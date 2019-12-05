# -*- encoding: utf-8 -*-
# Reference: http://docs.rubygems.org/read/chapter/20

Gem::Specification.new do |s|
   s.name = 'git-scripts'
   s.version = '0.9.1'
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

   s.add_dependency 'bundler', '~> 1.17'
   s.add_dependency 'octokit', '~> 4.0'
   s.add_dependency 'json', '~> 1.8'

   s.files = %w( COPYING Rakefile README.md  )
   s.files += Dir.glob 'completion/*'
   s.files += Dir.glob 'bin/*'
   s.files += Dir.glob 'lib/*'
   s.files += Dir.glob 'man/*'

   s.executables = ['feature']
   s.extra_rdoc_files = ['COPYING', 'README.md']

   s.summary = %q{User scripts for managing and merging feature branches.}
   s.homepage = 'http://ifixit.github.com/git-scripts/'
   s.description = s.summary
end
