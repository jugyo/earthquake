# encoding: UTF-8
require 'uri'
require 'open-uri'
Earthquake.init do
  command :exit do
    stop
  end

  command :help do
    system 'less', File.expand_path('../../../README.md', __FILE__)
  end

  command :restart do
    puts 'restarting...'
    stop
    args = ARGV.dup
    args.push '-n' unless args.include?('-n')
    exec File.expand_path('../../../bin/earthquake', __FILE__), *args
  end

  command :eval do |m|
    ap eval(m[1])
  end

  command :update do |m|
    async_e { twitter.update(m[1]) } if confirm("update '#{m[1]}'")
  end

  command %r|^[^:\$].*| do |m|
    input(":update #{m[0]}")
  end

  command %r|^:reply\s+(\d+)\s+(.*)|, :as => :reply do |m|
    in_reply_to_status_id = m[1]
    target = twitter.status(in_reply_to_status_id)
    screen_name = target["user"]["screen_name"]
    text = "@#{screen_name} #{m[2]}"
    if confirm(["'@#{screen_name}: #{target["text"]}'".c(:info), "reply '#{text}'"].join("\n"))
      async_e { twitter.update(text, :in_reply_to_status_id => in_reply_to_status_id) }
    end
  end

  # $xx hi!
  command %r|^(\$[^\s]+)\s+(.*)$| do |m|
    input(":reply #{m[1..2].join(' ')}")
  end

  command :status do |m|
    puts_items twitter.status(m[1])
  end

  # $xx
  command %r|^(\$[^\s]+)$| do |m|
    input(":status #{m[1]}")
  end

  command :delete do |m|
    tweet = twitter.status(m[1])
    async_e { twitter.status_destroy(m[1]) } if confirm("delete '#{tweet["text"]}'")
  end

  command :mentions do
    puts_items twitter.mentions
  end

  command :follow do |m|
    async_e { twitter.friend(m[1]) }
  end

  command :unfollow do |m|
    async_e { twitter.unfriend(m[1]) }
  end

  command :recent do
    puts_items twitter.home_timeline(:count => config[:recent_count])
  end

  # :recent jugyo
  command %r|^:recent\s+([^\/\s]+)$|, :as => :recent do |m|
    puts_items twitter.user_timeline(:screen_name => m[1])
  end

  # :recent yugui/ruby-committers
  command %r|^:recent\s+([^\s]+)\/([^\s]+)$|, :as => :recent do |m|
    puts_items twitter.list_statuses(m[1], m[2])
  end

  command :user do |m|
    ap twitter.show(m[1]).slice(*%w(id screen_name name profile_image_url description url location time_zone lang protected))
  end

  command :search do |m|
    search_options = config[:search_options] ? config[:search_options].dup : {}
    puts_items twitter.search(m[1], search_options)["results"].each { |s|
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
    if confirm("retweet 'RT @#{target["user"]["screen_name"]}: #{target["text"]}'")
      async_e { twitter.retweet(m[1]) }
    end
  end

  command %r|^:retweet\s+(\d+)\s+(.*)$|, :as => :retweet do |m|
    target = twitter.status(m[1])
    text = "#{m[2]} #{config[:quotetweet] ? "QT" : "RT"} @#{target["user"]["screen_name"]}: #{target["text"]}"
    if confirm("unofficial retweet '#{text}'")
      async_e { twitter.update(text) }
    end
  end

  command :favorite do |m|
    tweet = twitter.status(m[1])
    if confirm("favorite '#{tweet["user"]["screen_name"]}: #{tweet["text"]}'")
      async_e { twitter.favorite(m[1]) }
    end
  end

  command :unfavorite do |m|
    tweet = twitter.status(m[1])
    if confirm("unfavorite '#{tweet["user"]["screen_name"]}: #{tweet["text"]}'")
      async_e { twitter.unfavorite(m[1]) }
    end
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
    async_e { twitter.block(m[1]) }
  end

  command :unblock do |m|
    async_e { twitter.unblock(m[1]) }
  end

  command :report_spam do |m|
    async_e { twitter.report_spam(m[1]) }
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
    async_e { twitter.message(*m[1, 2]) } if confirm("message '#{m[2]}' to @#{m[1]}")
  end

  command :reconnect do
    reconnect
  end

  command :thread do |m|
    thread = [twitter.status(m[1])]
    while reply = thread.last["in_reply_to_status_id"]
      print '.'.c(:info)
      thread << twitter.status(reply)
    end
    print "\e[2K\e[0G"
    puts_items thread.reverse_each.with_index{|tweet, indent|
      tweet["_mark"] = "  " * indent
    }
  end

  command :update_profile_image do |m|
    image_path = File.expand_path(m[1].gsub('\\', ''))
    async_e { twitter.update_profile_image(File.open(image_path, 'rb')) }
  end

  command %r|^:open\s+(\d+)$|, :as => :open do |m|
    if match = twitter.status(m[1])["text"].match(URI.regexp(["http", "https"]))
      browse match[0]
    else
      puts "no link found".c(41)
    end
  end

  command :browse do |m|
    url = case m[1]
      when /^\d+$/
        "https://twitter.com/#{twitter.status(m[1])['user']['screen_name']}/status/#{m[1]}"
      else
        "https://twitter.com/#{m[1][/[^'"]+/]}"
      end
    browse url
  end

  command :sh do
    system ENV["SHELL"] || 'sh'
  end

  command :'!' do |m|
    system eval("\"#{m[1]}\"").to_s
  end

  command :plugin_install do |m|
    uri = URI.parse(m[1])
    unless uri.host == "gist.github.com"
      puts "the host must be gist.github.com".c(41)
    else
      puts "..."
      gist_id = uri.path[/\d+/]
      meta = JSON.parse(open("https://gist.github.com/api/v1/json/#{gist_id}").read)
      filename = meta["gists"][0]["files"][0]
      raw = open("https://gist.github.com/raw/#{gist_id}/#{filename}").read

      puts '-' * 80
      puts raw.c(36)
      puts '-' * 80

      filename = "#{meta["gists"][0]["repo"]}.rb" if filename =~ /^gistfile/
      filepath = File.join(config[:plugin_dir], filename)
      if confirm("Install to '#{filepath}'?")
        File.open(File.join(config[:plugin_dir], filename), 'w') do |file|
          file << raw
          file << "\n# #{m[1]}"
        end
        reload
      end
    end
  end

  command :edit_config do
    editor = ENV["EDITOR"] || 'vim'
    system "#{editor} #{config[:file]}"
  end

  command %r|^:alias\s+?(:\w+)\s+(.+)|, :as => :alias do |m|
    alias_command m[1], m[2]
  end

  command :reauthorize do
    get_access_token
  end
end
