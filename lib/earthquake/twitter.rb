module Earthquake
  module Twitter
    attr_reader :twitter
  end

  init do
    @twitter = TwitterOAuth::Client.new(config.slice(:consumer_key, :consumer_secret, :token, :secret))
  end

  once do
    class ::TwitterOAuth::Client
      [:status, :info].each do |m|
        define_method("#{m}_with_cache") do |*args|
          key = "#{m}:#{args.join(',')}"
          unless result = Earthquake.cache.read(key)
            result = __send__(:"#{m}_without_cache", *args)
            Earthquake.cache.write(key, result, :expires_in => 1.hour.ago)
          end
          result.dup
        end
        alias_method_chain m, :cache
      end
    end
  end

  extend Twitter
end