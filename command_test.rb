@@time = GitDeclare.current_time
x = %x(git rev-parse --abbrev-ref HEAD)
@@branch = x
puts "On #{@@branch} branch"