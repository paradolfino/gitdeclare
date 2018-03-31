arr = %x(git branch).split("* ").strip
arr.shift
puts arr.first