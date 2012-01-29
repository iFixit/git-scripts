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

when 'list'
   puts "\nCurrent Branch:"
   puts "--" * 30
   current = Git::current_branch
   if current
      puts HIGHLIGHT +  Git::branch_info(current)
   else
      puts HIGHLIGHT + "(not on any branch!)" + HIGHLIGHT_OFF
   end

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

