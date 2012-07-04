HIGHLIGHT="\033[31m"
HIGHLIGHT_OFF="\033[0m"

def fail_on_local_changes
   if Git::has_uncommitted_changes
      die "Cannot perform this action with a dirty working tree, " +
          "please stash your changes with 'git stash save \"Some message\"'."
   end
end

def display_feature_help(command = nil, message = nil)
   display_help(
      :script_name => "Git Feature Branch Helper",
      :commands => {
         :list    => "feature list",
         :start   => "feature start name-of-feature",
         :switch  => "feature switch name-of-feature",
         :finish  => "feature finish name-of-feature",
         :finish  => "feature pull",
         :status  => "feature status",
         :stashes => "feature stashes [-v]",
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
         :list    => "hotfix list",
         :start   => "hotfix start name-of-hotfix",
         :switch  => "hotfix switch name-of-hotfix",
         :finish  => "hotfix finish name-of-hotfix"
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


# prints out an error and the approprite help if there is not exactly one
# commandline argument
def require_argument(program, command = nil)
   help = lambda do |msg|
      if program == :hotfix
         display_hotfix_help(command, msg)
      else
         display_feature_help(command, msg)
      end
   end

   if (ARGV.length > 2)
      help.call "Too many arguments. This command accepts only one argument."
   end

   if (ARGV.length < 2)
      help.call "Missing argument. This command requires exactly one argument."
   end

   if (ARGV.last !~ /^[a-zA-z0-9-]+$/)
      help.call "Invalid branch name: '#{ARGV.last}'"
   end
end

##
# Repeatedly prints out a y/n question until a y or n is input
def confirm(question)
   loop do
      print(question)
      print(" (y/n):")
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
   return HIGHLIGHT + str + HIGHLIGHT_OFF;
end

def wrap_text(txt, col = 80)
   txt.gsub(
    /(.{1,#{col}})(?: +|$)\n?|(.{#{col}})/,
    "\\1\\3\n")
end
