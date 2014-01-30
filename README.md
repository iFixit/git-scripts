[![Gem Version](https://badge.fury.io/rb/git-scripts.png)](http://rubygems.org/gems/git-scripts)

# Git Scripts

User scripts for easily managing feature branches and hotfixes.

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
ln -s ${PWD}/bin/hotfix /path/to/bin/dir/
```

## Branching Model

This is loosely based on the [Git Flow][gitflow] branching model, with a couple
of noteable changes. Essentially Git Flow's `develop` is our `master`, Git
Flow's `master` is our `stable`, and there are no `release` branches and our
`hotfix` branch names all have a prefix.

**master** is the active development branch, and what our development server
has checked out. This is configurable using: `git config
feature.development_branch branch-name`

**stable** is the branch which is deployed on the production machines. You
should always be able to check out this branch and get "bug-free" production
code.  This branch is always ready-to-go and should always be deployed as soon
as it's changed

**feature branches** are named after the feature you're developing and branched
from `master`. When finished, the feature branch is merged back into master
with `--no-ff` (so we preserve the merge commit) and deleted.

**hotfix branches** are named `hotfix-name` and branched from `stable`. When
finished, the hotfix branch is merged back into `stable` with `--no-ff` so we
preserve the merge commit. We attempt to merge it back into `master` as well,
but if it's going to get messy just bail.

## Deployment

The production machines always run off the `stable` branch. When deploying,
you need to:

* Merge `stable` into `master` (and vice-versa). This ensures that the two code
  paths come together relatively frequently. This also guarantees that we'll
  pick up any stray hotfixes that didn't get merged back.

* Create a tag on `stable` for keeping track of deploys

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

## hotfix script

    hotfix <command> [branch name]

Automates the process of fixing a bug on the live site, similar to the
`feature` script with a few differences. Any command that is run with missing
arguments will just print the help and exit

    hotfix start my-sweet-fix

Makes a new branch from `stable` named `hotfix_my-sweet-fix`. Prepending the
name with `hotfix_` allows easy filtering.

    hotfix switch my-other-fix

Switches hotfix branches. Assuming the branch `hotfix_my-other-fix` exists, it
checks out that branch and informs you about any stashes saved on that branch.

    hotfix finish [my-other-fix]

Creates a pull-request on Github for the current or specified hotfix branch.

    hotfix merge [my-other-fix]

Merges the hotfix branch back into `stable` with `--no-ff`. Also does a
merge back into `master`.

[gitflow]: http://nvie.com/posts/a-successful-git-branching-model/

## Plugins

Any files matching `plugins/*.rb` will be loaded as plugins. The plugin
architecture is *very* simple. There are a few hooks scattered over the
code-base of the form: `Plugins.invoke :before_start, :feature`. If a plugin
has a method of the same name `before_start` it will be called, passing along
any arguments passed to `Plugins.invoke`.
