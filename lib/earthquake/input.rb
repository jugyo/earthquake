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

    def command_aliases
      @command_aliases ||= {}
    end

    def alias_command(name, target)
      command_aliases[name.to_s] = target.to_s
    end

    def input(text)
      return if text.empty?

      input_filters.each { |f| text = f.call(text) }

      if command = command(text)
        command[:block].call(command[:pattern].match(text))
      elsif !text.empty?
        puts "Command not found".c(43)
      end
    rescue Exception => e
      error e
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
        return !(ask("#{message} [Yn] ".u) =~ /^n$/i)
      when :n
        return !!(ask("#{message} [yN] ".u) =~ /^y$/i)
      else
        raise "type must be :y or :n"
      end
    end

    def ask(message)
      Readline.readline(message, false)
    end

    def async_e(&block)
      async { handle_api_error(&block) }
    end

    def handle_api_error(&block)
      result = block.call
      if result["error"]
        error "[ERROR] #{result["error"]}"
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
          results | (completion.call(text) || [])
        rescue Exception => e
          error e
          results
        end
      end
    end

    completion do |text|
      regexp = /^#{Regexp.quote(text)}/
      results = (command_names + command_aliases.keys.map {|i| ":#{i}"}).grep(regexp)
      history = Readline::HISTORY.reverse_each.take(config[:history_size]) | @tweets_for_completion
      history.inject(results){|r, line|
        r | line.split.grep(regexp)
      }
    end

    @tweets_for_completion ||= []

    output do |item|
      next unless item["text"]
      @tweets_for_completion << [item["user"]["screen_name"], item["text"]].join(" ")
      @tweets_for_completion.shift if @tweets_for_completion.size > config[:history_size]
    end

    input_filter do |text|
      if text =~ %r|^:(\w+)|
        if target = command_aliases[$1]
          text = text.sub(%r|^:\w+|, ":#{target}")
        end
        text = text.gsub(/\$\w+/) { |var| var2id(var) || var }
      end
      text
    end
  end

  extend Input
end
