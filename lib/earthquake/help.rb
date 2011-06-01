module Earthquake
  module Help
    # The hash that contains help info.
    def helps
      @helps ||= {}
    end

    def help on, &block
      on = on.to_s if on.is_a? Symbol
      if helps.has_key? on
        error "Attempted to add duplicate help for '#{on}'"
      else
        helps[on] = block
      end
    end
  end

  init do
    command %r|^:help (:?\w+)|, :as => :help do |m|
      if helps.has_key? m[1]
        puts helps[m[1]]
      else
        puts "No help found for '#{m[1]}'"
      end
    end

    help :reply do
      "Reply to a tweet."
    end
  end

  extend Help
end
