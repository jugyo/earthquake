module Earthquake
  module Output
    def output
      return if item_queue.empty?
      insert do
        while item = item_queue.shift
          puts_item(item)
        end
      end
    end

    def puts_item(item)
      output_handers.each { |p| p.call(item) }
    rescue => e
      puts e, e.backtrace
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
  end

  init do
    output_handers.clear

    output_hander do |item|
      if item["text"]
        puts "[#{item["id"]}] #{item["user"]["screen_name"]}: #{item["text"]}" +
              (item["in_reply_to_status_id"] ? " (reply to #{item["in_reply_to_status_id"]})" : "")
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
