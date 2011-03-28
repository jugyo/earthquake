# encoding: UTF-8
module Earthquake
  init do
    command :exit do
      stop
    end

    command :help do
      system 'less', File.expand_path('../../../README.md', __FILE__)
    end

    command :restart do
      puts 'restarting...'
      stop
      exec File.expand_path('../../../bin/earthquake', __FILE__)
    end

    command :eval do |m|
      ap eval(m[1])
    end

    # update
    command %r|^[^:].*| do |m|
      async { twitter.update(m[0]) } if confirm("update '#{m[0]}'")
    end

    command %r|^:reply (\d+)\s+(.*)|, :as => :reply do |m|
      in_reply_to_status_id = m[1]
      target = twitter.status(in_reply_to_status_id)
      screen_name = target["user"]["screen_name"]
      text = "@#{screen_name} #{m[2]}"
      if confirm(["'@#{screen_name}: #{target["text"].u}'", "reply '#{text}'"].join("\n"))
        async { twitter.update(text, :in_reply_to_status_id => in_reply_to_status_id) }
      end
    end

    command :status do |m|
      # TODO: show reply to statuses
      puts_items twitter.status(m[1]).tap { |s| s["_detail"] = true }
    end

    command :delete do |m|
      # TODO: confirm
      async { twitter.status_destroy(m[1]) }
    end

    command :mentions do
      puts_items twitter.mentions
    end

    command :follow do |m|
      async { twitter.friend(m[1]) }
    end

    command :unfollow do |m|
      async { twitter.unfriend(m[1]) }
    end

    command :recent do
      puts_items twitter.home_timeline
    end

    command :recent do |m|
      puts_items twitter.user_timeline(:screen_name => m[1])
    end

    command :user do |m|
      ap twitter.show(m[1]).slice(*%w(id screen_name name profile_image_url description url location time_zone lang protected))
    end

    command :search do |m|
      puts_items twitter.search(m[1])["results"].each { |s|
        s["user"] = {"screen_name" => s["from_user"]}
        s["_disable_cache"] = true
        words = m[1].split(/\s+/).reject{|x| x[0] =~ /^-|^(OR|AND)$/ }.map{|x|
          case x
          when /^from:(.+)/, /^to:(.+)/
            $1
          else
            x
          end
        }
        s["_highlights"] = words
      }
    end

    command %r|^:retweet\s+(\d+)$|, :as => :retweet do |m|
      target = twitter.status(m[1])
      if confirm("retweet 'RT @#{target["user"]["screen_name"]}: #{target["text"].e}'")
        async { twitter.retweet(m[1]) }
      end
    end

    command %r|^:retweet\s+(\d+)\s+(.*)$|, :as => :retweet do |m|
      target = twitter.status(m[1])
      text = "#{m[2]} RT @#{target["user"]["screen_name"]}: #{target["text"].e} (#{target["id"]})"
      if confirm("unofficial retweet '#{text}'")
        async { twitter.update(text) }
      end
    end

    command :favorite do |m|
      async { twitter.favorite(m[1]) }
    end

    command :unfavorite do |m|
      async { twitter.unfavorite(m[1]) }
    end

    command :retweeted_by_me do
      puts_items twitter.retweeted_by_me
    end

    command :retweeted_to_me do
      puts_items twitter.retweeted_to_me
    end

    command :retweets_of_me do
      puts_items twitter.retweets_of_me
    end

    command :block do |m|
      async { twitter.block(m[1]) }
    end

    command :unblock do |m|
      async { twitter.unblock(m[1]) }
    end

    command :report_spam do |m|
      async { twitter.report_spam(m[1]) }
    end

    command :messages do
      puts_items twitter.messages.each { |s|
        s["user"] = {"screen_name" => s["sender_screen_name"]}
        s["_disable_cache"] = true
      }
    end

    command :sent_messages do
      puts_items twitter.sent_messages.each { |s|
        s["user"] = {"screen_name" => s["sender_screen_name"]}
        s["_disable_cache"] = true
      }
    end

    command %r|^:message (\w+)\s+(.*)|, :as => :message do |m|
      async { twitter.message(*m[1, 2]) } if confirm("message '#{m[2]}' to @#{m[1]}")
    end

    command :reconnect do
      reconnect
    end
  end
end
