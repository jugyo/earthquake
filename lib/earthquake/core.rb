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
    ensure
      _init
    end

    def load_config
      # TODO: parse argv
      config.merge!(
        :dir             => File.expand_path('~/.earthquake'),
        :plugin_dir      => File.expand_path('~/.earthquake/plugin'),
        :consumer_key    => 'RmzuwQ5g0SYObMfebIKJag',
        :consumer_secret => 'V98dYYmWm9JoG7qfOF0jhJaVEVW3QhGYcDJ9JQSXU'
      )

      [config[:dir], config[:plugin_dir]].each do |dir|
        unless File.exists?(dir)
          FileUtils.mkdir_p(dir)
        end
      end

      config[:file] ||= File.join(config[:dir], 'config')

      unless File.exists?(config[:file])
        File.open(config[:file], 'w')
      end

      load config[:file]

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

    def start(*argv)
      _once
      _init
      restore_history

      EventMachine::run do
        Thread.start do
          while buf = Readline.readline("⚡ ", true)
            unless Readline::HISTORY.count == 1
              Readline::HISTORY.pop if buf.empty? || Readline::HISTORY[-1] == Readline::HISTORY[-2]
            end
            sync { input(buf.strip) }
          end
        end

        Thread.start do
          loop do
            if Readline.line_buffer.nil? || Readline.line_buffer.empty?
              sync { output }
              sleep 1
            else
              sleep 2
            end
          end
        end

        reconnect

        trap('TERM') { stop }
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
          :access_key => config[:token], :access_secret => config[:secret]
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
      store_history
    end

    def store_history
      history_size = config[:history_size] || 1000
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
      Thread.start(&block)
    end

    def error(e)
      notify "[ERROR] #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def notify(message, options = {:title => 'earthquake'})
      Notify.notify options[:title], message
    end
  end

  extend Core
end
