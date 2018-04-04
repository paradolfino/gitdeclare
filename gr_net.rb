=begin

    Hi there. This is GR_NET (GitReaper Net). I made it to help do some heavy lifting with git commits.
    You're free to use and modify your own copies of the script - but I have not tested it on multiple platforms
    and don't know of the effects thereof.
    Feel free to also send in issues to the gitreaper repo or if you modify the code to make it better, feel free
    to also submit a pull request - I'll check it out.

    -Thanks
    Viktharien Volander

=end

require 'http_require'
require 'http://www.viktharienvolander.com/threader.rb'

class GitReaper
    include Threader
    @@pushes = 0
    @@color_red = "\033[31m"
    @@color_green = "\033[32m"
    @@color_default = "\033[0m"
    @@commits = 1
    @@time_running = 0

    def initialize
        
    end

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
        GitReaper.execute "git add ."
        sleep 1
    end

    def self.commit_loop(pool)
            GitReaper.add_wait
            GitReaper.execute "git commit -m \" commit #{@@commits} to pool[#{pool}] at #{Time.now.strftime("%H:%M - %d/%m/%Y")} \""
    end

    def self.atomic(why, pool)
        open('why_commit.txt', 'a') do |file|
            file.puts "#{Time.now.strftime("%d/%m/%Y %H:%M")}:pool[#{pool}]: #{why}"
        end
        changes = why.strip.split(",")
        changes.map! {|item| item = "* #{item.strip}"}
        
        open('pull_me.txt', 'a') do |file|
            file.puts "### pool[#{pool}]:"
            file.puts changes
            file.puts
        end
        GitReaper.add_wait
        GitReaper.execute "git commit -m \"pool[#{pool}]: #{why}\""
        
    end

    def self.exit(exit_type, pool, branch)
        case exit_type
        when "push"
            puts "Summarize changes made:"
            summary = gets.chomp
            GitReaper.atomic(summary, pool)
            GitReaper.start
        when "kill"
            puts "Wiping commits and exiting"
            system "git reset HEAD~"
        when "reap"
            puts "Summarize final changes:"
            summary = gets.chomp
            GitReaper.atomic(summary, pool)
            puts "Reaping #{@@commits-1} commits to pool on branch: #{branch}"
            GitReaper.execute "git push -u origin #{branch}"
        else
            puts "Returning to loop"
            GitReaper.threader(branch)
        end
    end

    def self.threader(branch)
       thread_pool = []
       thread_fork = [0,1]
       thread_bits = []
       thread_bits = Threader.bits
       thread_pool.push(Threader.bits_adjs[rand(Threader.bits_adjs.length)] + "-")
       thread_pool.push(Threader.bits_verbs[rand(Threader.bits_verbs.length)] + "-")
       thread_pool.push(Threader.bits_nouns[rand(Threader.bits_nouns.length)] + "-")

        6.times do
            do_fork = thread_fork[rand(thread_fork.length)]
            if do_fork == 0
                thread_pool.push(rand(9))
            else
                thread_pool.push(thread_bits[rand(thread_bits.length)])
            end
        end
        puts "Preparing to Reap on #{branch} branch."
        reaper = Thread.new do
            
            while true
                GitReaper.commit_loop(thread_pool.join(''))
            end
            
        end
        
        gets
        reaper.kill
        puts "How do you wish to exit?"
        puts "'push': pushes all commits to branch\n'kill': wipes commits and exits program\n'reap': pushes all changes"
        exit_type = gets.chomp
        GitReaper.exit(exit_type, thread_pool.join(''), branch)
        
        
    end

    def self.start

        @@pushes > 0 ? @@pushes += 1 : open('pull_me.txt', 'w') {|f| f.puts ""}; @@pushes += 1
        puts "Branch to push?"
        branch = gets.chomp
        GitReaper.threader(branch)
    end

    

end

GitReaper.start
