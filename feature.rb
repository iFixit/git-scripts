#!/usr/bin/env ruby
require_relative 'git.rb'
HIGHLIGHT="\033[31m"
command=ARGV.first
case command
when 'list'
   puts "\nCurrent Branch:"
   puts "--" * 30
   current = Git::current_branch
   if current
      puts HIGHLIGHT +  Git::branch_info(current)
   else
      puts HIGHLIGHT + "(not on any branch!)\033[0m"
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
      puts <<HELP
Invalid command '#{command}'

================================
Git Feature Branch Helper

usage:
   feature list
   feature start name-of-feature
   feature switch name-of-feature
   feature finish name-of-feature

Look at the source to discover what each of these commands does.
HELP
end
