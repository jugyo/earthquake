# encoding: UTF-8
require 'set'

module Earthquake
  module Input
    def input_filters
      @input_filters ||= []
    end

    def input_filter(&block)
      input_filters << block
    end

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
      reload
      return if text.empty?

      begin
        input_filters.each { |f| text = f.call(text) }

        if command = command(text)
          command[:block].call(command[:pattern].match(text))
        elsif !text.empty?
          puts "Command not found".c(43)
        end

        store_history
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
      case type
      when :y
        print "#{message} [Yn] ".u
        return !(gets.strip =~ /^n$/i)
      when :n
        print "#{message} [yN] ".u
        return !!(gets.strip =~ /^y$/i)
      else
        raise "type must be :y or :n"
      end
    end

    def async_e(&block)
      async { handle_api_error(&block) }
    end

    def handle_api_error(&block)
      result = block.call
      if result["error"]
        notify "[ERROR] #{result["error"]}"
      end
    end
  end

  init do
    commands.clear
    command_names.clear
    completions.clear
    input_filters.clear

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
      results = []
      regexp = /^#{Regexp.quote(text)}/

      results += command_names.grep(regexp)

      range = Readline::HISTORY.count >= 100 ? -100..-1 : 0..-1
      results += Readline::HISTORY.to_a[range].map { |line| line.split(/\s+/) }.flatten.grep(regexp)

      results
    end

    input_filter do |text|
      if text =~ %r|^:|
        text.gsub(/\$\w+/) { |var| var2id(var) || var }
      else
        text
      end
    end
  end

  extend Input
end
