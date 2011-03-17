# encoding: UTF-8
module Earthquake
  module Input
    def commands
      @commands ||= []
    end

    def command_names
      @command_names ||= []
    end

    def input(text)
      begin
        reload if config[:debug]
        if command = commands.detect { |c| c[:pattern] =~ text }
          command[:block].call($~)
        elsif !text.empty?
          puts "<yellow>Command not found</yellow>".termcolor
        end
      rescue => e
        puts "[ERROR] #{e}\n#{e.backtrace.join("\n")}"
      end
    end

    def command(pattern, options = {}, &block)
      if block
        if pattern.is_a?(String) || pattern.is_a?(Symbol)
          command_name = "#{config[:command_prefix]}#{pattern}"
          command_names << command_name
          pattern = /^#{Regexp.quote(command_name)}\s*(.*)$/
        end
        command_names << "#{config[:command_prefix]}#{options[:as]}" if options[:as]
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

    config[:command_prefix] ||= '/'

    commands.clear
  end

  extend Input
end
