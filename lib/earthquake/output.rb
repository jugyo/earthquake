module Earthquake
  module Output
    def output
      return if item_queue.empty?
      insert do
        while item = item_queue.shift
          puts_items(item)
        end
      end
    end

    def puts_items(items)
      [items].flatten.each do |item|
        begin
          output_handers.each { |p| p.call(item) }
        rescue => e
          puts e, e.backtrace
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
      config[:colors][screen_name.to_i(36) % config[:colors].size]
    end
  end

  init do
    output_handers.clear

    config[:colors] = (31..36).to_a + (91..96).to_a

    output_hander do |item|
      if item["text"]
        misc = (item["in_reply_to_status_id"] ? " (reply to #{item["in_reply_to_status_id"]})" : "")
        user_color = color_of(item["user"]["screen_name"])
        text = item["text"].e.gsub(/[@#]([0-9A-Za-z_]+)/) do |i|
          c = color_of($1)
          "<#{c}>#{i}</#{c}>"
        end
        status = "<90>[#{item["id"].to_s.e}]</90> " +
                 "<#{user_color}>#{item["user"]["screen_name"].e}</#{user_color}>: " +
                 "#{text}<90>#{misc.e}</90>"
        puts status.t
      end
    end

    output_hander do |item|
      if item["delete"]
        puts "[deleted] #{item["delete"]["status"]["id"]}"
      end
    end
  end

  extend Output
end
