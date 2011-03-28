# encoding: UTF-8
require 'set'

module Earthquake
  module Completion
    [:screen_name,:hashtag].each do |x|
      define_method(:"compl_#{x}") do |name|
        names = Earthquake.cache.fetch("completion:#{x}") { [] }
        names.grep(/^#{Regexp.escape(name)}/)
      end
    end
  end

  init do
    completions.clear

    completion do |text|
      case Readline.line_buffer
      when /@([a-zA-Z0-9_]+)$/
        compl_screen_name($1)
      when /#([a-zA-Z0-9_\-]+)$/
        compl_hashtag($1).map{|x| "#"+x }
      when /^\s*#{Regexp.quote(text)}/
        command_names.grep /^#{Regexp.quote(text)}/
      end
    end
  end

  extend Completion
end
