#!/usr/bin/env bash
BRANCH="master"
TARGET_REPO="stkyle/stkyle.github.io.git"
REPO_URL="https://github.com/stkyle/stkyle.github.io.git"
PELICAN_OUTPUT_FOLDER="output"

echo -e "Testing travis-encrypt"
echo -e "$ENCRYPTION_LABEL"
pwd
ls -la

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo -e "Starting to deploy to Github Pages\n"
    if [ "$TRAVIS" == "true" ]; then
        git config --global user.email "travis@travis-ci.org"
        git config --global user.name "Travis"
    fi
    #using token clone gh-pages branch
    git clone --branch=$BRANCH $REPO_URL built_website 
    #> /dev/null
    #go into directory and copy data we're interested in to that directory
    cd built_website
    rm -rf ./**/* || exit 0
    rsync -rv --exclude=.git  ../$PELICAN_OUTPUT_FOLDER/* .
    #add, commit and push files
    git add -A
    git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to Github Pages"
    # Save some useful information
    REPO=`git config remote.origin.url`
    SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
    SHA=`git rev-parse --verify HEAD`
    # Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in ../id_rsa_github.enc -out deploy_key -d
    chmod 600 deploy_key
    eval `ssh-agent -s`
    ssh-add deploy_key

    git push $SSH_REPO $BRANCH
    rm deploy_key
    echo -e "Deploy completed\n"
fi
