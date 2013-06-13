module Earthquake
  module GetAccessToken
    def get_access_token
      consumer = OAuth::Consumer.new(
        self.config[:consumer_key],
        self.config[:consumer_secret],
        :site => config[:site],
        :proxy => ENV['http_proxy']
      )
      request_token = consumer.get_request_token

      puts "1) open: #{request_token.authorize_url}"
      browse(request_token.authorize_url) rescue nil

      print "2) Enter the PIN: "
      pin = STDIN.gets.strip

      access_token = request_token.get_access_token(:oauth_verifier => pin)
      if identica?
        config[:identica_token] = access_token.token
        config[:identica_secret] = access_token.secret
      else
        config[:token] = access_token.token
        config[:secret] = access_token.secret
      end

      puts "Saving 'token' and 'secret' to '#{config[:file]}'"
      File.open(config[:file], 'a') do |f|
        f << "\n"
        if identica?
          f.puts "Earthquake.config[:identica_token] = '#{config[:identica_token]}'"
          f.puts "Earthquake.config[:identica_secret] = '#{config[:identica_secret]}'"
        else
          f.puts "Earthquake.config[:token] = '#{config[:token]}'"
          f.puts "Earthquake.config[:secret] = '#{config[:secret]}'"
        end
      end
    end
  end

  extend GetAccessToken
end
