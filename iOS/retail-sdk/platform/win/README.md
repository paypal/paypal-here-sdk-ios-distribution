PayPal Retail SDK for Windows
=============================

This is the internal README for the PayPal Retail SDK on the Windows platform.

The Windows implementation is not a single implementation. It's a painful combination of constraints that yields the following mix:

Platform    | Javascript Engine | .Net Framework | Device Libraries | UI Framework
----------- | ----------------- | -------------- | ---------------- | ------------
Windows XP  | Jint (pure .Net)  | 4.0 | HidLibrary and 32Feet | WPF
Windows 7/8/Vista | Microsoft ClearScript | 4.5 | HidLibrary and 32Feet | WPF
Windows 8.1 Desktop | Jint | 4.5 | Microsoft POS, USB and Bluetooth Stack |
Windows 8.1 Phone | Jint | 4.5 | Microsofot Bluetooth Stack |

Building
========
* Clone the repo
* Install node.js@6.5.0, potentially restarting afterwards to get your path updated
* Install nvm from this [link](https://github.com/coreybutler/nvm-windows)
* Install Python 2.7
* Install OpenSSL 1.0.2
* From a command prompt, run ```npm config set registry http://npm.paypal.com```
* Execute shell script ```.\update-repo.sh```
* Build the generated code files and the combined Javascript SDK with ```.\node_modules\.bin\gulp js-debug gen```
