class String
  alias_method :t, :termcolor

  def e
    TermColor.escape(self)
  end
end