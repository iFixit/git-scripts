# Contributing

We (obviously) use the same method on this repo as the tools contained within
encourage.  Unfortunately, `feature finish` will create a pull request within
your own forked repo.  Thus, if you do not have write privileges to this
repository, you have to create the pull request manually - bummer.

Please include any necessary changes to the documentation.  The man files are
written in [ronn], so the only manual change you need make are to the
man/*.ronn files.  After you've done that, run `rake man` to generate the HTML
and roff files.

[ronn]: http://rtomayko.github.io/ronn/ronn-format.7.html

