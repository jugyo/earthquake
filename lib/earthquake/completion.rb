# encoding: UTF-8
require 'set'

module Earthquake
  module Completion
    def compl_screen_name(name)
      names = Earthquake.cache.fetch("completion:screen_name") { [] }
      names.grep(/^#{Regexp.escape(name.gsub(/^@/,""))}/)
    end
  end

  init do
    completions.clear

    completion do |text|
      case Readline.line_buffer
      when /@([a-zA-Z0-9_]+)$/
        compl_screen_name($1)
      when /^\s*#{Regexp.quote(text)}/
        command_names.grep /^#{Regexp.quote(text)}/
      end
    end
  end

  extend Completion
end
