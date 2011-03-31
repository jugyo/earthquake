class String
  def c(*codes)
    if codes.size > 1
      result = self
      codes.each do |code|
        result = result.c(code)
      end
      result
    else
      code = codes[0]
      if code.is_a?(String) || code.is_a?(Symbol)
        code = Earthquake.config["color"][code.to_s]
      end
      "\e[#{code}m#{self}\e[0m"
    end
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