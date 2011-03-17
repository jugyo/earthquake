# encoding: UTF-8
module Earthquake
  module Input
    attr_accessor :command_prefix

    def commands
      @commands ||= []
    end

    def command_names
      @command_names ||= []
    end

    def input(text)
      begin
        if command = commands.detect { |c| c[:pattern] =~ text }
          command[:block].call($~)
        end
      rescue => e
        puts "[ERROR] #{e}\n#{e.backtrace.join("\n")}"
      end
    end

    def command(pattern, options = {}, &block)
      if block
        if pattern.is_a?(String) || pattern.is_a?(Symbol)
          command_name = "#{command_prefix}#{pattern}"
          command_names << command_name
          pattern = /^#{Regexp.quote(command_name)}\s*(.*)$/
        end
        command_names << "#{command_prefix}#{options[:as]}" if options[:as]
        commands << {:pattern => pattern, :block => block}
      else
        commands.detect { |c| c[:name] == name }
      end
    end

    def confirm(message, type = :y)
      case type
      when :y
        print "#{message} [Yn] "
        return !(gets.strip =~ /^n$/i)
      when :n
        print "#{message} [yN] "
        return !!(gets.strip =~ /^y$/i)
      else
        raise "type must be :y or :n"
      end
    end
  end

  init do
    Readline.completion_proc = lambda { |text|
      command_names.grep /^#{Regexp.quote(text)}/
    }

    Thread.start do
      while buf = Readline.readline("[earthquake] ", true)
        input(buf.strip)
      end
    end

    self.command_prefix = '/'

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
