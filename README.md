# Git Scripts

User scripts for easily managing feature branches and hotfixes.

## Branching Model

This is loosely based on the [Git Flow][gitflow] branching model, with a couple
of noteable changes. Essentially Git Flow's `develop` is our `master`, Git
Flow's `master` is our `stable`, and there are no `release` branches and our
`hotfix` branch names all have a prefix.

**master** is the active development branch, and what cominor.com has checked
out.

**stable** is the branch which is deployed on the production machines. You
should always be able to check out this branch and get "bug-free" code.  This
branch is always ready-to-go and should always be deployed as soon as it's
changed

**feature branches** are named after the feature you're developing and branched
from `master`. When finished, the feature branch is merged back into master
with `--no-ff` so we preserve the merge commit.

**hotfix branches** are named `hotfix_name` and branched from `stable`. When
finished, the hotfix branch is merged back into `stable` with `--no-ff` so we
preserve the merge commit. We attempt to merge it back into `master` as well,
but if it's going to get messy just bail.

## Deployment

The production machines always run off the `stable` branch. When we sync,
the sync scripts should:

* Merge `stable` into `master`. This ensures that the two code paths come
together relatively frequently. This also guarantees that we'll pick up any
stray hotfixes that didn't get merged back.

* Create a tag on `stable`. Use the sync number? Date? Both?

* Update everything on the production machines.

* Create a new directory for the release tag and copy code into it.

* Some kind of Apache/haproxy flag that allows us to change the doc root for
the office IP? Essentially the world would see the old code while we see the
new code. How would this work with migrations?

* When we're ready to flip the switch to the new code, swap the symlink to the
new tag directory. The doc root of the site should be the symlink for this to
work properly.

## feature script

    feature <command> [branch name]

Automates some of the git commands for dealing with feature branches.

    feature help

Shows how to use the script.

    feature start my-awesome-thing

If the branch `my-awesome-thing` does not exist, a new feature branch
from `master` will be cerated after a confirmation, and runs a
`git checkout my-awesome-thing` to drop you on the new branch.

    feature switch your-neato-thing

Assuming the branch `your-neato-thing` exists, it switches your current
checkout to that feature branch.

    feature finish optional-branch-name

Merges the feature branch back in to `master`, specifically ensure it's a
non-fast-forward merge. If no branch name is provided (i.e. invoked as
`feature finish`), then assume the user is on the feature branch they want to
finish, but confirm just in case.

## livebug script

    livebug <command> [branch name]

Automates the process of fixing a bug on the live site, similar to the `feature`
script with a few differences.

    livebug help

Shows how to use the script.

    livebug start my-sweet-fix

Makes a new branch from `stable` named `hotfix_my-sweet-fix`. Prepending the
name with `hotfix_` allows easy filtering.

    livebug switch my-other-fix

Switches hotfix branches.

    livebug finish optional-fix-name

Merges the hotfix branch back into `stable` with `--no-ff`. Also does a test
merge back into `master`. If it seems like it will merge cleanly, it does it.
Otherwise bail out. Possibly generate a patchfile and sendmail it to Danny,
James, or I to merge the hotfix back in later.

[gitflow]: http://nvie.com/posts/a-successful-git-branching-model/
