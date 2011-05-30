module Twitter
  class JSONStream
    protected
    def reconnect_after timeout
      @reconnect_callback.call(timeout, @reconnect_retries) if @reconnect_callback

      if timeout == 0
        reconnect @options[:host], @options[:port]
        start_tls if @options[:ssl]
      else
        EventMachine.add_timer(timeout) do
          reconnect @options[:host], @options[:port]
          start_tls if @options[:ssl]
        end
      end
    end
  end
end

module TwitterOAuth
  class Client
    private
    def consumer
      @consumer ||= OAuth::Consumer.new(
        @consumer_key,
        @consumer_secret,
        { :site => 'https://api.twitter.com', :proxy => @proxy }
      )
    end
  end
end

class String
  def c(*codes)
    codes = codes.flatten.map { |code|
      case code
      when String, Symbol
        Earthquake.config[:color][code.to_sym] rescue nil
      else
        code
      end
    }.compact.unshift(0)
    "\e[#{codes.join(';')}m#{self}\e[0m"
  end

  # This method colors the string according to a regular
  # expresion, a string or nil. When nil is passed, the entire
  # string is colored.
  #
  # You can pass either a second argument for the colour or
  # a block the receives one argument; the match.
  def coloring(pattern = nil, color = nil, &block)
    pattern = self.to_s if pattern.nil?
    self.gsub(pattern) do |match|
      applied_colors = $`.scan(/\e\[[\d;]+m/)
      c = color || block.call(match)
      "#{match.c(c)}#{applied_colors.join}"
    end
  end

  t = {
    ?& => "&amp;",
    ?< => "&lt;",
    ?> => "&gt;",
    ?' => "&apos;",
    ?" => "&quot;",
  }

  define_method(:u) do
    gsub(/(#{Regexp.union(t.values)})/o, t.invert)
  end

  define_method(:e) do
    gsub(/[#{t.keys.join}]/o, t)
  end
end
