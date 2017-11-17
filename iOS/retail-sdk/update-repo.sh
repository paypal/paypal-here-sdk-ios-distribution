#! /bin/bash

if [ ! -d sdkenv ]; then
  echo "Setting up nodeenv"
  if ! type "nodeenv" > /dev/null 2>&1; then
    sudo easy_install nodeenv
  fi
  nodeenv --node=6.5.0 --with-npm --npm=3.10.9 --prebuilt sdkenv
fi
. sdkenv/bin/activate
echo "NODE `node -v` NPM `npm -v`"

echo "Syncing submodules"
git submodule update --init --recursive

echo "Pulling changes from remote"
git pull

npm config set registry http://npm.paypal.com

echo "Updating node submodules"
npm update
