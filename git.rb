module Git
   def self.has_uncommitted_changes()
      clean = system("git diff --quiet 2>/dev/null >&2")
      return !clean
   end

   def self.development_branch
      dev_branch = `git config feature.development-branch`.strip
      if !dev_branch || $? != 0
         $stderr.puts "No development branch specified"
         $stderr.puts "  set it with: git config feature.development-branch master"
         exit 1;
      end
      dev_branch
   end

   # Returns an array of branches that aren't merged into the specifeid branch
   def self.branches_not_merged_into(branch)
      self::all_branches - self::merged_branches(branch)
   end

   # Returns an array of unmerged hotfix branches
   def self.hotfix_branches(type)
      branches = if type == :unmerged
         self.branches_not_merged_into('stable')
      elsif type == :merged
         self.merged_branches('stable')
      end

      branches.select {|branch| branch.include?('hotfix-') }
   end

   # Returns an array of unmerged feature branches
   def self.feature_branches(type)
      branches = if type == :unmerged
         self.branches_not_merged_into('master')
      elsif type == :merged
         self.merged_branches('master')
      end

      branches.reject {|branch| branch.include?('hotfix-') }
   end

   # Returns an array of all branch names that have have been merged into the
   # specified branch
   def self.merged_branches(into_branch='master')
      `git branch --merged #{into_branch} -a`.
         split("\n").
         map {|branch| branch.gsub('*','').strip.sub('remotes/','')}
   end

   # Returns an array of all local branch names
   def self.all_branches()
      `git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads refs/remotes`.
      split("\n").
      map {|branch| branch.sub(/refs\/\w+\//, '') }.uniq
   end

   # returns the name of th currently checked out brnach, or nil if detached.
   def self.current_branch()
      ref = `git symbolic-ref -q HEAD`.strip
      ref.split('/').last
   end

   # returns the SHA1 hash that the specified branch or symbol points to
   def self.branch_hash(branch)
      `git rev-parse --verify --quiet "#{branch}" 2>/dev/null`.strip
   end

   # Return formatted string containing:
   #  commit_hash Authoe Name (relative date)
   # for the specifeid branch or commit
   def self.branch_info(branch)
      # branch info format: hash author (relative date)
      format = "%h %an %Cgreen(%ar)%Creset"
      branch_info = `git show -s --pretty="#{format}" #{branch}`.strip
      simple_branch = branch.sub('origin/', '')
      sprintf "%-30s %s", simple_branch, branch_info
   end

   def self.run_safe(command)
      puts "> #{command}"
      result = system(command)
      raise "Git command failed, aborting." if (!result)
   end

   def self.show_stashes_saved_on(branch = nil)
      self.stashes.each do |stash|
         if !branch || stash[:branch] == branch
            puts "=" * 40
            puts highlight(
               "There is a stash saved from #{branch} #{stash[:date]}")
            puts wrap_text(stash[:subject])
            puts "see it with >\n git stash show -p " + stash[:ref]
            puts "apply it with >\n git stash apply " + stash[:ref]
         end
      end
   end

   def self.show_branch_list(options = {})
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

      options.each do |branch_type, branches|
         puts "\nAvailable #{branch_type} branches:"
         puts "--" * 30
         if branches && !branches.empty?
            shown_branches = {}
            branches.each do |branch|
               simple_branch = branch.sub('origin/', '')
               next if shown_branches.has_key?(simple_branch)
               puts Git::branch_info(branch)
               shown_branches[simple_branch] = true
            end
         else
            puts "(none)"
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

   def self.switch_branch(branch)
      # capture only the path, not the newline
      basedir = `git rev-parse --show-toplevel`.split("\n").first

      # change directory to base dir
      Dir.chdir(basedir)

      self.run_safe("git checkout \"#{branch}\"")
      self.run_safe("git submodule --quiet update --init --recursive")
      self.run_safe("git clean -ffd") if ARGV.include?('--clean')

      self.show_stashes_saved_on(branch)
   end

   ##
   # Returns the commit message from the given commit hash or branch name
   #
   def self.commit_message(ref)
      `git log -1 --format="%B" #{ref}`.strip
   end
end
