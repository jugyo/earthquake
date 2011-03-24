# NOTE: It's important to cache duped objects
module Earthquake
  module Twitter
    attr_reader :twitter
  end

  init do
    @twitter = TwitterOAuth::Client.new(config.slice(:consumer_key, :consumer_secret, :token, :secret))

    filter do |item|
      next if item["text"].nil? || item["disable_cache"]
      Earthquake.cache.write("status:#{item["id"]}", item.dup)
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