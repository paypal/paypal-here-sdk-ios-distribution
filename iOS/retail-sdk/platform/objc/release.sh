#!/bin/bash

BRANCH=`git symbolic-ref --short HEAD`

git clone git@github.paypal.com:RetailSDK-NewGen/objc-cocoapod-release-stage.git
cd objc-cocoapod-release-stage
git clone git@github.paypal.com:RetailSDK-NewGen/retail-sdk.git
cd retail-sdk
git checkout $BRANCH
git reset --hard HEAD
npm install
cd node_modules/miura-emv
../../node_modules/.bin/gulp
cd ../..
./node_modules/.bin/gulp gen js-release
cp PayPalRetailSDK.podspec ..
cp PayPalRetailSDK.js ..
rm -rf ../platform
mv platform ..
cd ..
rm -rf retail-sdk
rm -rf platform/win
rm -rf platform/node
rm -rf platform/chrome
rm -rf platform/android
rm platform/README.md
sed -i '' '/^Common.generated.*$/d' platform/objc/.gitignore
