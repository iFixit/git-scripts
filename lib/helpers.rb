HIGHLIGHT="\033[31m"
HIGHLIGHT_OFF="\033[0m"

def fail_on_local_changes
   if Git::has_uncommitted_changes
      die "Cannot perform this action with a dirty working tree; " +
          "please stash your changes with 'git stash save \"Some message\"'."
   end
end

def display_feature_help(command = nil, message = nil)
   display_help(
      :script_name => "Git Feature Branch Helper",
      :commands => {
         :list    => "feature list [-v]",
         :url     => "feature url [name-of-feature]",
         :start   => "feature start name-of-feature",
         :switch  => "feature switch (name-of-feature | -n number-of-feature) [--clean]",
         :finish  => "feature finish [name-of-feature]",
         :merge   => "feature merge [name-of-feature]",
         :pull    => "feature pull",
         :prune   => "feature prune <local | origin> <preview | clean>",
         :status  => "feature status",
         :stashes => "feature stashes [-v]",
         :clean   => "feature clean [--all]",
         :'github-test' => "feature github-test"
      },
      :command_name => 'feature',
      :command => command,
      :message => message
   )
end

def display_hotfix_help(command = nil, message = nil)
   display_help(
      :script_name => "Git Hotfix Helper",
      :commands => {
         :list    => "hotfix list [-v]",
         :url     => "hotfix url [name-of-hotfix]",
         :start   => "hotfix start name-of-hotfix",
         :switch  => "hotfix switch (name-of-hotfix | -n number-of-hotfix)",
         :finish  => "hotfix finish [name-of-hotfix]",
         :merge   => "hotfix merge [name-of-hotfix]"
      },
      :command_name => 'hotfix',
      :command => command,
      :message => message
   )
end

def display_help(args)
   command = args[:command]
   message = args[:message]
   script_name = args[:script_name]

   highlighted_commands = args[:commands].map do |name, desc|
      help_line = "    #{name.to_s.ljust(8)} #{desc}"

      if name == command
         HIGHLIGHT + help_line + HIGHLIGHT_OFF
      else
         help_line
      end
   end

   if message
      puts HIGHLIGHT + "Error: " + HIGHLIGHT_OFF + message
      puts
      puts
   end

   die <<HELP
#{script_name}

usage:
#{highlighted_commands.join("\n")}

arguments:
   name-of-#{args[:command_name]}: letters, numbers, and dashes

Look at the source to discover what each of these commands does.

HELP
end

##
# Prints out an error and the appropriate help if there is not exactly one
# command-line argument
##
def require_argument(program, command = nil, min = 2, max = 2)
   help = lambda do |msg|
      if program == :hotfix
         display_hotfix_help(command, msg)
      else
         display_feature_help(command, msg)
      end
   end

   if (ARGV.length > max)
      help.call "Too many arguments. This command accepts only #{max} arguments."
   end

   if (ARGV.length < min)
      help.call "Missing argument. This command requires exactly #{min} arguments."
   end

   if (ARGV.last !~ /^[a-zA-z0-9-]+$/)
      help.call "Invalid branch name: '#{ARGV.last}'"
   end
end

##
# Repeatedly prints out a y/n question until a y or n is input
##
def confirm(question)
   loop do
      print(question)
      print(" (y/n): ")
      STDOUT.flush
      s = STDIN.gets
      exit if s == nil
      s.chomp!

      return true if s == 'y'
      return false if s == 'n'
   end
end

def die(message = nil)
   puts wrap_text(message) if message
   exit 1
end

def highlight(str)
   return HIGHLIGHT + str + HIGHLIGHT_OFF
end

def get_branch_name_from_number(num)
   octokit = Github::api

   return octokit.pull_request(Github::get_github_repo, num).head.ref
end

def hotfix_branch(name)
   if is_hotfix_branch(name)
     return name
   else
     return "hotfix-#{name}"
   end
end

def current_hotfix_branch()
   if ARGV[1] == '-n'
      branch = get_branch_name_from_number(ARGV[2])
   elsif ARGV[1]
      branch = hotfix_branch(ARGV[1])
   else
      branch = Git::current_branch
   end

   unless is_hotfix_branch(branch)
      puts "#{branch} is not a hotfix branch"
      exit 1
   end
   return branch
end

def is_hotfix_branch(name)
   name =~ /^hotfix-/
end

def wrap_text(txt, col = 80)
   txt.gsub(
    /(.{1,#{col}})(?: +|$)\n?|(.{#{col}})/,
    "\\1\\3\n")
end

##
# Write the given string to the git-dir specific git-scripts command-log
##
def log_command(command)
   require 'time'
   filename = File.join(Git.git_dir, "git-scripts.log")
   log = File.open(filename, "a")
   log.puts "#{Time.now.iso8601}: #{command}"
   log.close
end
