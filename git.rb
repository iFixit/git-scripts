module Git
   def self.has_uncommitted_changes()
      system("git diff --quiet 2>/dev/null >&2")
   end

   def self.unmerged_branches()
      `git branch --no-merged master`.
         split("\n").
         map {|branch| branch.gsub('*','').strip}.
         reject {|branch| branch =~ /^  hot-fix-/ }
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
