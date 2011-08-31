module Earthquake
  module GetAccessToken
    def get_access_token
      consumer = OAuth::Consumer.new(
        self.config[:consumer_key],
        self.config[:consumer_secret],
        :site => 'https://api.twitter.com',
        :proxy => ENV['http_proxy']
      )
      request_token = consumer.get_request_token

      puts "1) open: #{request_token.authorize_url}"
      browse(request_token.authorize_url) rescue nil

      print "2) Enter the PIN: "
      pin = STDIN.gets.strip

      access_token = request_token.get_access_token(:oauth_verifier => pin)
      config[:token] = access_token.token
      config[:secret] = access_token.secret

      puts "Saving 'token' and 'secret' to '#{config[:file]}'"
      File.open(config[:file], 'a') do |f|
        f << "\n"
        f << "Earthquake.config[:token] = '#{config[:token]}'"
        f << "\n"
        f << "Earthquake.config[:secret] = '#{config[:secret]}'"
      end
    end
  end

  extend GetAccessToken
end
