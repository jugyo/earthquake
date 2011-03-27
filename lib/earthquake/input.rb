# encoding: UTF-8
require 'set'

module Earthquake
  module Input
    def commands
      @commands ||= []
    end

    def command_names
      @command_names ||= Set.new
    end

    def completions
      @completions ||= []
    end

    def completion(&block)
      completions << block
    end

    def input(text)
      begin
        reload
      rescue Exception => e
        error e
      end

      begin
        text = text.gsub(/\$\w+/) do |var|
          var2id(var) || var
        end

        if command = command(text)
          command[:block].call(command[:pattern].match(text))
        elsif !text.empty?
          puts "Command not found".c(43)
        end
      rescue Exception => e
        error e
      end
    end

    def command(pattern, options = {}, &block)
      if block
        if pattern.is_a?(String) || pattern.is_a?(Symbol)
          command_name = ":#{pattern}"
          command_names << command_name
          if block.arity > 0
            pattern = %r|^#{command_name}\s+(.*)$|
          else
            pattern = %r|^#{command_name}$|
          end
        end
        command_names << ":#{options[:as]}" if options[:as]
        commands << {:pattern => pattern, :block => block}
      else
        commands.detect {|c| c[:pattern] =~ pattern}
      end
    end

    def confirm(message, type = :y)
      message = message.c(36)
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
    commands.clear
    command_names.clear
    completions.clear

    Readline.basic_word_break_characters = " \t\n\"\\'`$><=;|&{(@"

    Readline.completion_proc = lambda do |text|
      completions.inject([]) do |results, completion|
        begin
          results + (completion.call(text) || [])
        rescue Exception => e
          error e
          results
        end
      end
    end

    completion do |text|
      if Readline.line_buffer =~ /^\s*#{Regexp.quote(text)}/
        command_names.grep /^#{Regexp.quote(text)}/
      end
    end
  end

  extend Input
end
