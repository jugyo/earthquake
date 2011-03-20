# encoding: UTF-8
module Earthquake
  module Output
    def output
      return if item_queue.empty?
      insert do
        while item = item_queue.shift
          item["hide_timestamp"] = true
          puts_items(item)
        end
      end
    end

    def puts_items(items)
      [items].flatten.each do |item|
        output_handers.each do |p|
          begin
            p.call(item)
          rescue => e
            puts e, e.backtrace
          end
        end
      end
    end

    def output_handers
      @output_handers ||= []
    end

    def output_hander(&block)
      output_handers << block
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
    output_handers.clear

    config[:colors] ||= (31..36).to_a + (91..96).to_a

    output_hander do |item|
      next unless item["text"]

      if item["in_reply_to_status_id"]
        misc = " (reply to #{item["in_reply_to_status_id"]})"
      elsif item["retweeted_status"]
        misc = " (retweet of #{item["retweeted_status"]["id"]})"
      else
        misc = ""
      end

      statuses = ["[#{item["id"].to_s}]"]
      unless item["hide_timestamp"]
        statuses.insert(0, "[#{Time.parse(item["created_at"]).strftime('%Y.%m.%d %X')}]")
      end

      source = item["source"] =~ />(.*)</ ? $1 : 'web'
      user_color = color_of(item["user"]["screen_name"])
      text = item["text"].e.gsub(/[@#]([0-9A-Za-z_]+)/) do |i|
        c = color_of($1)
        "<#{c}>#{i}</#{c}>"
      end
      status = "<90>#{statuses.join(" ").e}</90> " +
               "<#{user_color}>#{item["user"]["screen_name"].e}</#{user_color}>: " +
               "#{text}<90>#{misc.e} #{source.e}</90>"
      puts status.t
    end

    output_hander do |item|
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
