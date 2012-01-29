
def fail_on_local_changes
   if Git::has_uncommitted_changes
      exit
   end
end

def display_help(command = nil, message = nil)
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

options:
   name-of-feature: letters,numbers,underscores,and dashes

Look at the source to discover what each of these commands does.

HELP
   exit
end

def require_feature_name(command = nil)
   if (ARGV.length != 2 || ARGV.last !~ /^[\w-]+$/)
      display_help(command, "Missing or invalid feature name")
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
