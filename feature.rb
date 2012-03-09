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


when 'list'
   options = {
      :feature => Git::feature_branches(:unmerged)
   }
   if ARGV.include?('-v')
      options[:merged] = Git::feature_branches(:merged)
   end
   Git.show_branch_list(options)

when 'stashes'
   current = Git::current_branch
   Git::show_stashes_saved_on(current)

else
   display_feature_help
end

