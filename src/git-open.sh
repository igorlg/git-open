#!/bin/bash

# TODO: Refactor the structure, to always use `git remote` to find the proper remote
#       and derive the URL from there.
# TODO: Change to use zsh instead of bash.
# TODO: Remove reliance on global variables!
# TODO: Add bats unit tests
# TODO: Add proper cmd line argument parsing (lines 83-95 are horrible)


VERSION="1.4.0"

usage() {
  echo "Usage: $0 [user name] [repo name]"
  echo "Note: user name will default to \$GITHUB_USER or your \`git config --get github.user\` entry."
}

version() {
  echo "$VERSION"
}

# creates variables into parent scope:
# baseurl="https://github.com";username="jeffreyiacono";repo="git-open"
parse_url() {
  local url="$1" project host proto path

  project=${url##**/}

  host=${url#git@}
  host=${host#ssh:\/\/git@}
  host=${host#http://}
  host=${host#https://}
  proto=${url%$host}
  host=${host%%[:/]*}

  path=${url#$proto$host[:/]}
  path=${path%/$project}

  project=${project%.git}

  # update globals
  baseurl="https://$host"
  username="$path"
  repo="$project"
}

# separate function to parse CodeCommit URLs (e.g. codecommit::ap-southeast-2://profile@repo)
parse_url_codecommit() {
  local proto region url profile repo_name

  proto="$(echo $1 | sed -e's,^\(.*://\).*,\1,g')"
  url="$(echo ${1/$proto/})"
  
  region="$(echo $1 | cut -d ':' -f 3)"
  profile="$(echo $url | grep @ | cut -d@ -f1)"
  repo_name="$(echo ${url/$profile@/} | cut -d/ -f1)"

  # update globals  
  baseurl="https://${region}.console.aws.amazon.com/codesuite/codecommit"
  username="repositories"
  repo="${repo_name}/browse?region=${region}"

  if [ -n "${DEBUG:-}" ]; then
    echo "[parse_url_codecommit] 1        = '${1}'"
    echo "[parse_url_codecommit] region   = '${region}'"
    echo "[parse_url_codecommit] baseurl  = '${baseurl}'"
    echo "[parse_url_codecommit] username = '${username}'"
    echo "[parse_url_codecommit] repo     = '${repo}'"
  fi
}

get_git_remote() {
  local remote
  remote="$(git branch -vv | grep '^*' | awk '{print $4}' | tr -d '[]' | cut -d '/' -f 1)"
  # remote="$(git remote | head -1)"

  if [ -z "$remote" ]; then
    return 1
  fi

  git config "remote.${remote}.url"
}

main() {
  git_repo=$(git rev-parse --git-dir 2>/dev/null)

  if [ $# = 0 ]; then
    if [ -z "$git_repo" ]; then
      echo "Error: must pass repo name or run from a git repo to open"
      usage
      exit 1
    fi
  elif [ "$1" = "-h" ]; then
    usage
    exit 0
  elif [ "$1" = "-v" ]; then
    version
    exit 0
  fi

  if [ -z "$git_repo" ]; then
    baseurl=${GITHUB_URL:-"https://github.com"}
  elif [[ $(get_git_remote) == codecommit::* ]]; then
    # baseurl="https://ap-southeast-2.console.aws.amazon.com/codesuite/codecommit";username="repositories";repo="repo/browse?region=ap-southeast-2"
    parse_url_codecommit "$(get_git_remote)"
  else
    # baseurl="https://github.com";username="jeffreyiacono";repo="git-open"
    parse_url "$(git config remote.origin.url)"
  fi

  # TODO: What is this??? Is it needed?
  if [ $# = 1 ]; then
    username=${GITHUB_USER:-$(git config --get github.user)}
    repo=$1
  elif [ $# = 2 ]; then
    username=$1
    repo=$2
  fi

  if [ -n "${DEBUG:-}" ]; then
    echo $baseurl/$username/$repo
  else
    open $baseurl/$username/$repo
  fi
}

if [ "$0" -eq "git-open" ]; then
  main
fi
