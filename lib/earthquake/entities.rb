module Earthquake
  module Entities
    class << self
      def apply(item)
        if item["retweeted_status"] && item["truncated"]
          text = apply(item["retweeted_status"])
          screen_name = item["retweeted_status"]["user"]["screen_name"]
          return "RT #{"@#{screen_name}".c(Earthquake.color_of(screen_name))}: #{text}"
        end
        text, item_entities = item.values_at("text", "entities")
        if item_entities
          text = text.dup
          parse(item_entities).reverse_each do |entity|
            entity.apply(text)
          end
        end
        text.u
      end

      private

      def parse(item_entities)
        item_entities.flat_map{|type, entities|
          entities.map{|entity|
            klass = type.classify
            const_get(klass).new(entity) if const_defined?(klass)
          }.compact
        }.sort_by!(&:position)
      end
    end

    class Base
      def initialize(entity)
        @entity = entity
        @first, @last = entity["indices"]
      end

      def position
        @first
      end

      def apply(text)
        text[@first...@last] = colored_text
        text
      end

      def string
        raise NotImplementedError, "need to define `string'"
      end

      private

      def colored_text
        s = string
        s.c(Earthquake.color_of(s))
      end
    end

    class UrlBase < Base
      def string
        Earthquake.config[:expand_url] && @entity["expanded_url"] || @entity["url"]
      end

      private

      def colored_text
        string.c(:url)
      end
    end

    class Url < UrlBase
    end

    class Medium < UrlBase
    end

    class Hashtag < Base
      def string
        "#" + @entity["text"]
      end
    end

    class UserMention < Base
      def string
        "@" + @entity["screen_name"]
      end
    end
  end
end
