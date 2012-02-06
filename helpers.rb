HIGHLIGHT="\033[31m"
HIGHLIGHT_OFF="\033[0m"

def fail_on_local_changes
   if Git::has_uncommitted_changes
      exit
   end
end

def display_feature_help(command = nil, message = nil)
   commands = {
      :list    => "feature list",
      :start   => "feature start name-of-feature",
      :switch  => "feature switch name-of-feature",
      :finish  => "feature finish name-of-feature"
   }

   highlighted_commands = commands.map do |name, desc|
      help_line = "    #{name.to_s.ljust(8)} #{desc}"

      if name == command
         HIGHLIGHT + help_line + HIGHLIGHT_OFF
      else
         help_line
      end
   end

   if message
      puts '=' * 40
      puts HIGHLIGHT + message + HIGHLIGHT_OFF
      puts '=' * 40
   end

   puts <<HELP

Git Feature Branch Helper

usage:
#{highlighted_commands.join("\n")}

arguments:
   name-of-feature: letters, numbers, and dashes

Look at the source to discover what each of these commands does.

HELP
   exit
end

def require_feature_name(command = nil)
   if (ARGV.length > 2)
      display_help(command, "Too many arguments. This command accepts only one argument.")
   end

   if (ARGV.length < 2)
      display_help(command, "Missing arguemnt. This command requires 'name-of-feature'")
   end

   if (ARGV.last !~ /^[a-zA-z0-9-]+$/)
      display_help(command, "Invalid name-of-feature: '#{ARGV.last}'")
   end
end

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
   puts wrap_text(message)
   exit 1
end

def wrap_text(txt, col = 80)
   txt.gsub(
    /(.{1,#{col}})(?: +|$)\n?|(.{#{col}})/,
    "\\1\\3\n")
end
