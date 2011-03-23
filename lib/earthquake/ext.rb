class String
  def c(*codes)
    "\e[#{codes.join;}m#{self}\e[0m"
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