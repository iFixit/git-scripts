require 'mg'
MG.new 'git-scripts.gemspec'

desc 'Build the manual'
task :man do
  require 'ronn'
  ENV['RONN_ORGANIZATION'] = 'iFixit'
  sh "ronn -w -s toc -r5 --markdown man/*.ronn"
end

desc 'Publish to github pages'
task :pages => :man do
  puts '----------------------------------------------'
  puts 'Rebuilding pages ...'
  verbose(false) {
    rm_rf 'pages'
    push_url = `git remote show origin`.each_line.grep(/Push.*URL/).first[/git@.*/]
    sh "
      set -ex
      git fetch -q origin
      rev=$(git rev-parse origin/gh-pages)
      git clone -q -b gh-pages . pages
      cd pages
      git reset --hard $rev
      rm -f *
      cp -rp ../man/*.html ../man/index.txt ./
      git add -A .
      git commit -m 'Rebuild manual.'
      git push #{push_url} gh-pages
      cd ..
      rm -rf pages
    ", :verbose => false
  }
end

