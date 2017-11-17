# NOTE: It's important to cache duped objects
module Earthquake
  module Twitter
    attr_reader :twitter
  end

  init do
    @twitter = TwitterOAuth::Client.new(config.slice(:consumer_key, :consumer_secret, :token, :secret, :api_version, :secure))

    output do |item|
      next if item["text"].nil? || item["_disable_cache"]
      item = item.dup
      item.keys.select { |key| key =~ /^_/ }.each { |key| item.delete(key) } # remote optional data like "_stream", "_highlights"
      cache_key = "status:#{item["id"]}"
      cache.write(cache_key, item) unless cache.exist?(cache_key)
    end
  end

  once do
    module ClientWithCache
      [:status, :info].each do |m|
        define_method(m) do |*args|
          key = "#{m}:#{args.join(',')}"
          if result = Earthquake.cache.read(key)
            result.dup
          else
            result = super *args
            Earthquake.cache.write(key, result.dup)
            result
          end
        end
      end
    end

    ::TwitterOAuth::Client.prepend(ClientWithCache)
  end

  extend Twitter
end
