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
        if command = commands.detect { |c| c[:pattern] =~ text }
          command[:block].call($~)
        end
      rescue => e
        notify "[ERROR] #{e}"
      end
    end

    def command(pattern, &block)
      if block
        if pattern.is_a?(String) || pattern.is_a?(Symbol)
          command_name = "/#{pattern}"
          command_names << command_name
          pattern = /^#{Regexp.quote(command_name)}\s*(.*)$/
        end
        commands << {:pattern => pattern, :block => block}
      else
        commands.detect { |c| c[:name] == name }
      end
    end
  end
end
