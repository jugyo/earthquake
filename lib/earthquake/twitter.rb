module Earthquake
  module Twitter
    attr_reader :twitter
    def init_twitter
      @twitter = TwitterOAuth::Client.new(config.slice(:consumer_key, :consumer_secret, :token, :secret))
    end
  end
end