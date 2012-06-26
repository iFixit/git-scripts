require "rubygems"
require "bundler/setup"
require 'octokit'
require 'readline'
require 'shellwords'

module Github
   ##
   # Get a global git config property
   ##
   def self.config(property)
      `git config --global #{property.to_s.shellescape}`.strip
   end

   ##
   # Get a local (to the repo) git config property
   ##
   def self.local_config(property)
      `git config #{property.to_s.shellescape}`.strip
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
      username = self::config("github.user")
      token    = self::config("github.token")
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

      return {:login => username, :oauth_token => auth[:token]}
   end

   ##
   # Returns the github repo identifier in the form that the API likes:
   # "someuser/theirrepo"
   #
   # Requires the "origin" remote to be set to a github url
   ##
   def self.get_github_repo()
      url = self::local_config("remote.origin.url")
      m = /github\.com.(.*?)\/(.*)/.match(url)
      if m
        return [m[1], m[2].sub(/\.git\Z/, "")].join("/")
      else
         raise "remote.origin.url in git config but be a github url"
      end
   end

   ##
   # Prompts the user (using $EDITOR) to provide a title and body
   # for this pull-request
   #
   # Returns a hash containing a :title and :body
   ##
   def self.get_pull_request_description(branch_name = nil)
      require 'tempfile'

      if branch_name
         initial_message = Git::commit_message(branch_name)
      else
         initial_message = <<-MESSAGE
Title of pull-request
#  Second line is ignored (do no edit)
Body of pull-request
         MESSAGE
      end

      msg = Tempfile.new('pull-message')
      msg.write(initial_message)
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
