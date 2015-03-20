PayPal Access
=============

In order to authenticate merchants to PayPal and to issue API calls on their behalf for processing payment, you use
PayPal Access, which uses standard OAuth protocols. Basically, you send the merchant to a web page on paypal.com,
they login, and are then redirected back to a URL you control with an "oauth token." That token is then exchanged for
an "access token" which can be used to make API calls on the merchant's behalf. Additionally, a "refresh token" is
returned in that exchange that allows you to get a new access token at some point in the future without merchant
interaction. All of this is based on two pieces of data from your application - an app id and a secret. You can setup
PayPal Access and/or create an application via the [devportal](https://developer.paypal.com/). As of this writing your application will still need to be specifically enabled for the PayPal Here scope. To enable the PayPal Here scopes please contact us at <DL-PayPal-Here-SDK@ebay.com>. 
You'll note that it asks you for a Return URL, and that this Return URL must be http or https. This means you can't
redirect directly back to your mobile app after a login. But the good news is this would be a terrible idea anyways.
You never want to store your application secret on a mobile device - you can't be sure it isn't jailbroken or
otherwise compromised and once it's out there you don't have many good options for updating all your users.
So instead, you need a backend server to host this secret and control the applications usage of OAuth on
behalf of your merchants. While you can use PayPal Access as your sole point of authentication, you likely have an
existing account system of some sort, so you would first authenticate your users to your system, then send them to
PayPal and link up the accounts on their return.

The other good news is that we've included a simple sample implementation of a back end server with the SDK, written
in Node.js which most people should be able to read reasonably easily. The sample server implements four REST service
endpoints:

1. /login - a dummy version of your user authentication. It returns a "secret ticket" that can be used in place of a
password to reassure you that the person you're getting future requests from is the same person that typed in their
password to your application.
2. /goPayPal - validates the ticket and returns a URL which your mobile application can open in Safari to start
the PayPal access flow. This method specifies the OAuth scopes you're interested in, which must include the PayPal
Here scope (https://uri.paypal.com/services/paypalhere) if you want to use PayPal Here APIs.
3. /goApp - when PayPal Access completes and the merchant grants you access, PayPal will return them to this
endpoint, and this endpoint will inspect the result and redirect back to your application. First, the code calls PayPal
to exchange the OAuth token for the access token. The request to do the exchange looks like this:
```javascript
    request.post({
      url:config.PAYPAL_ACCESS_BASEURL + "auth/protocol/openidconnect/v1/tokenservice",
        auth:{
          user:config.PAYPAL_APP_ID,
          pass:config.PAYPAL_SECRET,
          sendImmediately:true
        },
        form:{
          grant_type:"authorization_code",
          code:req.query.code
        }
    }, function (error, response, body) {
    });
```
Now comes the important part. The server encrypts the access token received from PayPal using the client ticket so that
even if someone has hijacked your application's URL handler, the data will be meaningless since it wasn't the one that
sent the merchant to the PayPal Access flow anyways (this implies you chose your ticket well - the sample server doesn't
really do this because there's no backend to speak of, it's just a flat file database). Secondly, it returns a URL
to your mobile application that allows it to generate a refresh token. This URL is to the /refresh handler and
includes the refresh token issued by PayPal encrypted with an "account specific server secret." The refresh token is
never stored on the server, and is not stored in a directly usable form on the client either. This minimizes the value
of centralized data on your server, and allows you to cutoff refresh tokens at will in cases of client compromise.
4. /refresh/username/token - This handler decrypts the refresh token and calls the token service to get a new
access token given that refresh token.

To setup the server you need to setup your ReturnURL in PayPal Access to point to your instance of the sample server.
Assuming you want to test on a device, this URL needs to work on that device and on your simulator typically, meaning
you need a "real" DNS entry somewhere. Hopefully you can do this on your office router, or buy a cheap travel router
and do it there. Alternatively, you could stick the server on heroku or some such. See config.js in the sample-server
directory for the variables you need to set to run the sample server. To run the sample server, after modifying
config.js, install Node.js and run "npm install" in the sample-server directory. Then run "node server.js" and you
should see useful log messages to the console. The server advertises itself using Bonjour/zeroconf, so the sample app
should find it automatically. But again, the return URL in PayPal Access is harder to automate, so you'll need to
configure that once. One instance of the sample server can serve all your developers in theory, so it's easiest to
run it on some shared or external resource.
