module Earthquake
  module Help
    def helps
      @helps ||= {}
    end

    def help(name, summary, usage = nil)
      helps[name] = summary, usage ? usage.trim_indent : nil
    end
  end

  init do
    helps.clear
  end

  extend Help
end
