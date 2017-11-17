retail-sdk
===============

A re-imagining of the PayPal Here SDKs as a single cross platform code base. The core
is written in javascript, and codegen tools are used to create native shims that call
in and out of Javascript implementations. The relatively thin native modules in turn
can be used as native SDKs to implement card swipe and EMV payment applications.
The desire is to centralize all cross-platform-capable code in this Javascript facade
and only write native code necessary to display the user interface and talk to hardware.

Currently, native modules have the following responsibilities:
* Instantiate the javascript engine and load the core SDK
* Establish connections to hardware readers and shuffle bytes (without understanding them)
* Display alert UI
* Display receipt selection UI
* Make network requests (without understanding them)

See the [Platform README](platform/README.md) for more details.

Build Status
============

Platform | Status
-------- | ------
iOS | [![Build Status](http://bender.corp.ebay.com:8080/buildStatus/icon?job=retail-sdk-ios)](http://bender.corp.ebay.com:8080/view/On-Demand%20Jobs/job/retail-sdk-ios/)
MacOS | [![Build Status](http://bender.corp.ebay.com:8080/buildStatus/icon?job=retail-sdk-osx)](http://bender.corp.ebay.com:8080/view/On-Demand%20Jobs/job/retail-sdk-osx/)
Windows (All) | [![Build Status](http://bender.corp.ebay.com:8080/buildStatus/icon?job=retail-sdk-windows)](http://bender.corp.ebay.com:8080/job/retail-sdk-windows/)
Android | [![Build Status](http://bender.corp.ebay.com:8080/buildStatus/icon?job=retail-sdk-android)](http://bender.corp.ebay.com:8080/view/On-Demand%20Jobs/job/retail-sdk-android/)
ChromeOS/Chrome App |
Node.js | [![Build Status](http://bender.corp.ebay.com:8080/buildStatus/icon?job=retail-sdk-core)](http://bender.corp.ebay.com:8080/view/On-Demand%20Jobs/job/retail-sdk-core/)

Basic Build Instructions
========================
- Install [Node.js](https://nodejs.org/) and [nvm Linux/Mac](https://github.com/creationix/nvm) or [nvm Windows](https://github.com/coreybutler/nvm-windows)
- Clone the repo
- Get submodules with ```./update-repo.sh```
- Generate Javascript build and generated platform files: ```./node_modules/.bin/gulp develop```
- Make sure your environment is sane: ```npm test```

See the platform specific READMEs for more information: [Mac/iOS](platform/objc/README.md), [Windows](platform/win/README.md), [Android](platform/android/README.md), [Chrome](platform/chrome/README.md), [Node.js](platform/node/README.md)

Platforms
=========
We currently support the following platforms using the listed Javascript Interpreters/VMs. Jint and Rhino are not
JIT compilers, so they are slower. At some point we may want to optimize this but so far it's fine.

* Windows XP - [Jint pure .Net JSVM](https://github.com/sebastienros/jint)
* Windows Desktop (aka post XP, pre 8.1) - [Microsoft ClearScript JSVM](https://clearscript.codeplex.com/)
* Windows 8.1 Desktop and Windows Phone 8.1 - [Jint pure .Net JSVM](https://github.com/sebastienros/jint)
* iOS 7+ and Mac OS X - [JavaScriptCore](https://developer.apple.com/library/mac/documentation/Carbon/Reference/WebKit_JavaScriptCore_Ref/)
* Android 2.3+ - [J2V8](https://github.com/eclipsesource/J2V8)
* Node.js - V8, duh.
* Chrome - V8, again duh. This is a pure-javascript implementation using [Chrome APIs for apps](https://developer.chrome.com/apps).

Current and planned features and parity metrics:

- :smile: Done with tests
- :ok: It worked on my machine once
- :no_entry_sign: Not considered possible


Feature                     | iOS             | OSX     | Android         | WinXP | Win8- | Win81 | WP8.1 | Node | Chrome
--------------------------- | --------------- | ------- | --------------- | ----- | ----- | ----- | ----- | ---- | ------
Initialize SDK              | :smile:         | :smile: | :smile:         |:smile:| :smile:|:smile:|:smile:| :ok: | :ok:
Initialize Merchant         | :ok:            | :smile: | :smile:         |:smile:|:smile:|:smile:|:smile:| :ok: | :ok:
Create an Invoice           | :smile:         | :smile: | :smile:         |:smile:|:smile:|:smile:|       | :ok: | :ok:
Save an Invoice             | :smile:         | :smile: | :ok:            | :ok:  | :ok:  | :ok:  | :ok:  | :ok: | :ok:
Connect USB Swiper          | :no_entry_sign: | :ok:    | :no_entry_sign: | :ok:  | :ok:  | :ok:  | :no_entry_sign: | :ok: | :ok:
Connect ROAM Audio Readers  | :ok:            | :no_entry_sign: |                 |       |       |       | :no_entry_sign:
Connect Miura Readers BT    | :ok:            | :ok:    |                 | :ok:  | :ok:  | :ok:  | :ok:  | :ok: | :ok:
Connect Miura Readers USB   | :no_entry_sign: | :ok:    |                 | :ok:  | :ok:  | :ok:  | :no_entry_sign: | :ok: | :ok:
Complete a Swipe Payment    | :ok:            | :ok:    |                 |       | :ok:  |       |       |      | :ok:
Complete a Chip&Pin Payment | :ok:            | :ok:    | :ok:            |       | :ok:  |       | :ok:  |      | :ok:
Complete an NFC Payment     |                 | :ok:    | :ok:            |       |       |       | :ok:  |      | :ok:
Display Generic Alerts      | :ok:            | :ok:    | :ok:            |       |       |       | :ok:  |      | :ok:
Display Receipt Flow        |                 |         |                 |       |       |       |       |      | :ok:
Display Signature View      | :ok:            | :ok:    |                 |       |       |       |       |      | :ok:
ZeroConf for automation     | :ok:            | :ok:    |
Get and Set Secure Data     | :ok:            | :ok:

Standards
=========
* ES6 with babel transpilation to ES5
* JSDoc for documentation and native object generation
* Browserify for module packaging and minification
* Gulp for builds and task running
* Mocha for tests
* Super-subtle - if your JS file begins with a capital letter, it exports a class.

Modules
=======
Where possible, isolated functionality should be contained in an isolated
node module. For now, we are developing most of the code in the repo (tlv
processing was already in its own module).

Code Generation
===============
The codegen directory contains a script that parses the Javascript looking for
JSDoc comments (using docchi parser for now because JSDoc doesn't support ES6).
It builds a model of the exposed types and then uses DustJS templates to render
code in each of the target languages and/or platforms. Currently, we can generate:

* Objective-C
* Java
* C# in two flavors (for Jint and Clearscript)
* Xamarin for iOS (C# but bound against the iOS Objective-C library)

Javascript Conventions
======================
* If it's not documented, it can't be called from SDK consumers
* Private (meaning never leaves Javascript) variables should be prefixed with _
* Some JS engines are picky about parameter counts on native functions (e.g. callbacks). Pass all parameters that you declare.

Task List
=========
Pick one for yourself!

- [ ] Create server modules in Ruby/ASP.Net/etc to handle the token generation ala Braintree
- [ ] Many more Mocha tests for the JS layer
- [ ] Code coverage
- [ ] Cleanup and factor the dust templates (java j2v8 is a good example of the goal), and apply an indentation reformatter afterwards so the templates are readable
- [ ] CocoaPod, nuGet, java packaging framework for easy app creation
- [ ] Fix returning/instantiating subclasses of JS objects in native languages... Probably some hack since this is an infrequent usage
