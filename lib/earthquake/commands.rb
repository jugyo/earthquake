# encoding: UTF-8
module Earthquake
  init do
    command :exit do
      stop
    end

    command :help do
      puts "TODO..."
    end

    command :restart do
      puts 'restarting...'
      stop
      exec File.expand_path('../../..//bin/earthquake', __FILE__)
    end

    command :eval do |m|
      ap eval(m[1])
    end

    # update
    command %r|^[^:].*| do |m|
      async { twitter.update(m[0]) } if confirm("update '#{m[0]}'")
    end

    command %r|^:reply (\d+)\s+(.*)|, :as => :reply do |m|
      # TODO: fill the user name to reply
      async {
        twitter.update(m[2], :in_reply_to_status_id => m[1])
      } if confirm("reply '#{m[2]}' to #{m[1]}")
    end

    command :status do |m|
      puts_items twitter.status(m[1])
    end

    command :delete do |m|
      # TODO: confirm
      async { twitter.status_destroy(m[1]) }
    end

    command :mentions do
      puts_items twitter.mentions.reverse
    end

    command :follow do |m|
      async { twitter.friend(m[1]) }
    end

    command :unfollow do |m|
      async { twitter.unfriend(m[1]) }
    end

    command :list do |m|
      puts_items twitter.user_timeline(:screen_name => m[1]).reverse
    end

    command :home do
      puts_items twitter.home_timeline.reverse
    end

    command :user do |m|
      ap twitter.show(m[1]).slice(*%w(id screen_name name profile_image_url description url location time_zone lang protected))
    end

    command :search do |m|
      puts_items twitter.search(m[1])["results"].each { |s|
        s["user"] = {"screen_name" => s["from_user"]}
      }.each {|s|
        words = m[1].split(/\s+/).reject{|x| x[0] =~ /^-|^(OR|AND)$/ }.map{|x|
          case x
          when /^from:(.+)/, /^to:(.+)/
            $1
          else
            x
          end
        }
        s["highlights"] = words
      }.reverse
    end

    command :retweet do |m|
      async { twitter.retweet(m[1]) }
    end

    command :favorite do |m|
      async { twitter.favorite(m[1]) }
    end

    command :unfavorite do |m|
      async { twitter.unfavorite(m[1]) }
    end

    command :retweeted_by_me do
      puts_items twitter.retweeted_by_me.reverse
    end

    command :retweeted_to_me do
      puts_items twitter.retweeted_to_me.reverse
    end

    command :retweets_of_me do
      puts_items twitter.retweets_of_me.reverse
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

    command :reconnect do
      reconnect
    end
  end
end
