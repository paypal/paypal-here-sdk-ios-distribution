PayPal Retail SDK for Windows
=============================
This is the internal README for the PayPal Retail SDK on the Windows platform.


Publishing
========

The PayPal Retail SDK for Windows is published as a nuget package on our nuget server hosted on Azure.
* Nuget server url (add this as a nuget package source in Visual Studio): ```http://paypalretailsdknuget.azurewebsites.net/nuget```
* Publishing to the server is manual. Keep track of the last version number published.
* To publish a new package:
  * Build the PayPalRetailSDK.sln solution from Visual Studio
  * ```ci.msbuild.cmd <new package version>``` e.g. where ```<new package version>``` is something like 0.0.0.45
