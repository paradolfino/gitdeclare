test = "git rev-parse --abbrev-ref HEAD"
x = %x(#{test})
puts x