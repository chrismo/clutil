class String
  def get_indent
    scan(/^(\s*)/).flatten[0].to_s
  end

  def rbpath
    self.gsub(/\\/, '/')
  end

  def winpath
    self.gsub(/\//, "\\")
  end
end

def indent(s, amt)
  a = s.split("\n", -1)
  if amt >= 0
    a.collect! do |ln| 
      if !ln.empty? 
        (' ' * amt) + ln
      else
        ln
      end
    end
  else
    a.collect! do |ln|
      (1..amt.abs).each do ln = ln[1..-1] if ln[0..0] == ' ' end
      ln
    end
  end
  a.join("\n")
end
  
def here_ltrim(s, add_indent_amt=0)
  a = s.split("\n", -1)
  trim_indent_amt = a[0].get_indent.length
  indent(s, add_indent_amt - trim_indent_amt)
end
