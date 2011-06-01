module Earthquake
  module Help
    # The hash that contains help info.
    def helps
      @helps ||= {}
    end

    # Add to the in-program help system. The block that you
    # pass in to this method should return a string, nothing
    # else. .to_s gets called on the result and the following
    # gsub is run on it:
    #
    # .gsub(/(\w+)\n(\w+)/, '$1 $2')
    #
    # This removes single new lines surrounded by word characters.
    # This makes it safe to break lines up on the code and they
    # will be put together again when printed to the console.
    #
    # To separate paragraphs, use two newlines.
    #
    # If the "on" parameter has a symbol on it, it will get
    # converted to its exact string representation:
    #
    #   :help => ":help"
    #
    # Which means that retrieval from the helps hash will
    # be: helps[":help"].
    def help on, &block
      on = ':' + on.to_s if on.is_a? Symbol
      if helps.has_key? on
        error "Attempted to add duplicate help for '#{on}'"
      else
        helps[on] = block
      end
    end
  end

  extend Help

  init do
    # This is the :help command code. It searches the helps hash
    # for a block and, if it finds one, it prints its return value.to_s
    # to the console.
    #
    # If you try to add a help block to a command that already has
    # a help block asscociated with it, you will get an error.
    command %r|^:help\s+(:?[\w!]+)|, :as => :help do |m|
      if helps.has_key? m[1]
        puts helps[m[1]].call.to_s.gsub(/(\w+)\n(\w+)/, '\1 \2')
      else
        puts "No help found for '#{m[1]}'."
      end
    end
  end

  once do
    help :exit do
      %q!
Exits Earthuake and returns you back to your terminal.
      !
    end

    help :help do
      %q!
With no arguments, the :help command will print the
contents of the README into the console, piped to the
"less" command.

If you supply an argument to help, e.g. ":help :reply"
you will get help on that command.

Please note that plugins may not have help built in. It
is up to the plugin developer to write their own help
files.
      !
    end

    help :eval do
      %q!
The :eval command will evaluate whatever Ruby code you give
it. For example, to display a notification window on your
screen you could do the following:

  :eval notify "Hello, world\!"
      !
    end

    help :update do
      %q!
The :update command is what actually posts Tweets to Twitter. It is
aliased to just normal text entry, so the following two commands are
exactly the same:

  "tweeting from Earthquake."
  ":update Tweeting from Earthquake."

It is unlikely that you will ever explicitly use the :update command.
It exists mainly for internal reasons.
      !
    end

    help :reply do

      %q!
To reply to a tweet, the syntax is as follows:

  $id Tweet contents goes here.

Where $id is the 2 letter identification number that appears
next to the tweet in the stream.
      !

    end

    help :status do
      %q!
The :status commands prints out a single Tweet from its 2 letter
ID. Here's an example:

Assume that this tweet exists: "$aa samwhoo: Hello, earthquake." and
you executed the following command:

  :status $aa

The tweet $aa would be output to the command line. You can also print
out a single Tweet by just typing its ID. The following command is exactly
the same as the previous:

  $aa
      !
    end

    help :delete do
      %q!
The :delete command will delete one of your own tweets based on its
2 letter ID. Assume that you posted the following tweet:

  $aa Hello, earthquake.

The command:

  :delete $aa

Would delete it. Attempting to delete another user's tweet will result
in an error message.
      !
    end

    help :mentions do
      %q!
The :mentions command will print the last 20 mentions you had. There is
currently no support for printing more or less mentions.
      !
    end

    help :follow do
      %q!
The :follow command will cause you to start following a user. For example,
if you wanted to follow @samwhoo on Twitter, you would execute the
following command:

  :follow samwhoo
      !
    end

    help :unfollow do
      %q!
The :unfollow command will cause you to stop following someone. For example,
if you wanted to stop following @samwhoo on Twitter, you would execute the
following command:

  :unfollow samwhoo
      !
    end

    help :recent do
      %q!
The :recent command, on its own, lists recent posts on your personal timeline.
The amount of posts displayed is configurable via config[:recent_count].

Passing an argument to recent, e.g. ":recent samwhoo" will cause the comment to
display the last 20 posts by that user.

Passing an argument with a forward slash in it will cause you to print out a
list by that person, e.g. ":recent samwhoo/my-heroes" will print the last 20
posts on samwhoo's "my-heroes" list.
      !
    end

    help :user do
      %q!
The :user command will print out JSON formatted info on the person you pass
as an argument. For example, ":user samwhoo" will print out all of the info
on @samwhoo.
      !
    end

    help :search do
      %q!
The :search command will show you the last 20 posts when searching for a given
word or phrase. For example, the command ":search hello there" will give you 20
posts, all of which containing the words "hello" and "there".
      !
    end

    help :retweet do
      %q!
The :retweet command can take 1 or 2 arguments. With 1 arguments, you do a standard
retweet, like so:

  :retweet $aa

Will retweet the tweet with the ID $aa. If you want to add some text to the retweet,
you can pass in a second argument:

  :retweet $aa Omg, so funny.

This will retweet the post with "Omg, so funny." prepended to it, followed by RT and
then the original tweet.
      !
    end
    help :favorite do
      %q!
The :favorite command will favourite a tweet. Example:

  :favorite $aa

Will favorite the tweet with the ID $aa.
      !
    end
    help :unfavorite do
      %q!
The :unfavorite command will unfavorite a tweet. Example:

  :unfavorite $aa

Will unfavorite the tweet with the ID $aa.
      !
    end
    help :retweeted_by_me do
      %q!
The :retweeted_by_me command will show you the last 20 tweets that you retweeted.
      !
    end
    help :retweeted_to_me do
      %q!
The :retweeted_to_me command will show you the last 20 retweets that appeared in
your ome timeline (tweets that people you follow have retweeted).
      !
    end
    help :retweets_of_me do
      %q!
The :retweets_of_me command will how you the last 20 of your tweets that got
retweeted by someone.
      !
    end
    help :block do
      %q!
The :block command will block a user on Twitter. For example, if you wanted to block
@samwhoo, you would type:

  :block samwhoo

And you would stop receiving communications from that person.
      !
    end
    help :unblock do
      %q!
The :unblock command unblocks previously blocked users. For example, if you had
previously blocked @samwhoo and wanted to unblock him, you would type:

  :unblock samwhoo

And that would unblock them on your Twitter account.
      !
    end
    help :report_spam do
      %q!
The :report_spam command reports a user for spam. If @samwhoo was spamming you, you
would report him by typing:

  :report_spam samwhoo

And that will notify Twitter that @samwhoo is spamming you and the appropriate action
would be taken.
      !
    end
    help :messages do
      %q!
The :messages command prints out the last 20 messages you received on Twitter. Direct
messages, not tweets.
      !
    end
    help :sent_messages do
      %q!
The :sent_messages command prints out the last 20 messages you send on Twitter. Direct
messages, not tweets.
      !
    end
    help :message do
      %q!
The :message command sends a message to a specified user. Example usage:

  :message samwhoo Hello, samwhoo. How are you?

That will send the message "Hello, samwhoo. How are you?" to user @samwhoo.
      !
    end
    help :reconnect do
      %q!
The :reconnect command will tell earthquake to reconnect to Twitter. Only use
this if you're sure you have to.
      !
    end
    help :thread do
      %q!
The :thread command takes a tweet ID (2 letters prepended by a dollar sign) as an
argument and returns the thread of conversation that involves that tweet.

If you have a tweet with ID $ab that is a reply to another tweet with ID $aa, the
command ":thread $ab" will print out tweet $aa followed by an indented tweet $ab.

The best way to get an understanding of this command is to play around with it.
      !
    end
    help :update_profile_image do
      %q!
The :update_profile_image takes an image URL from your hard drive and sets your
Twitter profile image to that photo.
      !
    end
    help :open do
      %q!
The :open command will open a web page on Twitter in your browser. For example,
the command ":open samwhoo" will open "https://twitter.com/samwhoo" in my browser.
      !
    end
    help :sh do
      %q!
The :sh command will open up your shell inside of earthquake. After executing this
command, typing "exit" at the shell will return you back to earthquake and all of
the messages that you received while in shell will be printed out.
      !
    end
    help :'!' do
      %q!
The :\! command will execute an external command from inside earthquake (the same
as how Vim does it). So if you're on a Linux system, :\!ls will print a list of
files in the current directory.

The only drawback it currently has is that you will need to manually escape double
quotes. If you don't, bad things will happen.
      !
    end
    help :plugin_install do
      %q!
The :plugin_install command takes a GitHub Gist and installs it to your earthquake
plugin directory. If anything other than a GitHub Gist is passed, an error is thrown.
      !
    end
    help :edit_config do
      %q!
The :edit_config command opens up your config file in whatever command is set in
your EDITOR environment variable. If nothing is set in your EDITOR environment
variable, the command throws an error.
      !
    end
    help :alias do
      %q!
The :alias command allows you to alias any of the existing command to a new one.
Example:

  :alias h help

That will make :h map to :help when executed.
      !
    end
  end
end
