require 'rubygems'
require 'octokit'
require 'readline'
require 'shellwords'

module Github
   ##
   # Get a global git config property
   ##
   def self.config(property)
      `git config --global github.#{property.to_s.shellescape}`.strip
   end

   ##
   # Get a local (to the repo) git config property
   ##
   def self.local_config(property)
      `git config github.#{property.to_s.shellescape}`.strip
   end

   ##
   # Get an instance of the Octokit API class
   #
   # Authorization info is the structure from here:
   # http://developer.github.com/v3/oauth/#create-a-new-authorization
   #
   # something like this:
   # {
   #     :scopes => ['repo'],
   #     :note => "git-scripts command line interface",
   #     :note_url => "https://github.com/ifixit/git-scripts"
   # }
   ##
   def self.api(authorization_info = {})
      # Defaults
      authorization_info = {
         :scopes => ['repo'],
         :note => "ifixit git-scripts command line interface",
         :note_url => "https://github.com/ifixit/git-scripts"
      }.merge(authorization_info)
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

   ##
   # Returns the github repo identifier in the form that the API likes:
   # "someuser/theirrepo"
   #
   # Prompts the user for this value if it isn't in git config
   ##
   def self.get_github_repo()
      while ((repo = self::local_config("repo")).to_s.empty?) do
         repo = Readline.readline("Provide a github repo: (like: someuser/repo_name): ", true)
         if (repo =~ /\w+\/\w+/)
            system("git config github.repo #{repo.shellescape}")
         else
            puts "Repo must be in the format: someuser/repo_name"
         end
      end
      repo
   end

   ##
   # Prompts the user (using $EDITOR) to provide a title and body
   # for this pull-request
   #
   # Returns a hash containing a :title and :body
   ##
   def self.get_pull_request_description()
      require 'tempfile'
      msg = Tempfile.new('pull-message')
      msg.write(<<-MESSAGE)
Title of pull-request
#  Second line is ignored (do no edit)
Body of pull-request
      MESSAGE
      msg.close

      system("$EDITOR -c \":set filetype=gitcommit\" #{msg.path.shellescape}")
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
