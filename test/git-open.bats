#!/usr/bin/env bats

setup_file() {
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  export PATH="$DIR/../src:$PATH"

  export REPO_BASE=$DIR/../tmp
  export REPO_DIR=$REPO_BASE/git-open-test

  mkdir -p $REPO_BASE

  cd $REPO_BASE

  # Clone test repo
  git clone git@github.com:igorlg/git-open-test.git
  cd git-open-test
  git remote add origin-ssh git@github.com:igorlg/git-open-test.git

  # Create new local branch, add content and commit
  git checkout -b other_branch
  echo "More content" > OTHER_FILE.md
  git add .
  git commit -m "Second commit" --no-gpg-sign

  # Add fork repo as remote, push new branch to it.
  git remote add fork git@github.com:igorlg/git-open-test-fork.git
  git fetch fork
  git branch --set-upstream-to fork/other_branch

  git checkout main
}

teardown_file() {
  # Cleanup test repo
  cd $DIR
  # rm -rf $REPO_BASE
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  source $DIR/../src/git-open.sh
  cd $REPO_DIR

  # So that git-open prints the URL to stdout, instead of opening it.
  export DEBUG=1
}

teardown() {
  git checkout main
}

@test "git-open -v: Show correct version" {
  run main -v

  assert_success
  assert_equal $output "1.4.0"
}

@test "parse_url: SSH github URL" {
  parse_url "git@github.com:glensc/git-open.git"

  assert_equal $baseurl   "https://github.com"
  assert_equal $username  "glensc"
  assert_equal $repo      "git-open"
}

@test "parse_url: HTTPS github URL" {
  parse_url "https://github.com/jeffreyiacono/git-open"

  assert_equal $baseurl   "https://github.com"
  assert_equal $username  "jeffreyiacono"
  assert_equal $repo      "git-open"
}

@test "parse_url: SSH gitlab URL" {
  parse_url "git@gitlab.com:gitlab-org/examples/mvn-example.git"

  assert_equal $baseurl   "https://gitlab.com"
  assert_equal $username  "gitlab-org/examples"
  assert_equal $repo      "mvn-example"
}

@test "parse_url_codecommit: HTTPS GRC AWS CodeCommit URL with profile" {
  parse_url_codecommit "codecommit::ap-southeast-2://profile@repo"

  assert_equal $baseurl   "https://ap-southeast-2.console.aws.amazon.com/codesuite/codecommit"
  assert_equal $username  "repositories"
  assert_equal $repo      "repo/browse?region=ap-southeast-2"
}

@test "parse_url_codecommit: HTTPS GRC AWS CodeCommit URL without profile" {
  parse_url_codecommit "codecommit::ap-southeast-2://repo"

  assert_equal $baseurl   "https://ap-southeast-2.console.aws.amazon.com/codesuite/codecommit"
  assert_equal $username  "repositories"
  assert_equal $repo      "repo/browse?region=ap-southeast-2"
}

@test "get_git_remote: get URL for 'main' branch" {
  run get_git_remote

  assert_success
  assert_equal $output "https://github.com/igorlg/git-open-test.git"
}

@test "get_git_remote: get URL for 'other_branch' branch" {
  git checkout other_branch
  run get_git_remote

  assert_success
  assert_equal $output "git@github.com:igorlg/git-open-test-fork.git"
}






# $ git remote -v
# fork	git@github.com:igorlg/git-open-test-fork.git (fetch)
# fork	git@github.com:igorlg/git-open-test-fork.git (push)
# origin	https://github.com/igorlg/git-open-test.git (fetch)
# origin	https://github.com/igorlg/git-open-test.git (push)
# origin-ssh	git@github.com:igorlg/git-open-test.git (fetch)
# origin-ssh	git@github.com:igorlg/git-open-test.git (push)


# $ git branch -vv
# * main         a23a33e [origin/main] Initial commit
#   other_branch 5f92d9c [fork/other_branch: ahead 1, behind 1] Second commit
