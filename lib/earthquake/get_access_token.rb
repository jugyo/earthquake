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
  end
end