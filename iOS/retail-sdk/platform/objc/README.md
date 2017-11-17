PayPal Retail SDK for Objective-C
=============================

This is the internal README for the PayPal Retail SDK on iOS and OSX.

Building
========
* Follow the build instructions in the [main README](../../README.md)
* For the iOS test app, `cd platform/objc/iOS/TestApp`, `./repod.sh`, and then open `platform/objc/iOS/RetailSDKTestApp.xcworkspace`.
* For the OSX test app, `cd platform/objc/OSX`, `pod install`, and then open `platform/objc/iOS/RetailSDKTestApp.xcworkspace`.
* If you add a new file to the Retail SDK (either by creating a new .h or .m or by causing the codegen to generate a new .h or .m), you'll need to rerun `repod.sh` before running the test apps.
