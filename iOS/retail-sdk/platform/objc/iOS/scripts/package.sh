#!/bin/sh
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Clean the build folders
rm -rf armdebug armrelease simdebug simrelease Debug Release

# Build all 4 combinations - arm/sim, release/debug
xcodebuild -workspace ../RetailSDK.iOS.xcworkspace -scheme 'PayPalRetailSDK' -configuration 'Debug' -sdk iphonesimulator8.3 CONFIGURATION_BUILD_DIR=$DIR/simdebug
xcodebuild -workspace ../RetailSDK.iOS.xcworkspace -scheme 'PayPalRetailSDK' -configuration 'Debug' -sdk iphoneos8.3 CONFIGURATION_BUILD_DIR=$DIR/armdebug
xcodebuild -workspace ../RetailSDK.iOS.xcworkspace -scheme 'PayPalRetailSDK' -configuration 'Release' -sdk iphonesimulator8.3 CONFIGURATION_BUILD_DIR=$DIR/simrelease
xcodebuild -workspace ../RetailSDK.iOS.xcworkspace -scheme 'PayPalRetailSDK' -configuration 'Release' -sdk iphoneos8.3 CONFIGURATION_BUILD_DIR=$DIR/armrelease

# Lipo the architectures for debug and create the distribution folder
mkdir -p Debug
cp -r armdebug/PayPalRetailSDK.framework Debug/PayPalRetailSDK.framework
lipo -create armdebug/PayPalRetailSDK.framework/PayPalRetailSDK simdebug/PayPalRetailSDK.framework/PayPalRetailSDK -output Debug/PayPalRetailSDK.framework/PayPalRetailSDK

# Lipo the architectures for release and create the distribution folder
mkdir -p Release
cp -r armrelease/PayPalRetailSDK.framework Release/PayPalRetailSDK.framework
lipo -create armrelease/PayPalRetailSDK.framework/PayPalRetailSDK simrelease/PayPalRetailSDK.framework/PayPalRetailSDK -output Release/PayPalRetailSDK.framework/PayPalRetailSDK

# Resource bundles
cp -r armdebug/PayPalRetailSDKResources.bundle Debug/PayPalRetailSDKResources.bundle
cp -r armrelease/PayPalRetailSDKResources.bundle Release/PayPalRetailSDKResources.bundle

# Clean up after ourselves.
rm -rf armdebug armrelease simdebug simrelease
