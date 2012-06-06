require 'rubygems'
require 'octokit'
require 'readline'

module Github
   ##
   # Get a global git config property
   ##
   def self.config(property)
      `git config --global github.#{property}`.strip
   end

   ##
   # Get an instance of the Octokit API class
   #
   # Authorization info is the structure from here:
   # http://developer.github.com/v3/oauth/#create-a-new-authorization
   #
   # like this:
   # {
   #     :scopes => ['repo'],
   #     :note => "ifixit git-scripts command line interface",
   #     :note_url => "https://github.com/ifixit/git-scripts"
   # }
   ##
   def self.api(authorization_info)
      Octokit::Client.new(self::get_authentication(authorization_info))
   end

   def self.get_authentication(authorization_info)
      username = self::config(:user)
      token    = self::config(:token)
      if !username.empty? && !token.empty?
         return {:login => username, :oauth_token => token}
      else
         return self::request_authorization(authorization_info)
      end
   end

   ##
   # Returns a hash containing username and github oauth token
   #
   # Prompts the user for credentials if the token isn't stored in git config
   ##
   def self.request_authorization(authorization_info)
      puts "Authorizing..."

      username ||= Readline.readline("github username: ", true)
      password   = Readline.readline("github password: ", false)

      octokit = Octokit::Client.new(:login => username, :password => password)

      auth = octokit.authorizations.find {|auth|
         note = auth['note']
         note && note.include?(authorization_info[:note])
      }

      auth = auth || octokit.create_authorization(authorization_info)

      success = 
         system("git config --global github.user #{username}") &&
         system("git config --global github.token #{auth[:token]}")

      if !success
         puts "Couldn't set git config"
         exit
      end
   end

   def self.get_pull_request_description()
      require 'tempfile'
      msg = Tempfile.new('pull-message')
            # => A unique filename in the OS's temp directory,
                     #    e.g.: "/tmp/foo.24722.0"
                     #    This filename contains 'foo' in its basename.
      msg.write(<<-MESSAGE)
Title of pull-request
#  Second line is ignored (do no edit)
Body of pull-request
      MESSAGE
      msg.close

      system("$EDITOR -c \":set filetype=gitcommit\" #{msg.path}")
      full_message = File.open(msg.path, "r").read
      lines = full_message.split("\n")
      lines = lines.select {|line| !(line =~ /^\s*#/) }
      title = lines[0]
      body  = lines[1..-1].join("\n")

      if title.empty? || body.empty?
         puts "You must provide a title and a body:\n"
         puts title
         puts
         puts body
         exit 1
      end

      return {
         :title => title,
         :body => body
      }
   end
end
