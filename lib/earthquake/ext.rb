class String
  def c(*codes)
    "\e[#{codes.join;}m#{self}\e[0m"
  end

  def cn(name)
    default = {
      :info    => 90, # timestamp
      :private => 31, # [P] for protected tweet
      :mark    => 90, # $xx
      :event   => 42, # such as delete, favorite, unblock, etc
      :url     => [4, 36], # URL highlight
    }
    color = Earthquake.config["color_#{name}".to_sym] || default[name.to_sym]
    str = self
    [color].flatten.each{|color|
      # for multiple colorize. [4, 36] means underline and cyan
      # see also: http://pueblo.sourceforge.net/doc/manual/ansi_color_codes.html
      str = str.c(color)
    }
    str
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
