module Earthquake
  module GetAccessToken
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
      pin = STDIN.gets.strip

      access_token = request_token.get_access_token(:oauth_verifier => pin)
      config[:token] = access_token.token
      config[:secret] = access_token.secret

      puts "Saving 'token' and 'secret' to '#{config[:file]}'"
      File.open(config[:file], 'a') do |f|
        f << "Earthquake.config[:token] = '#{config[:token]}'"
        f << "\n"
        f << "Earthquake.config[:secret] = '#{config[:secret]}'"
      end
    end
  end

  extend GetAccessToken
end