#!/bin/bash

set -e -o pipefail

dub test --compiler=${DC}

if [[ $TRAVIS_BRANCH == 'master' ]] ; then
    if [ ! -z "$GH_TOKEN" ]; then
        git checkout master
        dub build -b docs --compiler=${DC}
        cd docs
        git init
        git checkout -b gh-pages
        git config user.name "Travis-CI"
        git config user.email "travis@nodemeatspace.com"
        git add .
        git commit -m "Deployed to Github Pages"
        #git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages > /dev/null 2>&1
        git push --force "https://BlackEdder:$GITHUB_API_KEY@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages
        #git push --force "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages
    fi
fi
