module Git
   def self.has_uncommitted_changes()
      system("git diff --quiet 2>/dev/null >&2")
   end

   def self.unmerged_branches()
      merged = `git branch --merged master`.
         split("\n").
         map {|branch| branch.gsub('*','').strip}.

      all_branches =
         `git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads/`.
         split("\n").
         map {|branch| branch.split('/').last.strip }

      (all_branches - merged).reject {|branch| branch.start_with?('hot-fix-') }
   end

   def self.current_branch()
      ref = `git symbolic-ref -q HEAD`.strip
      ref.split('/').last
   end

   def self.branch_info(branch)
      format = "%h %an %Cgreen(%ar)%Creset"
      branch_info = `git show -s --pretty="#{format}" #{branch}`.strip
      sprintf "%-30s %s", branch, branch_info
   end
end
