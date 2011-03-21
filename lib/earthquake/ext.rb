class String
  def c(*codes)
    "\e[#{codes.join;}m#{self}\e[0m"
  end
end