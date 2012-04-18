Earthquake
====

Terminal-based Twitter Client with Streaming API support.
Only supports Ruby 1.9.

Homepage: [https://github.com/jugyo/earthquake](https://github.com/jugyo/earthquake)  
Twitter: [http://twitter.com/earthquakegem](http://twitter.com/earthquakegem)  
Changelog'd: [earthquake: Twitter terminal client with streaming API support](http://thechangelog.com/post/4005924669/earthquake-twitter-client-on-terminal-with-streaming-api)  
Demo: [http://www.youtube.com/watch?v=S2KtBGrIe5c](http://www.youtube.com/watch?v=S2KtBGrIe5c)  
Slide: [http://www.slideshare.net/jugyo/earthquakegem](http://www.slideshare.net/jugyo/earthquakegem)  

**We need patches that fix the english of the documentation!**

![http://images.instagram.com/media/2011/03/21/862f3b8d119b4eeb9c52e690a0087f5e_7.jpg](http://images.instagram.com/media/2011/03/21/862f3b8d119b4eeb9c52e690a0087f5e_7.jpg)

Features
----

* Use Twitter entirely in your Terminal.
* Receive data in real time with Streaming API.
* Easily extend using Ruby.

Install
----

You'll need openssl and readline support with your 1.9.2. If you are
using rvm you can run:

    $ rvm pkg install openssl
    $ rvm remove 1.9.2
    $ rvm install 1.9.2 --with-openssl-dir=$HOME/.rvm/usr \
      --with-readline-dir=$HOME/.rvm/usr

Then install the gem:

    $ gem install earthquake

**Ubuntu:** EventMachine needs the package libssl-dev.

    $ sudo apt-get install libssl-dev

Usage
----

### Launch

    $ earthquake

Commands
----

### Tweet

    ⚡ Hello World!

### Show

    ⚡ $xx

**$xx** is the alias of tweet id.

### Reply

    ⚡ $xx hi!

### Delete

    ⚡ :delete $xx

### Retweet

    ⚡ :retweet $xx

### Timeline

    ⚡ :recent
    ⚡ :recent jugyo

### Lists

    ⚡ :recent yugui/ruby-committers

### Search

    ⚡ :search #ruby

### Eval

    ⚡ :eval Time.now

### Exit

    ⚡ :exit

### Reconnect

    ⚡ :reconnect

### Restart

    ⚡ :restart

### Threads

    ⚡ :thread $xx

### Install Plugins

    ⚡ :plugin_install https://gist.github.com/899506

### Alias

    ⚡ :alias :rt :retweet

### Tweet Ascii Art

    ⚡ :update[ENTER]
    [input EOF (e.g. Ctrl+D) at the last]
        ⚡
       ⚡
        ⚡
       ⚡
    ^D

### View Ascii Art

    # permanently
    ⚡ :eval config[:raw_text] = true

    # temporarily(with :status, :recent or :thread etc...)
    ⚡ :aa :status $aa

### Stream Filter Tracking

    # keywords
    ⚡ :filter keyword earthquakegem twitter

    # users
    ⚡ :filter user jugyo matsuu

    # return to normal user stream
    ⚡ :filter off

### Show config

    # All config
    ⚡ :config

    # config for :key
    ⚡ :config key

### Set config

    # set config for :key to (evaluated) value
    ⚡ :config key 1 + 1
    2

And more!

Configuration
----

The default earthquake directory is ~/.earthquake.

The config file is **~/.earthquake/config**.

### Changing the earthquake directory

You can change the directory at launch by entering a directory as an argument. For example:

    $ earthquake ~/.earthquake_foo

### Changing the colors for user name

    # ~/.earthquake/config
    # For example, to exclude blue:
    Earthquake.config[:colors] = (31..36).to_a - [34]

### Changing the color scheme

    # ~/.earthquake/config
    Earthquake.config[:color] = {
      :info => 34,
      :notice => 41,
      :event  => 46,
      :url => [4, 34]
    }

### Tracking specified keywords

    # ~/.earthquake/config
    Earthquake.config[:api] = {
      :method => 'POST',
      :host => 'stream.twitter.com',
      :path => '/1/statuses/filter.json',
      :ssl => true,
      :filters => %w(Twitter Earthquake)
    }

### Tracking specified users

    # ~/.earthquake/config
    Earthquake.config[:api] = {
      :method => 'POST',
      :host => 'stream.twitter.com',
      :path => '/1/statuses/filter.json',
      :ssl => true,
      :params => {
        :follow => '6253282,183709371' # @twitterapi @sitestreams
      }
    }

### Defining aliases

    # ~/.earthquake/config
    Earthquake.alias_command :rt, :retweet

### Default confirmation type

    # ~/.earthquake/config
    Earthquake.config[:confirm_type] = :n

### HTTP proxy support

Please set environment variable *http_proxy* if you want earthquake to use an http proxy.
    
Desktop Notifications
----

To enable desktop notifications, install one of the following:

* ruby-growl (gem install ruby-growl)
* growlnotify (http://growl.info/extras.php#growlnotify)
* notify-send (sudo aptitude install libnotify-bin)
* libnotify (https://github.com/splattael/libnotify)

Call Earthquake.notify for desktop notification.
You can try it by using the :eval command:

    ⚡ :eval notify 'Hello World!'

Plugins
----

See [https://github.com/jugyo/earthquake/wiki](https://github.com/jugyo/earthquake/wiki)

Making Plugins
----

**~/.earthquake/plugin** is the directory for plugins.
At launch, Earthquake tries to load files under this directory.
The block that is specified for Earthquake.init will be reloaded at any command line input.

### Defining your commands

#### A command named 'foo':

    Earthquake.init do
      command :foo do
        puts "foo!"
      end
    end

#### Handling the command args:

    Earthquake.init do
      command :hi do |m|
        puts "Hi #{m[1]}!"
      end
    end

'm' is a [http://www.ruby-doc.org/core/classes/MatchData.html](MatchData) object.

#### Using regexp:

    Earthquake.init do
      # Usage: :add 10 20
      command %r|^:add (\d+)\s+(\d+)|, :as => :add do |m|
        puts m[1].to_i + m[2].to_i
      end
    end

### Handling outputs

#### Keyword notifier:

    Earthquake.init do
      output do |item|
        next unless item["_stream"]
        if item["text"] =~ /ruby/i
          notify "#{item["user"]["screen_name"]}: #{item["text"]}"
        end
      end
    end

#### Favorite notifier:

    Earthquake.init do
      output do |item|
        case item["event"]
        when "favorite"
          notify "[favorite] #{item["source"]["screen_name"]} => #{item["target"]["screen_name"]} : #{item["target_object"]["text"]}"
        end
      end
    end

### Defining filters for output

#### Filtering by keywords

    Earthquake.init do
      output_filter do |item|
        if item["_stream"] && item["text"]
          item["text"] =~ /ruby/i
        else
          true
        end
      end
    end

### Replacing the output for tweets

    Earthquake.init do
      output :tweet do |item|
        next unless item["text"]
        name = item["user"]["screen_name"]
        puts "#{name.c(color_of(name))}: foo"
      end
    end

### Defining completion

    Earthquake.init do
      completion do |text|
        ['jugyo', 'earthquake', '#eqrb'].grep(/^#{Regexp.quote(text)}/)
      end
    end

TODO
----

* mark my tweet
* Earthquake should parse ARGV
* ruby1.9nize
* guideline for plugin
* deal proxy
* spec

Copyright
----

Copyright (c) 2011 jugyo. See LICENSE.txt for further details.
