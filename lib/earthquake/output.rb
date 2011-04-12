# encoding: UTF-8
module Earthquake
  module Output
    def output_filters
      @output_filters ||= []
    end

    def output_filter(&block)
      output_filters << block
    end

    def outputs
      @outputs ||= []
    end

    def output(name = nil, &block)
      if block
        outputs.delete_if { |o| o[:name] == name } if name
        outputs << {:name => name, :block => block}
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
        next if output_filters.any? { |f| f.call(item) == false }
        outputs.each do |o|
          begin
            o[:block].call(item)
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
      config[:colors][screen_name.to_i(36) % config[:colors].size]
    end
  end

  init do
    outputs.clear
    output_filters.clear

    config[:colors] ||= (31..36).to_a + (91..96).to_a
    config[:color] ||= {}
    config[:color].reverse_merge!(
      :info   => 90,
      :notice => 31,
      :event  => 42,
      :url    => [4, 36]
    )
    config[:raw_text] ||= false

    output :tweet do |item|
      next unless item["text"]

      info = []
      if item["in_reply_to_status_id"]
        info << "(reply to #{id2var(item["in_reply_to_status_id"])})"
      elsif item["retweeted_status"]
        info << "(retweet of #{id2var(item["retweeted_status"]["id"])})"
      end
      if !config[:hide_time] && item["created_at"]
        info << Time.parse(item["created_at"]).strftime(config[:time_format])
      end
      if !config[:hide_app_name] && item["source"]
        info << (item["source"].u =~ />(.*)</ ? $1 : 'web')
      end

      id = id2var(item["id"])

      text = item["text"].u
      text.gsub!(/\s+/, ' ') unless config[:raw_text]
      text.gsub!(/@([0-9A-Za-z_]+)/) do |i|
        i.c(color_of($1))
      end
      text.gsub!(/(?:^#([^\s]+))|(?:\s+#([^\s]+))/) do |i|
        i.c(color_of($1 || $2))
      end
      text.gsub!(URI.regexp(["http", "https"])) do |i|
        i.c(:url)
      end

      if item["_highlights"]
        item["_highlights"].each do |h|
          if config[:color][:highlight].nil?
            c = color_of(h).to_i + 10
          else
            c = :highlight
          end
          text = text.gsub(/#{h}/i) do |i|
            i.c(c)
          end
        end
      end

      mark = item["_mark"] || ""

      status =  [
                  "#{mark}" + "[#{id}]".c(:info),
                  "#{item["user"]["screen_name"].c(color_of(item["user"]["screen_name"]))}:",
                  "#{text}",
                  (item["user"]["protected"] ? "[P]".c(:notice) : nil),
                  info.join(' - ').c(:info)
                ].compact.join(" ")
      puts status
    end

    output :delete do |item|
      if item["delete"] && cache.read("status:#{item["delete"]["status"]["id"]}")
        tweet = twitter.status(item["delete"]["status"]["id"])
        tweet["_mark"] = "[deleted]".c(:event) + ' '
        puts_items tweet
      end
    end

    output :event do |item|
      next unless item["event"]

      # TODO: handle 'list_member_added' and 'list_member_removed'
      case item["event"]
      when "follow", "block", "unblock"
        puts "[#{item["event"]}]".c(:event) + " #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]}"
      when "favorite", "unfavorite"
        puts "[#{item["event"]}]".c(:event) + " #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]} : #{item["target_object"]["text"].u}"
      else
        if config[:debug]
          ap item
        end
      end
    end
  end

  extend Output
end
