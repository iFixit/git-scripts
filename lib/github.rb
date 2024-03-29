require 'octokit'
require 'shellwords'
require 'readline'
require 'io/console'

module Github
   ##
   # Get a git config property from the first place that defines it. The `git
   # config` command takes properties, by default, from the repository, the
   # user's config, and the system config, in that order. We used to specify
   # `--global` here, but that means to read _only_ from the global config, and
   # it also prohibits processing includes by default.
   ##
   def self.config(property)
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
      # Let Octokit handle pagination automagically for us.
      Octokit.auto_paginate = true
      # Defaults
      authorization_info = {
         :scopes => ['repo'],
         :note => "ifixit git-scripts command line interface",
         :note_url => "https://github.com/ifixit/git-scripts"
      }.merge(authorization_info)
      OctokitWrapper.new(self::get_authentication(authorization_info))
   end

   def self.get_authentication(authorization_info)
      username = self::config("github.user")
      token    = self::config("github.token")
      if !username.empty? && !token.empty?
         return {:login => username, :access_token => token}
      else
         return self::request_authorization(authorization_info)
      end
   end

   ##
   # Returns a hash containing the username and github oauth token
   #
   # Prompts the user for credentials if the token isn't stored in git config
   ##
   def self.request_authorization(authorization_info)
      puts "Authorizing..."

      username ||= Readline.readline("github username: ", true)
      print "github password: "
      password = STDIN.noecho(&:gets).chomp
      puts # blank line

      octokit = OctokitWrapper.new(:login => username, :password => password)

      auth = octokit.authorizations.find {|auth|
         note = auth['note']
         note && note.include?(authorization_info[:note])
      }

      auth = auth || octokit.create_authorization(authorization_info)

      success =
         system("git config --global github.user #{username}") &&
         system("git config --global github.token #{auth[:token]}")

      unless success
         die("Couldn't set git config")
      end

      return {:login => username, :access_token => auth[:token]}
   end

   ##
   # Returns the github repo identifier in the form that the API likes:
   # "someuser/theirrepo"
   #
   # Requires the "origin" remote to be set to a github url
   ##
   def self.get_github_repo()
      url = self::config("remote.origin.url")
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
      if branch_name
         initial_message = Git::commit_message(branch_name).gsub("\r","")
      else
         initial_message = <<-MESSAGE
Title of pull-request
#  Second line is ignored (do no edit)
Body of pull-request
         MESSAGE
      end

      return self::open_title_body_editor(initial_message)
   end

   ##
   # Returns the most recent github commit status for a given commit
   ##
   def self.get_most_recent_commit_status(repo, sha)
      api.statuses(repo, sha).sort_by {|status| status['id'] }.last
   end

   ##
   # Prompts the user (using $EDITOR) to confirm the title and body
   # in the provided message.
   #
   # Returns a hash containing a :title and :body
   ##
   def self.open_title_body_editor(message)
      require 'tempfile'

      msg = Tempfile.new('pull-message')
      msg.write(message)
      msg.close

      Plugins.invoke :pre_message_edit, msg.path

      editor = Git::editor
      if (editor == 'vim')
         opts = "'+set ft=gitcommit' '+set textwidth=0'" +
          " '+setlocal spell spelllang=en_us'"
      else
         opts = ""
      end

      system("#{editor} #{opts} #{msg.path.shellescape}")
      full_message = File.open(msg.path, "r").read
      lines = full_message.split("\n")
      lines = lines.reject {|line| line =~ /^\s*#/ }
      title = lines.shift
      body  = lines.join("\n").strip

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

   # Returns a URL based off the branch name.
   def self.get_url(branch_name)
      pull = self.pull_for_branch(branch_name)
      return pull && pull[:html_url]
   end

   def self.get_pull_request_info_from_api(branch_name, into_branch)
      pull = self.pull_for_branch(branch_name)

      if pull
         # This will grab the latest commit and retrieve the state from it.
         sha = pull[:head][:sha]
         state = self.get_most_recent_commit_status(get_github_repo, sha)
         state = state ? state[:state] : 'none'

         desc = <<-MSG
Merge #{branch_name} (##{pull[:number]}) into #{into_branch}

#{pull[:title].gsub("\r", '')}

#{pull[:body].gsub("\r", '')}
      MSG

         return {:status => state, :description => desc}
      else
         return {:status => nil, :description => "Merge #{branch_name} into #{into_branch}"}
      end
   end

   @@pulls = nil
   def self.pulls
      if !@@pulls
         repo = get_github_repo
         @@pulls = api.pulls(repo)
      end
      return @@pulls 
   end

   def self.pull_for_branch(branch_name)
      pull = self.pulls.find {|pull| branch_name == pull[:head][:ref] }
   end

   def self.get_commit_status_warning(status)
      warning = 'Merge with caution.'
      case status
      when 'failure'
         return 'This pull request has failed to pass continuous integration' +
          " tests. #{warning}"
      when 'pending'
         return "Continuous integration tests have not finished. #{warning}"
      when 'error'
         return "Build tests were not able to complete. #{warning}"
      when 'none'
         return 'Continuous integration has not been set up.'
      when nil
         return 'No pull request found for this branch.'
      else
         return ''
      end
   end
end

class OctokitWrapper
   def initialize(*args)
      @client = Octokit::Client.new(*args)
   end

   def method_missing(meth,*args)
      begin
         return @client.send(meth,*args)
      rescue Octokit::Error => e
         die("=" * 80 + "\nGithub API Error\n" + e.to_s)
      end
   end
end
