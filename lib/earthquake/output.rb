module Earthquake
  module Output
    def output
      return if item_queue.empty?

      insert do
        while item = item_queue.shift
          begin
            puts "[#{item["id"]}] #{item["user"]["screen_name"]}: #{item["text"]}"
          rescue => e
            ap item
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
  end
end
