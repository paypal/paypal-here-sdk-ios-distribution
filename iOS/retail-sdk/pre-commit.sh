#!/bin/bash

# go to root of repository
ROOTDIR=$(git rev-parse --show-toplevel)
cd "$ROOTDIR"

./node_modules/.bin/gulp lint
LINTRESULT=$?
npm test
TESTRESULT=$?
[ $LINTRESULT -ne 0 ] && exit 1
[ $TESTRESULT -ne 0 ] && exit 1
exit 0
