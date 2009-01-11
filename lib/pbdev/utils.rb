def escapejs(s)
  s.gsub!("\\", "\\\\")
  s.gsub!("'", "\\'")
  s.gsub!("\n", "\\\n")
  s
end