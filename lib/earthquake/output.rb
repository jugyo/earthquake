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
            item["stream"] = true
            puts_items(item)
          end
        end
      end
    end

    def puts_items(items)
      [items].flatten.each do |item|
        outputs.each do |p|
          next if filters.any? { |filter| filter.call(item) == false }
          begin
            p.call(item)
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

      if item["in_reply_to_status_id"]
        misc = " (reply to #{item["in_reply_to_status_id"]})"
      elsif item["retweeted_status"]
        misc = " (retweet of #{item["retweeted_status"]["id"]})"
      else
        misc = ""
      end

      statuses = ["[#{item["id"].to_s}]"]
      unless item["stream"]
        statuses.insert(0, "[#{Time.parse(item["created_at"]).strftime('%Y.%m.%d %X')}]")
      end

      source = item["source"] =~ />(.*)</ ? $1 : 'web'
      user_color = color_of(item["user"]["screen_name"])
      text = item["text"].gsub(/[@#]([0-9A-Za-z_]+)/) do |i|
        i.c(color_of($1))
      end

      if item["highlights"]
        item["highlights"].each do |h|
          c = color_of(h).to_i + 10
          text = text.gsub(/#{h}/i) do |i|
            i.c(c)
          end
        end
      end

      mark = item["mark"] || ""

      status =  [
                  "#{mark}" + "#{statuses.join(" ")}".c(90),
                  "#{item["user"]["screen_name"].c(user_color)}:",
                  "#{text}",
                  "#{misc} #{source}".c(90)
                ].join(" ")
      puts status
    end

    output do |item|
      next unless item["event"]

      case item["event"]
      when "follow", "block", "unblock"
        puts "[#{item["event"]}] #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]}"
      when "favorite", "unfavorite"
        puts "[#{item["event"]}] #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]} : #{item["target_object"]["text"]}"
      when "delete"
        puts "[deleted] #{item["delete"]["status"]["id"]}"
      else
        if config[:debug]
          ap item
        end
      end
    end
  end

  extend Output
end
