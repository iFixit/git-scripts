#!/usr/bin/env ruby
require_relative 'git.rb'
require_relative 'helpers.rb'

command=ARGV.first
BRANCH_PREFIX = "hotfix-"
case command
when 'start'
   require_feature_name(:start)
   hotfix = BRANCH_PREFIX + ARGV[1]

   exit if !confirm("Create hotfix branch named: '#{hotfix}' ?")

   Git::run_safe("git branch \"#{hotfix}\" stable")
   Git::run_safe("git checkout \"#{hotfix}\"")

when 'switch'
   require_feature_name(:start)
   hotfix = BRANCH_PREFIX + ARGV[1]

   Git::run_safe("git checkout \"#{hotfix}\"")
   Git::show_stashes_saved_on(hotfix)

when 'finish'
   fail_on_local_changes

   require_feature_name(:finish)
   hotfix = BRANCH_PREFIX + ARGV[1]

   exit 1 if !confirm("Finish hotfix named: '#{hotfix}' ?")

   # Merge into stable
   Git::run_safe("git checkout stable")
   # pull the latest changes and rebase the unpushed commits if any.
   Git::run_safe("git pull --rebase")
   # merge the hotfix branch into stable
   Git::run_safe("git merge --no-ff \"#{hotfix}\"")
   # push the the merge to our origin
   Git::run_safe("git push origin")

   # Merge into master
   Git::run_safe("git checkout master")
   # pull the latest changes and rebase the unpushed master commits if any.
   Git::run_safe("git pull --rebase")
   # merge the hotfix branch into master
   Git::run_safe("git merge --no-ff \"#{hotfix}\"")
   # push the the merge to our origin
   Git::run_safe("git push origin")

   # delete the local hotfix branch
   Git::run_safe("git branch -d \"#{hotfix}\"")
   # delete the remote hotfix branch -- we'll leave this off for now
   # Git::run_safe("git push origin :\"#{hotfix}\"")

   puts "Successfully merged hotfix branch: #{hotfix} into stable and master"

when 'list'
   Git.show_branch_list(:hotfix, Git::hotfix_branches)
end
