module Git
   def self.has_uncommitted_changes()
      clean = system("git diff --quiet 2>/dev/null >&2")
      return !clean
   end

   # Returns an array of unmerged branches
   def self.unmerged_branches()
      (self::all_branches - self::merged_branches).
         reject {|branch| branch.start_with?('hot-fix-') }
   end

   # Returns an array of all branch names that have have been merged into the
   # specified branch
   def self.merged_branches(into_branch='master')
      `git branch --merged #{into_branch}`.
         split("\n").
         map {|branch| branch.gsub('*','').strip}
   end

   # Returns an array of all local branch names
   def self.all_branches()
      `git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads/`.
      split("\n").
      map {|branch| branch.split('/').last.strip }
   end

   # returns the name of th currently checked out brnach, or nil if detached.
   def self.current_branch()
      ref = `git symbolic-ref -q HEAD`.strip
      ref.split('/').last
   end

   # Return formatted string containing:
   #  commit_hash Authoe Name (relative date)
   # for the specifeid branch or commit
   def self.branch_info(branch)
      # branch info format: hash author (relative date)
      format = "%h %an %Cgreen(%ar)%Creset"
      branch_info = `git show -s --pretty="#{format}" #{branch}`.strip
      sprintf "%-30s %s", branch, branch_info
   end

   def self.run_safe(command)
      puts "> #{command}"
      result = system(command)
      raise "Command failed, aborting" if (!result)
   end

   def self.show_stashes_saved_on(branch)
      self.stashes.each do |stash|
         if stash[:branch] == branch
            puts "=" * 40
            puts HIGHLIGHT + "There is a stash saved " + stash[:date] + HIGHLIGHT_OFF
            puts "see it with >\n git stash show -p " + stash[:ref]
            puts "apply it with >\n git stash apply " + stash[:ref]
         end
      end
   end

   def self.stashes
      # format = "relative date|stash ref|commit message"
      `git log --format="%ar|%gd|%s" -g "refs/stash"`.lines.map do |line|
         fields = line.split '|', 3
         # All stashes have commit messages like "WIP on branch_name: ..."
         branch = line[/\S+:/]
         {
            :date => fields[0],
            :ref => fields[1],
            :branch => branch && branch.chop,
            :subject =>fields[2]
         }
      end
   end
end
