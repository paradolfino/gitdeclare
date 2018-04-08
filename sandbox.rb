#!/usr/bin/env ruby

require 'httparty'

class GitDeclare
    include HTTParty
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
    @@declare = nil
    @@uri = "http://localhost:3000/declarations"
    @@cwd = nil
    @@origin = nil

    def initialize; end

    def self.current_time
        Time.now.strftime("%H:%M")
    end

    def self.execute(param)
        puts param
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
        open("#{Dir.pwd}/changelog.txt", 'a') do |file|
            file.puts "#{@@date}: #{@@time} - #{GitDeclare.current_time}:pool[#{pool}]"
        end
        open("#{Dir.pwd}/readme.md", 'a') do |file|
            file.puts "\n##### #{@@date}: #{@@time} - #{GitDeclare.current_time}:pool[#{pool}]"
        end
        GitDeclare.post("#{@@uri}/#{@@declare}/entries", body: {content: pool})
        @@changes << pool
        if @@stage == 1
            GitDeclare.put("#{@@uri}/#{@@declare}", body: {content: summary})
            @@changes.map! {|item| item = "* #{item.strip}"}
            open('pull_me.txt', 'a') do |file|
                file.puts "[#{summary}]"
                file.puts "### #{@@date}[#{@@starttime} - #{GitDeclare.current_time}]:"
                file.puts @@changes
                file.puts
            end
        end
        GitDeclare.add_wait
        GitDeclare.execute "git commit -m \"#{pool}\""
        
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
            puts "Summarize final changes:"
            summary = gets.chomp
            @@stage = 1
            GitDeclare.atomic(summary, pool)
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
        @@cwd = Dir.pwd.split("/").last
        @@origin = %x(git remote get-url --push origin)
        @@branch = %x(git rev-parse --abbrev-ref HEAD).strip
        puts "On #{@@branch} branch"
        if @@pushes > 0
            @@pushes += 1
        else
            open('pull_me.txt', 'w') {|f| f.puts ""}
            @@pushes += 1
            res = GitDeclare.post(@@uri, body: {content: "New Declaration", directory: "New", git: "New"})
            body = JSON.parse(res.body)
            @@declare = body["id"]
            
        end
        if @@branch == "master" then puts "What branch are you working on?"; @@branch = gets.chomp end
        
        GitDeclare.threader(@@branch)
    end

    

end

GitDeclare.start
