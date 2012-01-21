module Earthquake
  module Identica
    def start_polling_identica
      reload
      poll_interval = 30
      initial_items = 3
      last_id = nil
      last_message_id = nil
      initial_messages = 1
      Thread.start do
        loop do
          begin
            items = if last_id
                      twitter.home_timeline(:since_id => last_id)
                    else
                      twitter.home_timeline(:count => initial_items)
                    end
            items.sort_by{|i|i["id"].to_i}.each do |item|
              last_id = item["id"]
              item_queue << item
            end
            items = if last_message_id
                      twitter.messages(:since_id => last_message_id)
                    else
                      twitter.messages(:count => initial_messages)
                    end
            items.sort_by{|i|i["id"].to_i}.each do |item|
              last_message_id = item["id"]
              item["user"] = {"screen_name" => item["sender_screen_name"]}
              item["_disable_cache"] = true
              item_queue << item
            end
          rescue => e
            error e
          end
          sleep poll_interval
        end
      end
    end

  end

  extend Identica
end
