# -*- encoding: utf-8 -*-
# Reference: http://docs.rubygems.org/read/chapter/20

Gem::Specification.new do |s|
   s.name = 'git-scripts'
   s.version = '0.7.0'
   s.date = Time.now.strftime('%Y-%m-%d')

   s.authors = ['Daniel Beardsley',
                'James Pearson',
                'Tim Asp',
                'Kim Arre',
                'Chris Opperwall',
                'Robin Choudhury']
   s.email = ['daniel@ifixit.com',
              'james@ifixit.com',
              'tim@ifixit.com',
              'kim@ifixit.com',
              'copperwall@gmail.com',
              'robin@ifixit.com']

   s.add_dependency 'bundler'
   s.add_dependency 'octokit', '~> 4.0.0'
   s.add_dependency 'highline'
   s.add_dependency 'json', '~> 1.8.0'

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
