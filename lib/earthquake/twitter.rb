module Earthquake
  module Twitter
    attr_reader :twitter
  end

  init do
    @twitter = TwitterOAuth::Client.new(config.slice(:consumer_key, :consumer_secret, :token, :secret))
  end

  once do
    class ::TwitterOAuth::Client
      def status_with_cache(id)
        key = "status:#{id}"
        unless s = Earthquake.cache.read(key)
          s = status_without_cache(id)
          Earthquake.cache.write(key, s, :expires_in => 1.hour.ago)
        end
        s
      end
      alias_method_chain :status, :cache
    end
  end

  extend Twitter
end