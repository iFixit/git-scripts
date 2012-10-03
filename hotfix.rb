#!/usr/bin/env ruby
require_relative 'github.rb'
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

   # ensure the hotfix name is the real branch name
   if (!hotfix.start_with?("hotfix-"))
       hotfix = "hotfix-" + hotfix
   end

   # Push commits to origin
   Git::run_safe("git push")

   exit 1 if !confirm("Create a pull-request for hotfix branch named: '#{hotfix}' ?")
   octokit = Github::api

   description = Github::get_pull_request_description(hotfix)
   puts "Pull-request description:"
   puts description[:title]
   puts "#"
   puts description[:body]

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
   fail_on_local_changes
   dev_branch = Git::development_branch

   Git::run_safe("git fetch")

   if ARGV[1]
      hotfix = BRANCH_PREFIX + ARGV[1]
      # Checkout the branch to make sure we have it locally.
      Git::run_safe("git checkout \"#{hotfix}\"")
   else
      hotfix = Git::current_branch
   end

   exit 1 if !confirm("Merge hotfix named: '#{hotfix}' ?")

   description = Github::get_pull_request_description_from_api(hotfix, 'stable')

   # Merge into stable
   Git::run_safe("git checkout stable")
   # pull the latest changes and rebase the unpushed commits if any.
   Git::run_safe("git rebase --preserve-merges origin/stable")
   # merge the hotfix branch into stable
   Git::run_safe("git merge --no-ff --edit -m #{description.shellescape} \"#{hotfix}\"")
   # push the the merge to our origin
   # Git::run_safe("git push origin")

   description = Github::get_pull_request_description_from_api(hotfix, dev_branch)

   # Merge into master
   Git::run_safe("git checkout #{dev_branch}")
   # pull the latest changes and rebase the unpushed master commits if any.
   Git::run_safe("git rebase origin/#{dev_branch}")
   # merge the hotfix branch into master
   Git::run_safe("git merge --no-ff --edit -m #{description.shellescape} \"#{hotfix}\"")
   # push the the merge to our origin
   # Git::run_safe("git push origin")

   # delete the local hotfix branch
   Git::run_safe("git branch -d \"#{hotfix}\"")
   # delete the remote hotfix branch -- we'll leave this off for now
   # Git::run_safe("git push origin :\"#{hotfix}\"")

   # checkout stable branch
   Git::run_safe("git checkout stable")

   puts "Successfully merged hotfix branch: #{hotfix} into stable and #{dev_branch}"
   puts "If you are satisfied with the result, do this:\n" + <<CMDS
      git push
      git checkout #{dev_branch}
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
