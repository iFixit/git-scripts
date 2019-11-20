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
         :switch  => "feature switch (name-of-feature | -n number-of-feature) [options]",
         :finish  => "feature finish [name-of-feature]",
         :'finish-issue'  => "feature finish-issue issue-number",
         :merge   => "feature merge (name-of-feature | -n number-of-feature)",
         :pull    => "feature pull",
         :prune   => "feature prune <local | origin> <preview | clean>",
         :status  => "feature status",
         :stashes => "feature stashes [-v]",
         :'github-test' => "feature github-test"
      },
      :command_name => 'feature',
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
      display_feature_help(command, msg)
   end

   if (ARGV.length > max)
      help.call "Too many arguments. This command accepts only #{max} arguments."
   end

   if (ARGV.length < min)
      help.call "Missing argument. This command requires exactly #{min} arguments."
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

def die(message = '')
   abort wrap_text(message)
end

def highlight(str)
   return HIGHLIGHT + str + HIGHLIGHT_OFF
end

def get_branch_name_from_number(num)
   octokit = Github::api

   return octokit.pull_request(Github::get_github_repo, num).head.ref
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

##
# If the commandline arguments contain '--pull', perform a feature pull
##
def optional_pull
   if ARGV.include?("--pull")
      puts %x(feature pull)
   end
end

def esc(str)
   str.shellescape
end
