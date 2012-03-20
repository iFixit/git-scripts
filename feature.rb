#!/usr/bin/env ruby
require_relative 'git.rb'
require_relative 'helpers.rb'

command=ARGV.first

case command
when 'start'
   require_argument(:feature, :start)
   feature = ARGV[1]

   exit if !confirm("Create feaure branch named: '#{feature}' ?")

   Git::run_safe("git branch \"#{feature}\" master")
   Git::run_safe("git checkout \"#{feature}\"")
   # Automatically setup remote tracking branch
   Git::run_safe("git config branch.#{feature}.remote origin")
   Git::run_safe("git config branch.#{feature}.merge refs/heads/#{feature}")
   Git::run_safe("git config branch.#{feature}.rebase true")

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

   Git::run_safe("git checkout master")
   # pull the latest changes and rebase the unpushed master commits if any.
   Git::run_safe("git pull --rebase")
   # merge the feature branch into master
   Git::run_safe("git merge --no-ff  \"#{feature}\"")
   # delete the local feature-branch
   Git::run_safe("git branch -d \"#{feature}\"")
   # delete the remote branch we'll leave this off for now
   # Git::run_safe("git push origin :\"#{feature}\"")
   # push the the merge to our origin
   # Git::run_safe("git push origin")

   puts "Successfully merged feature-branch: #{feature} into master"

when 'switch'
   require_argument(:feature, :switch)
   feature = ARGV[1]

   Git::run_safe("git checkout \"#{feature}\"")
   Git::show_stashes_saved_on(feature)

when 'pull'
   Git::run_safe("git fetch")

   current = Git::current_branch
   upstream = "#{current}@{upstream}"
   upstream_hash = Git::branch_hash(upstream)

   if upstream_hash == ''
      die "Your branch #{current} hasn't been pushed, nothing to pull from"
   end

   old_branch_hash = Git::branch_hash(current)
   Git::run_safe("git rebase --preserve-merges origin/#{current}")
   if Git::branch_hash(current) == old_branch_hash
      die "No changes in the remote branch. Your branch is up to date."
   end

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

