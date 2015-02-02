#!/bin/bash

set -e -o pipefail

dub test --compiler=${DC}

if [ ! -z "$GH_TOKEN" ]; then
    dub build -b docs --compiler=${DC}
    cd docs
    git init
    git config user.name "Travis-CI"
    git config user.email "travis@nodemeatspace.com"
    git add .
    git commit -m "Deployed to Github Pages"
    #git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" docs:gh-pages > /dev/null 2>&1
    git push --force "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" docs:gh-pages
fi
