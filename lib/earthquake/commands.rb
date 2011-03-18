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
      exec File.expand_path('../../..//bin/earthquake', __FILE__)
    end

    command :eval do |m|
      ap eval(m[1])
    end

    # update
    command %r|^[^#{Regexp.quote(command_prefix)}].*| do |m|
      twitter.update(m[0]) if confirm("'#{m[0]}'")
    end

    command %r|^/reply (\d+)\s+(.*)|, :as => :reply do |m|
      # TODO
      ap m
    end

    command :status do |m|
      puts_items twitter.status(m[1])
    end

    command :delete do |m|
      twitter.status_destroy(m[1])
    end

    command :mentions do
      puts_items twitter.mentions.reverse
    end

    command :follow do |m|
      twitter.friend(m[1])
    end

    command :unfollow do |m|
      twitter.unfriend(m[1])
    end

    command :list do |m|
      puts_items twitter.user_timeline(:screen_name => m[1]).reverse
    end

    command :user do |m|
      ap twitter.show(m[1]).slice(*%w(id screen_name name profile_image_url description url location time_zone lang protected))
    end

    command :search do |m|
      puts_items twitter.search(m[1])["results"].each { |s| s["user"] = {"screen_name" => s["from_user"]} }.reverse
    end

    command :retweet do |m|
      twitter.retweet(m[1])
    end

    command :favorite do |m|
      twitter.favorite(m[1])
    end

    command :unfavorite do |m|
      twitter.unfavorite(m[1])
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
      twitter.block(m[1])
    end

    command :unblock do |m|
      twitter.unblock(m[1])
    end

    command :report_spam do |m|
      twitter.report_spam(m[1])
    end
  end
end
