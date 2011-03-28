# encoding: UTF-8
module Earthquake
  module Output
    def filters
      @filters ||= []
    end

    def filter(&block)
      filters << block
    end

    def outputs
      @outputs ||= []
    end

    def output(&block)
      if block
        outputs << block
      else
        return if item_queue.empty?
        insert do
          while item = item_queue.shift
            item["_stream"] = true
            puts_items(item)
          end
        end
      end
    end

    def puts_items(items)
      [items].flatten.reverse_each do |item|
        next if filters.any? { |f| f.call(item) == false }
        outputs.each do |o|
          begin
            o.call(item)
          rescue => e
            error e
          end
        end
      end
    end

    def insert(*messages)
      clear_line
      puts messages unless messages.empty?
      yield if block_given?
    ensure
      Readline.refresh_line
    end

    def clear_line
      print "\e[0G" + "\e[K"
    end

    def color_of(screen_name)
      colors[screen_name.to_i(36) % colors.size]
    end

    def colors
      config[:colors]
    end
  end

  init do
    outputs.clear
    filters.clear

    config[:colors] ||= (31..36).to_a + (91..96).to_a

    output do |item|
      next unless item["text"]

      info = []
      if item["in_reply_to_status_id"]
        info << "(reply to #{id2var(item["in_reply_to_status_id"])})"
      elsif item["retweeted_status"]
        info << "(retweet of #{id2var(item["retweeted_status"]["id"])})"
      end
      info << Time.parse(item["created_at"]).strftime('%m/%d/%y %H:%M %p')
      if item["_detail"] && item["source"]
        info << (item["source"].u =~ />(.*)</ ? $1 : 'web')
      end

      id = id2var(item["id"])

      text = item["text"].u
      text.gsub!(/@([0-9A-Za-z_]+)/) do |i|
        i.c(color_of($1))
      end
      text.gsub!(/(?:^#([^\s]+))|(?:\s+#([^\s]+))/) do |i|
        i.c(color_of($1 || $2))
      end

      if item["_highlights"]
        item["_highlights"].each do |h|
          c = color_of(h).to_i + 10
          text = text.gsub(/#{h}/i) do |i|
            i.c(c)
          end
        end
      end

      mark = item["_mark"] || ""

      status =  [
                  "#{mark}" + "[#{id}]".c(90),
                  "#{item["user"]["screen_name"].c(color_of(item["user"]["screen_name"]))}:",
                  "#{text}",
                  (item["user"]["protected"] ? "[P]".c(31) : nil),
                  info.join(' - ').c(90)
                ].compact.join(" ")
      puts status
    end

    output do |item|
      next unless item["event"]

      # TODO: handle 'list_member_added' and 'list_member_removed'
      case item["event"]
      when "follow", "block", "unblock"
        puts "[#{item["event"]}]".c(42) + " #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]}"
      when "favorite", "unfavorite"
        puts "[#{item["event"]}]".c(42) + " #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]} : #{item["target_object"]["text"].u}"
      when "delete"
        puts "[deleted]".c(42) + " #{item["delete"]["status"]["id"]}"
      else
        if config[:debug]
          ap item
        end
      end
    end
  end

  extend Output
end
