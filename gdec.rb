=begin

    Hi there. This is GitDeclare. I made it to help do some heavy lifting with git commits.
    You're free to use and modify your own copies of the script - but I have not tested it on multiple platforms
    and don't know of the effects thereof.
    Feel free to also send in issues to the gitdeclare repo or if you modify the code to make it better, feel free
    to also submit a pull request - I'll check it out.

    -Thanks
    Viktharien Volander

=end


class GitDeclare
    @@pushes = 0
    @@stage = 0
    @@changes = []
    @@color_red = "\033[31m"
    @@color_green = "\033[32m"
    @@color_default = "\033[0m"
    @@commits = 1
    @@time = Time.now.strftime("%H:%M - %d/%m/%Y")
    @@pool = nil

    def initialize; end

    def self.execute(param)
        stalker = %x{#{param}}
        @@time_running += 1
        if stalker.include? "nothing to commit" 
            
        elsif stalker.include? "insert"
            puts @@color_green + stalker + @@color_default
            puts "#{@@commits} commits to pool so far"
            @@commits += 1
        end
    end

    def self.add_wait
        sleep 1
        GitDeclare.execute "git add ."
        sleep 1
    end

    def self.commit_loop(pool)
            GitDeclare.add_wait
            GitDeclare.execute "git commit -m \" #{pool} \""
    end

    def self.atomic(summary, pool)
        open('why_commit.txt', 'a') do |file|
            file.puts "#{@@time}:pool[#{pool}]"
        end
        
        @@changes.map! {|item| item = "* #{item.strip}"}
        if @@stage == 1
            open('pull_me.txt', 'a') do |file|
                file.puts "[#{summary}]"
                file.puts "### [#{@@time}]:"
                file.puts @@changes
                file.puts
            end
        end
        GitDeclare.add_wait
        GitDeclare.execute "git commit -m \"pool[#{pool}]\""
        
    end

    def self.exit(exit_type, pool, branch)
        case exit_type
        when "new"
            GitDeclare.atomic(pool)
            GitDeclare.start
        when "reset"
            puts "Wiping commits and exiting"
            system "git reset HEAD~"
        when "push"
            puts "Summarize final changes:"
            summary = gets.chomp
            @@stage = 1
            GitDeclare.atomic(summary, pool)
            GitDeclare.execute "git push -u origin #{branch}"
        else
            puts "Returning to loop"
            GitDeclare.threader(branch)
        end
    end

    def self.threader(branch)
        puts "What are you working on next?"
        @@pool = gets.chomp
        puts "Working on: #{@@pool} on #{branch} branch."
        declare = Thread.new do
            
            while true
                GitDeclare.commit_loop(@@pool)
            end
            
        end
        
        gets
        declare.kill
        puts "How do you wish to exit?"
        puts "'push': pushes all commits to branch\n'kill': wipes commits and exits program\n'reap': pushes all changes"
        exit_type = gets.chomp
        GitDeclare.exit(exit_type, @@pool, branch)
        
        
    end

    def self.start

        @@pushes > 0 ? @@pushes += 1 : open('pull_me.txt', 'w') {|f| f.puts ""}; @@pushes += 1
        puts "Branch to push?"
        branch = gets.chomp
        GitDeclare.threader(branch)
    end

    

end

GitDeclare.start
