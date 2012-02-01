#!/usr/bin/env ruby
require_relative 'git.rb'
require_relative 'helpers.rb'

HIGHLIGHT="\033[31m"
HIGHLIGHT_OFF="\033[0m"
command=ARGV.first

case command
when 'start'
   require_feature_name(:start)
   feature = ARGV[1]

   exit if !confirm("Create feaure branch named: '#{feature}' ?")

   Git::run_safe("git branch \"#{feature}\" master")
   Git::run_safe("git checkout \"#{feature}\"")

   puts "Successfully created a new feature-branch: #{feature}"

when 'finish'
   if Git::has_uncommitted_changes
      die "Cannot finish and merge a feature branch with a dirty working tree, please stash your changes with 'git stash save'."
   end

   require_feature_name(:finish)
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
   Git::run_safe("git push origin")

   puts "Successfully merged feature-branch: #{feature} into master"

when 'switch'
   require_feature_name(:switch)
   feature = ARGV[1]

   Git::run_safe("git checkout \"#{feature}\"")
   Git::show_stashes_saved_on(feature)


when 'list'
   puts "\nCurrent Branch:"
   puts "--" * 30
   current = Git::current_branch
   print HIGHLIGHT
   if current
      print Git::branch_info(current)
   else
      print "(not on any branch!)"
   end
   puts HIGHLIGHT_OFF

   puts "\nAvailable feature branches:"
   puts "--" * 30
   branches = Git::unmerged_branches
   if branches && !branches.empty?
      branches.each do |branch|
         puts Git::branch_info(branch)
      end
   else
      puts "(none)"
   end

else
   display_help
end

