module Earthquake
  module Core
    attr_accessor :config
    attr_reader :item_queue

    def init(*argv)
      # TODO: parse argv
      self.config = {
        :dir             => File.expand_path('~/.earthquake'),
        :consumer_key    => 'qOdgatiUm6HIRcdoGVqaZg',
        :consumer_secret => 'DHcL0bmS02vjSMHMrbFxCQqbDxh8yJZuLuzKviyFMo'
      }
      config[:file] ||= File.join(config[:dir], 'config')
      load config[:file]

      get_access_token unless self.config[:access_key] && self.config[:access_secret]
    end

    def get_access_token
      consumer = OAuth::Consumer.new(
        self.config[:consumer_key],
        self.config[:consumer_secret],
        :site => 'http://api.twitter.com'
      )
      request_token = consumer.get_request_token

      puts "1) open: #{request_token.authorize_url}"
      Launchy::Browser.run(request_token.authorize_url)

      print "2) Enter the PIN: "
      pin = gets.strip

      access_token = request_token.get_access_token(:oauth_verifier => pin)
      config[:access_key] = access_token.token
      config[:access_secret] = access_token.secret

      puts "Saving 'access_key' and 'access_secret' to '#{config[:file]}'"
      File.open(config[:file], 'a') do |f|
        f << "\n"
        f << "Earthquake.config[:access_key] = '#{config[:access_key]}'"
        f << "\n"
        f << "Earthquake.config[:access_secret] = '#{config[:access_secret]}'"
      end
    end

    def start(*argv)
      init(*argv)

      @item_queue = []

      Thread.abort_on_exception = true

      Thread.start do
        while buf = Readline.readline("[earthquake] ", true)
          begin
            buf = buf.strip

            if buf == '/exit'
              # TODO: refactor
              @stream.stop if @stream
              EventMachine.stop if EventMachine.reactor_running? 
            end
          rescue => e
            notify "[ERROR] #{e}"
          end
        end
      end

      Thread.start do
        loop do
          # TODO: handle the response that include friends
          if Readline.line_buffer.empty?
            while item = item_queue.shift
              begin
                insert "#{item["user"]["screen_name"]}: #{item["text"]}"
              rescue => e
                insert do
                  ap item
                end
                # notify "[ERROR] #{e}"
              end
            end
          end
          sleep 1
        end
      end

      EventMachine::run {
        @stream = Twitter::JSONStream.connect(
          :ssl   => true,
          :host  => 'userstream.twitter.com',
          :path  => '/2/user.json',
          :oauth => config.slice(:consumer_key, :consumer_secret, :access_key, :access_secret)
        )

        @stream.each_item do |item|
          item_queue << JSON.parse(item)
        end

        @stream.on_error do |message|
          $stdout.print "error: #{message}\n"
          $stdout.flush
        end

        @stream.on_reconnect do |timeout, retries|
          $stdout.print "reconnecting in: #{timeout} seconds\n"
          $stdout.flush
        end

        @stream.on_max_reconnects do |timeout, retries|
          $stdout.print "Failed after #{retries} failed reconnects\n"
          $stdout.flush
        end

        trap('TERM') {
          @stream.stop
          EventMachine.stop if EventMachine.reactor_running? 
        }
      }
    end

    def notify(message)
      Notify.notify 'earthquake', message
    end

    def insert(*messages)
      clear_line
      puts messages unless messages.empty?
      yield if block_given?
    ensure
      Readline.refresh_line
    end

    def clear_line
      print "\e[0G" + "\e[K"
    end
  end
end
