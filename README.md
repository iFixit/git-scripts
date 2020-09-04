[![Gem Version](https://badge.fury.io/rb/git-scripts.png)](http://rubygems.org/gems/git-scripts)

# Git Scripts

User scripts for easily managing feature branches.

## Installation
```bash
gem install git-scripts
```

or

```bash
git clone git://github.com/iFixit/git-scripts.git
cd git-scripts
bundle install
ln -s ${PWD}/bin/feature /path/to/bin/dir/
```

## Branching Model

This is loosely based on the [Git Flow][gitflow] branching model, with a couple
of noteable changes. Essentially Git Flow's `develop` is our `master`, Git
Flow's `master` is our `stable`, there are no `release` branches nor hotfix
branches.

**master** is always deployed. It's also the branch that all feature branches
start from. This is configurable using: `git config feature.development-branch
branch-name` (`git config feature.development-branch master` in our case for
ifixit/ifixit).

**feature branches** are named after the feature you're developing and branched
from `master`. When finished, the feature branch is merged back into master
with `--no-ff` (so we preserve the merge commit) and deleted.

## feature script

    feature <command> [branch name]

Automates some of the git commands for dealing with feature branches. Any
command that is run with missing arguments will just print the help and exit.
Any command that modifies the working dir should warn the user and exit(1) if
the working tree is dirty; automatically managing the stash is frought with
danger.

    feature start my-awesome-thing

If the branch `my-awesome-thing` does not exist, a new feature branch
from `master` will be created after a confirmation, and runs a
`git checkout my-awesome-thing` to drop you on the new branch.

    feature switch your-neato-thing

Assuming the branch `your-neato-thing` exists, it checks out that branch and
informs you about any stashes saved on that branch.

    feature finish [your-neato-thing]

Creates a pull-request on Github for the current or specified feature branch.

    feature merge [your-neato-thing]

Merges the feature branch back in to `master`, using `--no-ff` to ensure it's a
non-fast-forward merge. This attempts to get a pull request description from
the github API.

    feature status

Shows a graphical commit log of the history between the current branch and the
remote version of the current branch (the upstream).

    feature stashes

Lists the stashes saved on the current branch if any. -v shows all stashes on
all branches.

[gitflow]: http://nvie.com/posts/a-successful-git-branching-model/

## Plugins

Any files matching `plugins/*.rb` will be loaded as plugins. The plugin
architecture is *very* simple. There are a few hooks scattered over the
code-base of the form: `Plugins.invoke :before_start, :feature`. If a plugin
has a method of the same name `before_start` it will be called, passing along
any arguments passed to `Plugins.invoke`.
