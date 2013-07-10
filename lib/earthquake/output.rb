# encoding: UTF-8
require 'stringio'
require 'monitor'

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
        insert do
          while item = item_queue.shift
            item["_stream"] = true
            puts_items(item)
          end
        end
      end
    end

    def puts_items(items)
      mark_color = config[:colors].sample + 10

      [items].flatten.reverse_each do |item|
        next if output_filters.any? { |f| f.call(item) == false }

        if item["text"] && !item["_stream"]
          item['_mark'] = ' '.c(mark_color) + item['_mark'].to_s
        end

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
      @insert_monitor.synchronize do
        begin
          try_swap = !$stdout.is_a?(StringIO)
          $stdout = StringIO.new if try_swap

          puts messages
          yield if block_given?

          unless $stdout.string.empty?
            STDOUT.print "\e[0G\e[K#{$stdout.string}"
            Readline.refresh_line
          end
        ensure
          $stdout = STDOUT if try_swap
        end
      end
    end

    def color_of(screen_name)
      config[:colors][screen_name.delete("^0-9A-Za-z_").to_i(36) % config[:colors].size]
    end
  end

  init do
    @insert_monitor ||= Monitor.new
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
    config[:raw_text] ||= true

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

      text = (item["retweeted_status"] ? "RT @#{item["retweeted_status"]["user"]["screen_name"]}: #{item["retweeted_status"]["text"]}" : item["text"]).u
      if config[:raw_text] && /\n/ =~ text
        text.prepend("\n")
        text.gsub!(/\n/, "\n       " + "|".c(:info))
        text << "\n      "
      else
        text.gsub!(/\s+/, ' ')
      end
      text = text.coloring(/@[0-9A-Za-z_]+/) { |i| color_of(i) }
      text = text.coloring(/(^#[^\s]+)|(\s+#[^\s]+)/) { |i| color_of(i) }
      if config[:expand_url]
        entities = (item["retweeted_status"] && item["truncated"]) ? item["retweeted_status"]["entities"] : item["entities"]
        if entities
          entities.values_at("urls", "media").flatten.compact.each do |entity|
            url, expanded_url = entity.values_at("url", "expanded_url")
            if url && expanded_url
              text = text.sub(url, expanded_url)
            end
          end
        end
      end
      text = text.coloring(URI.regexp(["http", "https"]), :url)

      if item["_highlights"]
        item["_highlights"].each do |h|
          color = config[:color][:highlight].nil? ? color_of(h).to_i + 10 : :highlight
          text = text.coloring(/#{h}/i, color)
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
      if deleted = item["delete"]
        case
        when deleted.key?("status")
          if tweet = cache.read("status:#{deleted["status"]["id"]}")
            screen_name = tweet["user"]["screen_name"]
            text = tweet["text"]
          else
            next
          end
        when deleted.key?("direct_message")
          screen_name = twitter.info["screen_name"]
          text = "(direct message)"
        end
        puts ("%s %s: %s" % ["[delete]", screen_name, text]).c(:info)
      end
    end

    output :direct_message do |item|
      next unless dm = item["direct_message"]
      puts "[direct message]".c(:event) +
           " #{dm["sender"]["screen_name"]} => #{dm["recipient"]["screen_name"]}: #{dm["text"]}"
    end

    output :event do |item|
      next unless item["event"]

      print "[#{item["event"]}]".c(:event) + " "
      case item["event"]
      when "follow", "block", "unblock"
        puts "#{item["source"]["screen_name"]} => #{item["target"]["screen_name"]}"
      when "favorite", "unfavorite"
        puts "#{item["source"]["screen_name"]} => #{item["target"]["screen_name"]} : #{item["target_object"]["text"].u}"
      when "list_member_added", "list_member_removed"
        puts "#{item["target_object"]["full_name"]} (#{item["target_object"]["description"]})"
      else
        if config[:debug]
          ap item
        end
      end
    end
  end

  extend Output
end
