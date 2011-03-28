Earthquake
====

Terminal-based Twitter Client with Streaming API.

It supports only Ruby 1.9.

**We need patches that fix the english of the documentation!**

![http://images.instagram.com/media/2011/03/21/862f3b8d119b4eeb9c52e690a0087f5e_7.jpg](http://images.instagram.com/media/2011/03/21/862f3b8d119b4eeb9c52e690a0087f5e_7.jpg)

Features
----

* You can use Twitter entirely in your Terminal.
* You can receive data in real time with Streaming API.
* You can easily extend by using Ruby.

Install
----

    gem install earthquake

Usage
----

### Launch

    $ earthquake

Commands
----

### Tweet

    ⚡ Hello World!

### Show

    ⚡ :status $xx

**$xx** is the alias of tweet id.

### Delete

    ⚡ :delete $xx

### Reply

    ⚡ :reply $xx hi!

### Retweet

    ⚡ :retweet $xx

### Timeline

    ⚡ :recent
    ⚡ :recent jugyo

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

And there are more commands!

Customize
----

The config file is **~/.earthquake/config**.

### Changing the colors

    Earthquake.config[:colors] = (31..36).to_a - [34]

The blue is excluded.

Plugin
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

The 'm' is a MatchData.

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

### Defining filters

#### Filtering by keywords

    Earthquake.init do
      filter do |item|
        if item["_stream"] && item["text"]
          item["text"] =~ /ruby/i
        else
          true
        end
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

* more intelligent completion
* spec
* change the config dir by ARGV

Copyright
----

Copyright (c) 2011 jugyo. See LICENSE.txt for further details.