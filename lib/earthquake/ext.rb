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
    }.compact
    codes.flatten.inject(self) { |str, c| "<#{c}>#{str}</#{c}>" } 
  end

  def to_esq
    _self = self.dup
    codes, text = [], []
    tag = /<(\/?)(\d+)>/
    pre_tag = _self[/.*?(?=#{tag})/]
    while _self.sub!(tag, '')
      md = $~
      code = "\e[#{md[2]}m"
      body = md.post_match[/.*?(?=#{tag})/]
      if md[1].empty?
        codes.push code
        text.push code
      else
        codes.pop
        text.push "\e[0m"
        text.push codes.join
        # codes.clear if codes.last == code
      end
      text.push body
    end
    pre_tag + text.join + md.post_match
  end

  def u
    gsub(/&(lt|gt|amp|quot|apos);/) do |s|
      case s
        when '&amp;' then '&'
        when '&lt;' then '<'
        when '&gt;' then '>'
        when '&apos;' then "'"
        when '&quot;' then '"'
      end
    end
  end

  def e
    gsub(/[&<>'"]/) do |s|
      case s
        when '&' then '&amp;'
        when '<' then '&lt;'
        when '>' then '&gt;'
        when "'" then '&apos;'
        when '"' then '&quot;'
      end
    end
  end
end
