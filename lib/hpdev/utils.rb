def escapejs(s)
  s.gsub!("\\", "\\\\")
  # s.gsub!("'", "\\'") doesn't work! 
  s = s.gsub("'", "\\ddd3702caa3736ddc7f690385fd42512").gsub("ddd3702caa3736ddc7f690385fd42512", "'") # do you know better solution?
  s.gsub!("\r", "")
  s.gsub!("\n", "\\\n")
  s
end

def url(mode, server, path = nil)
  path = "" unless path
  case mode
  when :production
    return "http://#{server}.hashpage.com/#{path}"
  when :simulation
    return "http://#{server}.hashpage.local/#{path}"
  when :development
    return "http://localhost:9876/#{server}/#{path}"
  end
  "unknown url mode"
end