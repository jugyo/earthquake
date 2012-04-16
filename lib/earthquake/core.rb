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
      Gem.refresh
      loaded = ActiveSupport::Dependencies.loaded.dup
      ActiveSupport::Dependencies.clear
      loaded.each { |lib| require_dependency lib }
    rescue Exception => e
      error e
    ensure
      _init
    end

    def load_config
      consumer = YAML.load_file(File.expand_path('../../../consumer.yml', __FILE__))

      config[:dir]              ||= File.expand_path('~/.earthquake')
      config[:time_format]      ||= Time::DATE_FORMATS[:short]
      config[:plugin_dir]       ||= File.join(config[:dir], 'plugin')
      config[:file]             ||= File.join(config[:dir], 'config')
      config[:prompt]           ||= '⚡ '
      config[:consumer_key]     ||= consumer['key']
      config[:consumer_secret]  ||= consumer['secret']
      config[:output_interval]  ||= 1
      config[:history_size]     ||= 1000
      config[:api]              ||= { :host => 'userstream.twitter.com', :path => '/2/user.json', :ssl => true }
      config[:confirm_type]     ||= :y
      config[:expand_url]       ||= false
      config[:thread_indent]    ||= "  "

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

    def __init(options)
      config.merge!(options)
      _init
      _once
    end

    def invoke(command, options = {})
      __init(options)
      input(command)
    end

    def start(options = {})
      __init(options)
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
      start_stream(config[:api])
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
        notify "error: #{message}"
      end

      @stream.on_reconnect do |timeout, retries|
        notify "reconnecting in: #{timeout} seconds"
      end

      @stream.on_max_reconnects do |timeout, retries|
        notify "Failed after #{retries} failed reconnects"
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
      begin
        File.read(history_file, :encoding => "BINARY").
          encode!(:invalid => :replace, :undef => :replace).
          split(/\n/).
          each { |line| Readline::HISTORY << line }
      rescue Errno::ENOENT
      rescue Errno::EACCES => e
        error(e)
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
      notify "[ERROR] #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def notify(message, options = {})
      args = {:title => 'earthquake'}.update(options)
      title = args.delete(:title)
      message = message.is_a?(String) ? message : message.inspect
      # FIXME: Escaping should be done at Notify.notify
      Notify.notify title, CGI::unescapeHTML(message.e)
    end
    alias_method :n, :notify

    def browse(url)
      Launchy.open(url)
    end
  end

  extend Core
end
