#!/usr/bin/env ruby
require_relative 'git.rb'
require_relative 'helpers.rb'

command=ARGV.first
BRANCH_PREFIX = "hotfix-"
case command
when 'start'
   require_argument(:hotfix, :start)
   hotfix = BRANCH_PREFIX + ARGV[1]

   exit if !confirm("Create hotfix branch named: '#{hotfix}' ?")

   Git::run_safe("git checkout stable")
   Git::run_safe("git pull --rebase")
   Git::run_safe("git branch \"#{hotfix}\" stable")
   Git::run_safe("git checkout \"#{hotfix}\"")

when 'switch'
   require_argument(:hotfix, :switch)
   hotfix = BRANCH_PREFIX + ARGV[1]

   Git::run_safe("git checkout \"#{hotfix}\"")
   Git::show_stashes_saved_on(hotfix)

when 'finish'
   hotfix = ARGV[1] || Git::current_branch

   exit 1 if !confirm("Create a pull-request for hotfix branch named: '#{hotfix}' ?")
   description = Github::get_pull_request_description
   octokit = Github::api
   response = octokit.create_pull_request(
      Github::get_github_repo,
      'stable',
      hotfix,
      description[:title],
      description[:body]
   )

   puts "Successfully created pull-request ##{response[:number]}"
   puts "   " + response[:html_url]

when 'merge'
   require_argument(:hotfix, :finish)
   fail_on_local_changes

   hotfix = BRANCH_PREFIX + ARGV[1]

   exit 1 if !confirm("Merge hotfix named: '#{hotfix}' ?")

   # Merge into stable
   Git::run_safe("git checkout stable")
   # pull the latest changes and rebase the unpushed commits if any.
   Git::run_safe("git pull --rebase")
   # merge the hotfix branch into stable
   Git::run_safe("git merge --no-ff \"#{hotfix}\"")
   # push the the merge to our origin
   # Git::run_safe("git push origin")

   # Merge into master
   Git::run_safe("git checkout master")
   # pull the latest changes and rebase the unpushed master commits if any.
   Git::run_safe("git pull --rebase")
   # merge the hotfix branch into master
   Git::run_safe("git merge --no-ff \"#{hotfix}\"")
   # push the the merge to our origin
   # Git::run_safe("git push origin")

   # delete the local hotfix branch
   Git::run_safe("git branch -d \"#{hotfix}\"")
   # delete the remote hotfix branch -- we'll leave this off for now
   # Git::run_safe("git push origin :\"#{hotfix}\"")

   # checkout stable branch
   Git::run_safe("git checkout stable")

   puts "Successfully merged hotfix branch: #{hotfix} into stable and master"
   puts "If you are satisfied with the result, do this:\n" + <<CMDS
      git push
      git checkout master
      git push
CMDS

when 'list'
   options = {
      :hotfix => Git::hotfix_branches(:unmerged)
   }
   if ARGV.include?('-v')
      options[:merged] = Git::hotfix_branches(:merged)
   end
   Git.show_branch_list(options)
else
   display_hotfix_help
end
