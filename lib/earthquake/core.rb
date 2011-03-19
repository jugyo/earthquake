# encoding: UTF-8
module Earthquake
  module Core
    attr_accessor :config

    def item_queue
      @item_queue ||= []
    end

    def inits
      @inits ||= []
    end

    def init(&block)
      inits << block
    end

    def _init
      load_config
      inits.each { |block| class_eval(&block) }
      inits.clear
    end

    def reload
      loaded = ActiveSupport::Dependencies.loaded.dup
      ActiveSupport::Dependencies.clear
      loaded.each { |lib| require_dependency lib }
      _init
    end

    def load_config
      # TODO: parse argv
      self.config = {
        :dir             => File.expand_path('~/.earthquake'),
        :consumer_key    => 'qOdgatiUm6HIRcdoGVqaZg',
        :consumer_secret => 'DHcL0bmS02vjSMHMrbFxCQqbDxh8yJZuLuzKviyFMo'
      }

      unless File.exists?(config[:dir])
        require 'fileutils'
        FileUtils.mkdir_p(config[:dir])
      end

      config[:file] ||= File.join(config[:dir], 'config')

      unless File.exists?(config[:file])
        File.open(config[:file], 'w')
      end

      load config[:file]

      get_access_token unless self.config[:token] && self.config[:secret]
    end

    def start(*argv)
      _init

      EventMachine::run do
        Thread.start do
          while buf = Readline.readline("⚡ ", true)
            Readline::HISTORY.pop if buf.empty?
            input(buf.strip)
          end
        end

        Thread.start do
          loop do
            if Readline.line_buffer.nil? || Readline.line_buffer.empty?
              output
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
    end

    def notify(message)
      Notify.notify 'earthquake', message
    end
  end

  extend Core
end
