#!/usr/bin/env ruby
require_relative 'git.rb'
require_relative 'helpers.rb'

command=ARGV.first

case command
when 'start'
   require_argument(:feature, :start)
   feature = ARGV[1]

   exit if !confirm("Create feaure branch named: '#{feature}' ?")

   Git::run_safe([
      "git branch \"#{feature}\" master",
      "git checkout \"#{feature}\"",
      # Automatically setup remote tracking branch
      "git config branch.#{feature}.remote origin",
      "git config branch.#{feature}.merge refs/heads/#{feature}",
      "git config branch.#{feature}.rebase true"
   ])

   puts "Successfully created a new feature-branch: #{feature}"

when 'status'
   current = Git::current_branch
   Git::run_safe("git fetch")

   upstream = `git-rev-parse --verify --quiet #{current}@{upstream} 2>/dev/null`.strip
   if upstream == ''
      die "Your branch #{current} hasn't been pushed"
   end

   git_command = 'git log --graph --boundary --color=always --decorate --date-order'
   incoming = `#{git_command} #{current}..#{upstream}`.strip
   outgoing = `#{git_command} #{upstream}..#{current}`.strip
   incoming = nil if incoming == ''
   outgoing = nil if outgoing == ''

   if (incoming && outgoing)
      # Show the whole history graph (... == through common ancestor)
      puts `#{git_command} #{upstream}...#{current}`.strip
      puts HIGHLIGHT
      puts "Your branch has diverged from the remote branch"
   elsif incoming
      puts incoming
      puts HIGHLIGHT
      puts "Your branch is behind the remote branch"
   elsif outgoing
      puts outgoing
      puts HIGHLIGHT
      puts "Your branch is ahead of the remote branch"
   else
      puts HIGHLIGHT
      puts "Your branch is up to date"
   end
   print HIGHLIGHT_OFF


when 'finish'
   fail_on_local_changes

   require_argument(:feature, :finish)
   feature = ARGV[1]

   exit 1 if !confirm("Finish feaure branch named: '#{feature}' ?")

   commands = [
      "git checkout master",
      # pull the latest changes and rebase the unpushed master commits if any.
      "git pull --rebase",
      # merge the feature branch into master
      "git merge --no-ff  \"#{feature}\"",
      # delete the local feature-branch
      "git branch -d \"#{feature}\"",
      # delete the remote branch we'll leave this off for now
      #"git push origin :\"#{feature}\"",
      # push the the merge to our origin
      #"git push origin",
   ]
   Git::run_safe(commands)

   puts "Successfully merged feature-branch: #{feature} into master"

when 'switch'
   require_argument(:feature, :switch)
   feature = ARGV[1]

   Git::run_safe("git checkout \"#{feature}\"")
   Git::show_stashes_saved_on(feature)


when 'list'
   options = {
      :feature => Git::feature_branches(:unmerged)
   }
   if ARGV.include?('-v')
      options[:merged] = Git::feature_branches(:merged)
   end
   Git.show_branch_list(options)

when 'stashes'
   current_branch = nil

   if !ARGV.include?('-v')
      current_branch = Git::current_branch
   end

   Git::show_stashes_saved_on(current_branch)

else
   display_feature_help
end

