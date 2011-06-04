# encoding: UTF-8
require 'fileutils'

module Earthquake
  module Core
    def config
      @config ||= {}
    end

    def item_queue
      @item_queue ||= []
    end

    def inits
      @inits ||= []
    end

    def init(&block)
      inits << block
    end

    def onces
      @once ||= []
    end

    def once(&block)
      onces << block
    end

    def _once
      onces.each { |block| class_eval(&block) }
    end

    def _init
      load_config
      load_plugins
      inits.each { |block| class_eval(&block) }
      inits.clear
    end

    def reload
      loaded = ActiveSupport::Dependencies.loaded.dup
      ActiveSupport::Dependencies.clear
      loaded.each { |lib| require_dependency lib }
    rescue Exception => e
      error e
    ensure
      _init
    end

    def load_config
      config[:dir]              ||= File.expand_path('~/.earthquake')
      config[:time_format]      ||= Time::DATE_FORMATS[:short]
      config[:plugin_dir]       ||= File.join(config[:dir], 'plugin')
      config[:file]             ||= File.join(config[:dir], 'config')
      config[:prompt]           ||= '⚡ '
      config[:consumer_key]     ||= 'RmzuwQ5g0SYObMfebIKJag'
      config[:consumer_secret]  ||= 'V98dYYmWm9JoG7qfOF0jhJaVEVW3QhGYcDJ9JQSXU'
      config[:output_interval]  ||= 1
      config[:history_size]     ||= 1000
      config[:only_gists]       ||= true
      config[:notify_errors]    ||= false

      [config[:dir], config[:plugin_dir]].each do |dir|
        unless File.exists?(dir)
          FileUtils.mkdir_p(dir)
        end
      end

      if File.exists?(config[:file])
        load config[:file]
      else
        File.open(config[:file], 'w')
      end

      get_access_token unless self.config[:token] && self.config[:secret]
    end

    def load_plugins
      Dir[File.join(config[:plugin_dir], '*.rb')].each do |lib|
        begin
          require_dependency lib
        rescue Exception => e
          error e
        end
      end
    end

    def start(options = {})
      config.merge!(options)
      _init
      _once
      restore_history

      EventMachine::run do
        Thread.start do
          while buf = Readline.readline(config[:prompt], true)
            unless Readline::HISTORY.count == 1
              Readline::HISTORY.pop if buf.empty? || Readline::HISTORY[-1] == Readline::HISTORY[-2]
            end
            sync {
              reload
              store_history
              input(buf.strip)
            }
          end
          stop
        end

        Thread.start do
          loop do
            if Readline.line_buffer.nil? || Readline.line_buffer.empty?
              sync { output }
            end
            sleep config[:output_interval]
          end
        end

        reconnect

        trap('INT') { stop }
      end
    end

    def reconnect
      item_queue.clear
      start_stream(:host  => 'userstream.twitter.com', :path  => '/2/user.json', :ssl => true)
    end

    def start_stream(options)
      stop_stream

      options = {
        :oauth => config.slice(:consumer_key, :consumer_secret).merge(
          :access_key => config[:token], :access_secret => config[:secret],
          :proxy => ENV['http_proxy']
        )
      }.merge(options)

      @stream = ::Twitter::JSONStream.connect(options)

      @stream.each_item do |item|
        item_queue << JSON.parse(item)
      end

      @stream.on_error do |message|
        error "error: #{message}"
      end

      @stream.on_reconnect do |timeout, retries|
        error "reconnecting in: #{timeout} seconds"
      end

      @stream.on_max_reconnects do |timeout, retries|
        error "Failed after #{retries} failed reconnects"
      end
    end

    def stop_stream
      @stream.stop if @stream
    end

    def stop
      stop_stream
      EventMachine.stop_event_loop
    end

    def store_history
      history_size = config[:history_size]
      File.open(File.join(config[:dir], 'history'), 'w') do |file|
        lines = Readline::HISTORY.to_a[([Readline::HISTORY.size - history_size, 0].max)..-1]
        file.print(lines.join("\n"))
      end
    end

    def restore_history
      history_file = File.join(config[:dir], 'history')
      if File.exists?(history_file)
        File.read(history_file).split(/\n/).each { |line| Readline::HISTORY << line }
      end
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def sync(&block)
      mutex.synchronize do
        block.call
      end
    end

    def async(&block)
      Thread.start do
        begin
          block.call
        rescue Exception => e
          error e
        end
      end
    end

    def error(e)
      if e.is_a? String
        error_str = "[ERROR] #{e}"
      elsif e.is_a? Exception
        error_str = "[ERROR] #{e.message}\n#{e.backtrace.join("\n")}"
      else
        error_str = "[ERROR] Error was of wrong type: #{e.class.to_s}"
      end

      if config[:notify_errors] == true
        notify error_str
      else
        puts error_str
      end
    end

    def notify(message, options = {})
      args = {:title => 'earthquake'}.update(options)
      title = args.delete(:title)
      message = message.is_a?(String) ? message : message.inspect
      # FIXME: Escaping should be done at Notify.notify
      Notify.notify title, message.e, args
    end
    alias_method :n, :notify

    def browse(url)
      Launchy::Browser.run(url)
    end
  end

  extend Core
end
