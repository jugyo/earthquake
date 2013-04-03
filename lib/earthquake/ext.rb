module Twitter
  class JSONStream
    protected
    def reconnect_after timeout
      @reconnect_callback.call(timeout, @reconnect_retries) if @reconnect_callback

      if timeout == 0
        reconnect @options[:host], @options[:port]
        start_tls if @options[:ssl]
      else
        EM.add_timer(timeout) do
          reconnect @options[:host], @options[:port]
          start_tls if @options[:ssl]
        end
      end
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

  def coloring(pattern, color = nil, &block)
    self.gsub(pattern) do |i|
      applied_colors = $`.scan(/\e\[[\d;]+m/)
      c = color || block.call(i)
      "#{i.c(c)}#{applied_colors.join}"
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

  def indent(count, char = ' ')
    (char * count) + gsub(/(\n+)/) { |m| m + (char * count) }
  end

  def trim_indent
      lines = self.split("\n")
      unindent = self.split("\n").select { |s| s !~ /^\s$/ }.map { |s| s.index(/[^\s]/) || 0 }.min
      lines.map { |s| s.gsub(/^#{' ' * unindent}/, '') }.join("\n")
  end
end
