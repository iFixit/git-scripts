# -*- encoding: utf-8 -*-
# Reference: http://docs.rubygems.org/read/chapter/20

Gem::Specification.new do |s|
   s.name = 'git-scripts'
   s.version = '0.5.1'
   s.date = Time.now.strftime('%Y-%m-%d')

   s.authors = ['Daniel Beardsley', 'James Pearson', 'Tim Asp', 'Robin Choudhury']
   s.email = ['daniel@ifixit.com', 'james@ifixit.com', 'tim@ifixit.com', 'robin@ifixit.com']

   s.add_dependency 'bundler'
   s.add_dependency 'octokit', '~> 3.0.0'

   # These aren't strictly necessary. They are dependencies of octokit but we
   # need to specify more precise versions of them because octokit didn't
   # properly specify the version. Ideally we would upgrade octokit which
   # would solve it but until we do that we need to specify these versions in
   # order for the gem to work out of the box.
   s.add_dependency 'json', '~> 1.8.0'
   s.add_dependency 'multi_json', '= 1.8.0'
   s.add_dependency 'highline', '= 1.6.19'
   s.add_dependency 'faraday'
   s.add_dependency 'faraday_middleware'

   s.files = %w( COPYING Rakefile README.md  )
   s.files += Dir.glob 'completion/*'
   s.files += Dir.glob 'bin/*'
   s.files += Dir.glob 'lib/*'
   s.files += Dir.glob 'man/*'

   s.executables = ['feature', 'hotfix']
   s.extra_rdoc_files = ['COPYING', 'README.md']

   s.summary = %q{User scripts for managing feature branches and hotfixes.}
   s.homepage = 'http://ifixit.github.com/git-scripts/'
   s.description = s.summary
end
