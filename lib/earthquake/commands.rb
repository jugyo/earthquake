# encoding: UTF-8
module Earthquake
  init do
    command :exit do |m|
      stop
    end

    command :help do |m|
      puts "TODO..."
    end

    command :restart do |m|
      puts 'restarting...'
      exec File.expand_path('../../..//bin/earthquake', __FILE__)
    end

    command :eval do |m|
      ap eval(m[1])
    end

    # update
    command %r|^[^/]+| do |m|
      twitter.update(m[0]) if confirm(m[0])
    end

    command %r|^/reply (\d+)\s+(.*)|, :as => :reply do |m|
      # TODO
      ap m
    end

    command :status do |m|
      puts_item twitter.status(m[1])
    end

    command :delete do |m|
      twitter.status_destroy(m[1])
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
  end
end
