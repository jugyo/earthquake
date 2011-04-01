class String
  def c(*codes)
    codes = codes.map { |code|
      case code
      when String, Symbol
        Earthquake.config[:color][code.to_sym] rescue nil
      else
        code
      end
    }.compact.unshift(0)
    "\e[#{codes.join(';')}m#{self}\e[0m"
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