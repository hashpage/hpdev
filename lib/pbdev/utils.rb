def escapejs(s)
  s.gsub!("\\", "\\\\")
  # s.gsub!("'", "\\'") doesn't work! 
  s = s.gsub("'", "\\ddd3702caa3736ddc7f690385fd42512").gsub("ddd3702caa3736ddc7f690385fd42512", "'") # do you know better solution?
  s.gsub!("\n", "\\\n")
  s
end