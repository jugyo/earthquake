module Earthquake
  module Output
    def output
      insert do
        while item = item_queue.shift
          begin
            puts "#{item["user"]["screen_name"]}: #{item["text"]}"
          rescue => e
            insert do
              ap item
            end
            # notify "[ERROR] #{e}"
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
