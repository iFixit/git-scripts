module Git
   def self.has_uncommitted_changes()
      clean = system("git diff --quiet 2>/dev/null >&2")
      return !clean
   end

   def self.in_a_repo
      return system("git rev-parse")
   end

   # Return the specified branch in the feature git config section.
   def self.get_branch(branch = '')
      specified_branch = `git config feature.#{branch.shellescape}-branch`.strip
      if specified_branch.empty? || $? != 0
         die("No #{branch} branch specified; set it with:\n" +
          "git config feature.#{branch}-branch \"name-of-branch\"")
      end
      return specified_branch
   end

   # Returns the editor specified in the user's gitconfig.
   def self.editor
      editor = `git var GIT_EDITOR`.strip
      unless editor
         abort "Configure an editor for git:\n" +
               "git config --global core.editor vim"
      end
      return editor
   end

   # Starts an editor with a file. Returns a string with the contents of that
   # file.
   def self.get_description_from_user(initial_message = '')
      require 'tempfile'
      editor = self::editor

      file = Tempfile.new('merge-msg')
      file.print(initial_message)
      file.flush

      if editor == 'vim'
         params = "'+set ft=gitcommit' '+set textwidth=72'" +
          " '+setlocal spell spelllang=en_us'"
      else
         params = ''
      end
      pid = spawn("#{editor} #{params} #{file.path}")
      Process.wait pid

      file.rewind
      commit = file.read
      file.unlink

      return commit
   end

   # Returns an array of branches that aren't merged into the specified branch
   def self.branches_not_merged_into(branch)
      self::all_branches - self::merged_branches(branch)
   end

   # Returns an array of unmerged hotfix branches
   def self.hotfix_branches(type)
      stable_branch = get_branch('stable')
      branches = if type == :unmerged
         self.branches_not_merged_into(stable_branch)
      elsif type == :merged
         self.merged_branches(stable_branch)
      else
         raise ArgumentError, 'Must specify :merged or :unmerged in hotfix_branches.'
      end

      branches.select {|branch| branch.include?('hotfix-') }
   end

   # Returns an array of unmerged feature branches
   def self.feature_branches(type)
      devBranch = get_branch('development')

      branches = if type == :unmerged
         self.branches_not_merged_into(devBranch)
      elsif type == :merged
         self.merged_branches(devBranch)
      else
         raise ArgumentError, 'Must specify :merged or :unmerged in feature_branches.'
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
      map {|branch| branch.sub(/refs\/\w+\//, '') }.
      uniq.
      reject {|branch| branch =~ %r{\w+/HEAD} }
   end

   # Returns the name of the currently checked out branch, or nil if detached.
   def self.current_branch()
      ref = `git symbolic-ref -q HEAD`.strip
      ref.split('/').last
   end

   # Deletes the current branch. For cleaning up after errors.
   def self.delete_current_branch()
      branchName = Git::current_branch
      Git::switch_branch('master')
      `git branch -d #{branchName}`.strip
   end

   # Returns the SHA1 hash that the specified branch or symbol points to
   def self.branch_hash(branch)
      `git rev-parse --verify --quiet "#{branch}" 2>/dev/null`.strip
   end

   # Returns formatted string containing:
   #
   #    commit_hash Author Name (relative date)
   #
   # for the specified branch or commit
   def self.branch_info(branch)
      # branch info format: hash author (relative date)
      format = "%h %an %Cgreen(%ar)%Creset"
      branch_info = `git show -s --pretty="#{format}" #{branch}`.strip
      simple_branch = branch.sub('origin/', '')
      sprintf "%-30s %s", simple_branch, branch_info
   end

   def self.run_safe(commands)
      while command = commands.shift
         safe_command = command.gsub(/[^[:print:]]+/,' ')
         puts "> " + safe_command
         unless system(command)
            puts highlight("\nERROR: failed on #{safe_command}`.")
            puts "\nWould have run:"
            commands.each do |command|
               puts "# " + command.gsub(/[^[:print:]]+/,' ')
            end
            abort
         end
      end
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
      # Do we even have a stash?
      unless File.exist? '.git/refs/stash'
         return []
      end

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

   ##
   # Switch to the specified branch.
   # Because we use submodules, we have to check for updates to those
   # submodules when we checkout a branch.
   #
   # args: --clean - remove every unstaged file, including non-existant
   # submodules
   #
   def self.switch_branch(branch)
      self.run_safe(["git checkout \"#{branch}\""])
      self.submodules_update
      self.run_safe(["git clean -ffd"]) if ARGV.include?('--clean')

      self.show_stashes_saved_on(branch)
   end

   ##
   # Update / initialize submodules from the TLD or return the command that
   # would do so as a string.
   #
   def self.submodules_update(mode = "")
      # capture only the path, not the newline
      basedir = `git rev-parse --show-toplevel`.split("\n").first
      command = "cd #{basedir} && git submodule --quiet update --init --recursive"

      if mode == "get"
         return command
      else
         Git::run_safe([command])
      end
   end

   ##
   # Returns the commit message from the given commit hash or branch name
   #
   def self.commit_message(ref)
      `git log -1 --format="%B" #{ref}`.strip
   end

   def self.git_dir()
      `git rev-parse --git-dir`.strip
   end
end
