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
    class ::TwitterOAuth::Client
      [:status, :info].each do |m|
        define_method("#{m}_with_cache") do |*args|
          key = "#{m}:#{args.join(',')}"
          if result = Earthquake.cache.read(key)
            result.dup
          else
            result = __send__(:"#{m}_without_cache", *args)
            Earthquake.cache.write(key, result.dup)
            result
          end
        end
        alias_method_chain m, :cache
      end
    end
  end

  extend Twitter
end
