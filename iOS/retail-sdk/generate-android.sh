#! /bin/bash

#  ____  ____  _   _   ____      _        _ _   ____  ____  _  __
# |  _ \|  _ \| | | | |  _ \ ___| |_ __ _(_) | / ___||  _ \| |/ /
# | |_) | |_) | |_| | | |_) / _ \ __/ _` | | | \___ \| | | | ' /
# |  __/|  __/|  _  | |  _ <  __/ || (_| | | |  ___) | |_| | . \
# |_|   |_|   |_| |_| |_| \_\___|\__\__,_|_|_| |____/|____/|_|\_\
#

if [ ${#@} == 0 ]; then
    echo "Usage: $0 [d] [t]"
    echo "d: Directory where the final binary will be copied to."
    echo "t: Build target: Optional; default is 'develop'.  Otherwise use 'release'"
    exit 0
fi

_DIR="$1"
_TARGET="develop"

if [ -z "$_DIR" ]; then
    echo "Please provide a directory for library to be copied."
    exit 0
fi

if [ ! -z $2 ]; then
    _TARGET=$2
fi

clear

node -v

#after rebase, do "./update-repo.sh"!!!

# Build retail-sdk
./node_modules/.bin/gulp ${_TARGET}

# Generate android aar file
cd ./platform/android/PayPalRetailSDK/sdk/
../gradlew clean assemble${_TARGET}

# Copying aar file to target
cp ./build/outputs/aar/sdk-${_TARGET}.aar $1
echo copied aar file to $1

