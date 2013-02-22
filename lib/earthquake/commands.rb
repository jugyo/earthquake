# encoding: UTF-8
require 'uri'
require 'open-uri'
require 'shellwords'
Earthquake.init do

  # :exit

  command :exit do
    stop
  end

  help :exit, 'exit from earthquake'

  # :help

  command :help do
    summaries = {}
    helps.each do |k, v|
      summaries[k] = v[0]
    end
    ap summaries
  end

  command :help do |m|
    if help = helps[m[1].gsub(/^:/, '').to_sym]
      summary, usage = *help
      puts
      puts "#{m[1]} - #{summary}".indent(4).c(92)
      if usage
        puts
        puts usage.indent(4).c(92)
      end
      puts
    else
      ap nil
    end
  end

  help :help, 'show help', <<-HELP
    ⚡ :help
    ⚡ :help :retweet
  HELP

  # :config

  command :config do
    ap config
  end

  command :config do |m|
    key, value = m[1].split(/\s+/, 2)
    key = key.to_sym
    if value
      value = eval(value)
      preferred_config.store(key, value)
      reload
    end
    ap config.slice(key)
  end

  help :config, 'show or set config', <<-HELP
    ⚡ :config
    ⚡ :config key
    ⚡ :config key value
  HELP

  # :restart

  command :restart do
    puts 'restarting...'
    stop
    args = ARGV.dup
    args.push '-n' unless args.include?('-n')
    exec File.expand_path('../../../bin/earthquake', __FILE__), *args
  end

  help :restart, 'restart earthquake'

  # :eval

  command :eval do |m|
    ap eval(m[1])
  end

  help :eval, 'eval script', <<-HELP
    ⚡ :eval 1 + 1
  HELP

  command :eval_update do |m|
    input ":update #{eval(m[1])}"
  end
  alias_command :eu, :eval_update
  help :eval_update, 'eval and update the result', <<-HELP
    ⚡ :eval_update 1 + 1
  HELP

  command :aa do |m|
    begin
      raw_text, config[:raw_text] = config[:raw_text], true
      input(m[1])
    ensure
      config[:raw_text] = raw_text
    end
  end

  help :aa, 'executes a command with raw text', <<-HELP
    ⚡ :aa :status $aa
  HELP

  def self._eval_as_ruby_string(text)
    return text unless config[:eval_as_ruby_string_for_update]
    begin
      text = eval(%|"#{text.gsub('"', '\"')}"|)
    rescue SyntaxError => e
    rescue Exception => e
      puts e.message.c(:notice)
    end
    text
  end

  command %r|^:update$|, :as => :update do
    puts "[input EOF (e.g. Ctrl+D) at the last]".c(:info)
    text = STDIN.gets(nil)
    text = _eval_as_ruby_string(text)
    if text && !text.split.empty?
      async_e{ twitter.update(text) } if confirm("update above AA?")
    end
  end

  command :update do |m|
    text = _eval_as_ruby_string(m[1])
    async_e { twitter.update(text) } if confirm("update '#{text}'")
  end

  command %r|^[^:\$].*| do |m|
    input(":update #{m[0]}")
  end

  help :update, 'update status', <<-HELP
    ⚡ :update this is my new status
    ⚡ :update[ENTER]
        ⚡   
       ⚡   
         ⚡   
        ⚡   
    ^D
  HELP

  command %r|^:reply\s+(\d+)\s+(.*)|, :as => :reply do |m|
    in_reply_to_status_id = m[1]
    target = twitter.status(in_reply_to_status_id)
    screen_name = target["user"]["screen_name"]
    text = "@#{screen_name} #{m[2]}"
    if confirm(["'@#{screen_name}: #{target["text"]}'".c(:info), "reply '#{text}'"].join("\n"))
      async_e { twitter.update(text, :in_reply_to_status_id => in_reply_to_status_id) }
    end
  end

  help :reply, "replys a tweet", <<-HELP
    [$aa] hello world
    ⚡ :reply $aa goodbye world
    ⚡ $aa goodbye world
  HELP

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

  help :status, "shows status", <<-HELP
    [$aa] hello world
    ⚡ :status $aa
     [$aa] hello world
    ⚡ $aa
     [$aa] hello world
  HELP

  command :delete do |m|
    tweet = twitter.status(m[1])
    async_e { twitter.status_destroy(m[1]) } if confirm("delete '#{tweet["text"]}'")
  end

  help :delete, "deletes status", <<-HELP
    [$aa] hello world
    ⚡ :delete $aa
    delete 'hello world' [Yn] Y
  HELP

  command :mentions do
    puts_items twitter.mentions(:include_entities => :true)
  end

  help :mentions, "show mentions timeline"

  command :follow do |m|
    async_e { twitter.friend(m[1]) }
  end

  help :follow, "follow user"

  command :unfollow do |m|
    async_e { twitter.unfriend(m[1]) }
  end

  help :unfollow, "unfollow user"

  command :recent do
    puts_items twitter.home_timeline(:count => config[:recent_count])
  end

  # :recent jugyo
  command %r|^:recent\s+@?([^\/\s]+)$|, :as => :recent do |m|
    puts_items twitter.user_timeline(:screen_name => m[1])
  end

  # :recent yugui/ruby-committers
  command %r|^:recent\s+([^\s]+)\/([^\s]+)$|, :as => :recent do |m|
    puts_items twitter.list_statuses(m[1], m[2])
  end

  help :recent, "show recent tweets", <<-HELP
    ⚡ :recent
    ⚡ :recent user
    ⚡ :recent user/list
  HELP

  command :user do |m|
    user = twitter.show(m[1])
    if user.key?("error")
      user = twitter.status(m[1])["user"] || {}
    end
    ap user.slice(*%w(id_str screen_name name profile_image_url description url location time_zone lang protected statuses_count followers_count friends_count listed_count created_at))
  end

  help :user, "show user info"

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

  help :search, "searches term"

  default_stream = {
    method: "POST",
    host: "userstream.twitter.com",
    path: "/2/user.json",
    ssl: true,
  }

  filter_stream = {
    method: "POST",
    host: "stream.twitter.com",
    path: "/1/statuses/filter.json",
    ssl: true,
  }

  command %r!^:filter off$!, as: :filter do
    config[:api] = default_stream
    reconnect
  end

  command %r!^:filter keyword (.*)$!, as: :filter do |m|
    keywords = Shellwords.split(m[1])
    config[:api] = filter_stream.merge(filters: keywords)
    reconnect
  end

  command %r!:filter user (.*)$!, as: :filter do |m|
    users = m[1].split.map{|user|
      twitter.show(user)["id"]
    }.compact.join(",")
    unless users.empty?
      config[:api] = filter_stream.merge(params: {follow: users})
      reconnect
    end
  end

  help :filter, "manages filters", <<-HELP
    ⚡ :filter off
    ⚡ :filter keyword annoyingsubject
    ⚡ :filter user annoyinguser
  HELP

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

  help :retweet, "retweets or quote status", <<-HELP
    ⚡ :retweet $aa
    ⚡ :retweet $aa // LOL
  HELP

  command :favorite do |m|
    tweet = twitter.status(m[1])
    if confirm("favorite '#{tweet["user"]["screen_name"]}: #{tweet["text"]}'")
      async_e { twitter.favorite(m[1]) }
    end
  end

  help :favorite, "marks status as favorite"

  command :unfavorite do |m|
    tweet = twitter.status(m[1])
    if confirm("unfavorite '#{tweet["user"]["screen_name"]}: #{tweet["text"]}'")
      async_e { twitter.unfavorite(m[1]) }
    end
  end

  help :unfavorite, "unmarks status as favorite"

  command :retweeted_by_me do
    puts_items twitter.retweeted_by_me
  end

  help :retweeted_by_me, "shows the latest retweets you made"

  command :retweeted_to_me do
    puts_items twitter.retweeted_to_me
  end

  help :retweeted_to_me, "shows the latest retweets someone you follow made"

  command :retweets_of_me do
    puts_items twitter.retweets_of_me
  end

  help :retweets_of_me, "shows your latest status somebody retweeted"

  command :block do |m|
    async_e { twitter.block(m[1]) }
  end

  help :block, "blocks user"

  command :unblock do |m|
    async_e { twitter.unblock(m[1]) }
  end

  help :unblock, "unblocks user"

  command :report_spam do |m|
    async_e { twitter.report_spam(m[1]) }
  end

  help :report_spam, "blocks user and report as spam"

  command :messages do
    puts_items twitter.messages.each { |s|
      s["user"] = {"screen_name" => s["sender_screen_name"]}
      s["_disable_cache"] = true
    }
  end

  help :messages, "list direct messages received"

  command :sent_messages do
    puts_items twitter.sent_messages.each { |s|
      s["user"] = {"screen_name" => s["sender_screen_name"]}
      s["_disable_cache"] = true
    }
  end

  help :sent_messages, "list direct messages sent"

  command %r|^:message @?(\w+)\s+(.*)|, :as => :message do |m|
    async_e { twitter.message(*m[1, 2]) } if confirm("message '#{m[2]}' to @#{m[1]}")
  end

  help :message, "sent a direct message"

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
      tweet["_mark"] = config[:thread_indent] * indent
    }
  end

  help :thread, "displays conversation thread"

  command :update_profile_image do |m|
    image_path = File.expand_path(m[1].gsub('\\', ''))
    async_e { twitter.update_profile_image(File.open(image_path, 'rb')) }
  end

  help :update_profile_image, "updates profile image from local file path"

  command %r|^:open\s+(\d+)$|, :as => :open do |m|
    matches = twitter.status(m[1])['retweeted_status'].nil? ? 
      URI.extract(twitter.status(m[1])["text"],["http", "https"]) :
      URI.extract(twitter.status(m[1])['retweeted_status']["text"],["http", "https"]) 
    unless matches.empty?
      matches.each do |match_url|
        browse match_url
      end
    else
      puts "no link found".c(41)
    end
  end

  help :open, "opens all links in a tweet"

  command :browse do |m|
    url = case m[1]
      when /^\d+$/
        "https://twitter.com/#{twitter.status(m[1])['user']['screen_name']}/status/#{m[1]}"
      else
        "https://twitter.com/#{m[1][/[^'"]+/]}"
      end
    browse url
  end

  help :browse, "opens the browser on a tweet or a user", <<-HELP
    ⚡ :browse $aa
    ⚡ :browse username
  HELP

  command :shell do
    system ENV["SHELL"] || 'sh'
  end
  alias_command :sh, :shell
  help :shell, "opens a shell"

  command %r|:!(.+)| do |m|
    command = m[1].strip
    puts "`#{command}`"
    system eval("\"#{command}\"").to_s
  end

  command :plugin_install do |m|
    uri = URI.parse(m[1])
    if uri.host == "t.co"
      begin
        open(uri, redirect: false)
      rescue OpenURI::HTTPRedirect => e
        uri = URI.parse(e.io.meta["location"])
      end
    end
    unless uri.host == "gist.github.com"
      puts "the host must be gist.github.com".c(41)
    else
      puts "..."
      gist_id = uri.path[/\d+/]
      meta = JSON.parse(open("https://api.github.com/gists/#{gist_id}").read)
      filename = meta["files"].keys[0]
      raw = meta['files'][filename]['content']

      puts '-' * 80
      puts raw.c(36)
      puts '-' * 80

      filename = "#{meta["id"]}.rb" if filename =~ /^gistfile/
      filepath = File.join(config[:plugin_dir], filename)
      if confirm("Install to '#{filepath}'?")
        File.open(File.join(config[:plugin_dir], filename), 'w') do |file|
          file << raw
          file << "\n# #{uri}\n"
        end
        reload
      end
    end
  end

  help :plugin_install, "installs a plugin from gist.github.com"

  command :edit_config do
    editor = ENV["EDITOR"] || 'vim'
    system "#{editor} #{config[:file]}"
  end

  help :edit_config, "edit your config; note that changes may require to :restart"

  command %r|^:alias\s+?(:\w+)\s+(.+)|, :as => :alias do |m|
    alias_command m[1], m[2]
  end

  help :alias, "creates a new command aliasing to an existing one", <<-HELP
    ⚡ :alias :rt :retweet
  HELP

  command :aliases do
    ap command_aliases
  end

  help :aliases, "shows aliases"

  command :reauthorize do
    get_access_token
  end

  help :reauthorize, "prompts for new oauth credentials"

  command %r{^:api\s+(get|post|delete|GET|POST|DELETE)\s+(.*)}, :as => :api do |m|
    _, http_method, path = *m
    ap twitter.send(http_method.downcase.to_sym, path)
  end
  help :api, "call twitter api ", <<-HELP
    ⚡ :api post /statuses/update.json?status=test
    ⚡ :api get /statuses/mentions.json?trim_user=true
  HELP
end
