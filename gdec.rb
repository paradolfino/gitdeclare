=begin

    Hi there. This is GitDeclare. I made it to help do some heavy lifting with git commits.
    You're free to use and modify your own copies of the script - but I have not tested it on multiple platforms
    and don't know of the effects thereof.
    Feel free to also send in issues to the gitdeclare repo or if you modify the code to make it better, feel free
    to also submit a pull request - I'll check it out.

    -Thanks
    Viktharien Volander

=end

require 'http_require'
require 'http://www.viktharienvolander.com/threader.rb'

class GitDeclare
    include Threader
    @@pushes = 0
    @@color_red = "\033[31m"
    @@color_green = "\033[32m"
    @@color_default = "\033[0m"
    @@commits = 1
    @@time_running = 0
    @@pool = nil

    def initialize; end

    def self.execute(param)
        stalker = %x{#{param}}
        @@time_running += 1
        if stalker.include? "nothing to commit" 
            puts @@color_red + "Stalking for #{@@time_running} secs" + @@color_default
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
            GitDeclare.execute "git commit -m \" commit #{@@commits} to pool[#{pool}] at #{Time.now.strftime("%H:%M - %d/%m/%Y")} \""
    end

    def self.atomic(summary, pool)
        open('why_commit.txt', 'a') do |file|
            file.puts "#{Time.now.strftime("%d/%m/%Y %H:%M")}:pool[#{pool}]"
        end
        changes = why.strip.split(",")
        changes.map! {|item| item = "* #{item.strip}"}
        
        open('pull_me.txt', 'a') do |file|
            file.puts "### pool[#{pool}]:"
            file.puts changes
            file.puts
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
            GitDeclare.atomic(summary, pool)
            puts "Reaping #{@@commits-1} commits to pool on branch: #{branch}"
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
