#!/usr/bin/env ruby


class GitDeclare
    @@pushes = 0
    @@stage = 0
    @@changes = []
    @@color_red = "\033[31m"
    @@color_green = "\033[32m"
    @@color_default = "\033[0m"
    @@commits = 1
    @@starttime = Time.now.strftime("%H:%M")
    @@date = Time.now.strftime("%d/%m/%Y")
    @@time = nil
    @@pool = nil
    @@branch = nil

    def initialize; end

    def self.current_time
        Time.now.strftime("%H:%M")
    end

    def self.execute(param)
        stalker = %x{#{param}}
        
        if stalker.include? "nothing to commit" 
            
        elsif stalker.include? "insert"
            puts @@color_green + stalker + @@color_default
            puts "#{@@commits} changes saved"
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
            GitDeclare.execute "git commit -m \" #{pool} : #{GitDeclare.serialize} \""
    end

    def self.atomic(summary, pool, goal=nil)
        @@changes << pool
        if @@stage == 1  && @@branch != "master"
            @@changes.map! {|item| item = "* #{item.strip}"}
            open('pull_me.txt', 'a') do |file|
                file.puts "[#{summary}]"
                file.puts "### #{@@date}[#{@@starttime} - #{GitDeclare.current_time}]:"
                file.puts @@changes
                file.puts
                file.puts "What's Next? #{goal}"
            end
        end
        GitDeclare.add_wait
        GitDeclare.execute "git commit -m \"update pull request header : #{GitDeclare.serialize}\""
        
    end

    def self.serialize
      table = ("a".."z").to_a
      serial = []
      6.times { serial << table[rand(table.length)] }
      serial.join("")
    end


    def self.exit(exit_type, pool, branch)
        case exit_type
        when "new"
            GitDeclare.atomic(nil, pool)
            GitDeclare.start
        when "reset"
            puts "Wiping commits and exiting"
            system "git reset HEAD~"
        when "push"
            if @@branch != "master"
                puts "Summarize final changes:"
                summary = gets.chomp
                puts "What is your next goal?"
                goal = gets.chomp
                @@stage = 1
                GitDeclare.atomic(summary, pool, goal)
            end
            GitDeclare.execute "git push -u origin #{branch}"
        when "switch"
            GitDeclare.atomic(nil, pool)
            puts "What branch are you working on?"; @@branch = gets.chomp
            GitDeclare.start
        else
            puts "Returning to loop"
            GitDeclare.threader(branch)
        end
    end

    def self.threader(branch)
        puts "What are you working on with the #{branch} branch?"
        @@pool = gets.chomp
        puts "You're now working on: \"#{@@pool}\" on #{branch} branch. #{@@color_red}GitDeclare is watching for changes#{@@color_default}."
        puts "When you're done with this change, press [Enter] to make a commit and start a new declaration."
        declare = Thread.new do
            
            while true
                GitDeclare.commit_loop(@@pool)
            end
            
        end
        
        gets
        declare.kill
        puts "How do you wish to exit?"
        puts "
        'new': logs the commit pool and starts a new declaration
        'reset': wipes commits and exits program
        'push': pushes all changes
        'switch': logs commit, starts new declare, and switches branch"
        exit_type = gets.chomp
        GitDeclare.exit(exit_type, @@pool, branch)
        
        
    end

    def self.start
        @@time = GitDeclare.current_time
        x = %x(git rev-parse --abbrev-ref HEAD)
        @@branch = x.strip
        puts "On #{@@branch} branch"
        @@pushes > 0 ? @@pushes += 1 : open('pull_me.txt', 'w') {|f| f.puts ""}; @@pushes += 1
        if @@branch == nil then puts "What branch are you working on?"; @@branch = gets.chomp end
        
        GitDeclare.threader(@@branch)
    end

    

end

GitDeclare.start
