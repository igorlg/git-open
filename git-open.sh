#!/bin/bash

usage() {
  echo "Usage: $0 [user name] [repo name]"
  echo "Note: user name will default to \$GITHUB_USER or your \`git config --get github.user\` entry."
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
}

#parse_url git@github.com:glensc/git-open.git
#parse_url https://github.com/jeffreyiacono/git-open
#parse_url git@gitlab.com:gitlab-org/examples/mvn-example.git
#parse_url_codecommit codecommit::ap-southeast-2://profile@repo

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
  echo "version 1.3"
  exit 0
fi

if [ -z "$git_repo" ]; then
  baseurl=${GITHUB_URL:-"https://github.com"}
elif [[ $(git config remote.origin.url) == codecommit::* ]]; then
  # baseurl="https://ap-southeast-2.console.aws.amazon.com/codesuite/codecommit";username="repositories";repo="repo/browse?region=ap-southeast-2"
  parse_url_codecommit "$(git config remote.origin.url)"
else
  # baseurl="https://github.com";username="jeffreyiacono";repo="git-open"
  parse_url "$(git config remote.origin.url)"
fi

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
