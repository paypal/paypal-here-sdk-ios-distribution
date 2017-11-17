Javascript Engine Notes
=======================

This page is a collection of discoveries and notes about hosting a Javascript engine
inside our SDK. Some of the information may be plain wrong, but at least we can
reference our assumptions and expectations in one place.

We need the following features from a JS Engine:

- Call Named Javascript Methods from Native
- Call Lambda expressions from Native
- Call native functions from Javascript
- Expose native objects to Javascript
- Send native Lambdas to Javascript (events/callbacks)
- Buffer handling (UInt8Array or similar)
- Arbitrary precision numbers and math
- Sane threading

As a refresher:

- iOS/MacOSX - JavaScriptCore
- Android - Rhino, though we may want to consider v8
- Windows 8- - ClearSript, which embeds v8 (and is a mixed mode assembly, so that's why it can't be on Win8.1+)
- Windows 8.1 Desktop and Phone - Jint, a pure .Net Javascript implementation
- Node - native v8. Generally won't be discussed here because it just works

Native Lambdas to Javascript
============================
Various javascript objects fire events that native code (usually from the app hosting the SDK).

Jint uses ClrFunctionInstance for this, and our code gen will build wrappers dynamically
that respond to the call and translate JS types in and out of the native types.

JavaScriptCore allows you to send blocks into Javascript, though you need to be careful about
reference counting and garbage collection. JSProtect/JSRelease functions allow you to say which
Javascript objects you want to keep around. For event handling, since we have to wrap the block in our
type converting block, we have to return a "signal handle" that you can use to unsubscribe later.
It's debatable whether this should be typed or not...

Sane Threading
==============
Jint demands only a single thread call "meaty" javascript methods at a time. It seems that
single property reads (so long as they are just data lookups) don't need serialization,
but if statements need to be executed, use the RetailSDK.JS or RetailSDK.JSWithReturn
executor functions to do your operations.

Buffer Handling
===============
All engines other than Jint seem to support UInt8Array which the bops module uses. NOTE:
turns out Browserify has a Buffer implementation that works with and without UInt8Array.
We should switch to that rather than the polyfill we use now.

Arbitrary Precision Numbers
===========================
We use bignumber.js, but it seems to pull in a ton of stuff via browserify (crypto for example)
so we may need to reconsider. Could be that a native type would provide a reasonable performance
boost, though we're not that heavy on math routines.