
Supporting Token Refresh for the SDK

  Here's an overview of the PPHSDK and supporting refresh.  

  The SDK is given an access token, an expires time, and a refresh_url.  This is done when the app calls the SDK's [PayPalHereSDK setActiveMerchant:] method.  See PPHMerchant's payPalAccount member.

  The SDK will automatically attempt to refresh the access token using the refresh_url supplied by the app.  This happens in two cases.

  First: This will happen when the SDK is about to execute a network call and finds (preemptively) that the expires_in time has elapsed.  It will then call the refresh_url, parse the response, and then attempt the call (take payment, save invoice, etc).

  Second: It will also call this refresh_url when a network call returns with an error indicating that the access_token is no longer valid.  In this case it will call the refresh_url, parse the response, and reattempt the network call.  It does this cycle once.  If the network call (take payment, save invoice, etc) fails with the same invalid access token message a second time the SDK will give up and return this error to the completion handler the app provided.

  Here's an example refresh_url I generated using our sample app and sample server.  Yours can look however you want it to.
http://morning-tundra-8515.herokuapp.com/refresh/dom/mBCgGmDi6nLHGEUtsZzZhJXgbAxFyY4Zp9DCMqusWcK67wysSytcjgR2tK0l4PIiL+eBi6SguuWJQYysLkZy4OpxSOpH+skaJHi9Ls7H1HETwLbScwpkjt3DYKPqjiwmPFFuh+qnvfi8FgN3jML5Jjpsg6HQggSaVQ6mxKEQlPR5ZG7P


  Here is an example response when I call this refresh_url.  Your server's response should also look like this so the SDK can parse it correctly.
{
  "access_token": "6FaIukmIEl4eaJ5UKXeWCLBB1Cui8O9lFmgtdPgrS0s",
  "refresh_url": "http://morning-tundra-8515.herokuapp.com/refresh/dom/ehoviiRefX4bW7oO9i9vU30U1InbRCSMCzljz6bDdE4Pm5bKUjD6dHZqjbByxQebur1ayJ5w567/yF6TwPGGB6X5gkmNQrf9gQlz4cRLUIfbbQR/yoY+nW3PVjzHdxoSRzkPID+qVsEPK2Upa6YQBUOpIj5+D83U3swQn3bLfmWiHYZP",
  "expires_in": 28801
}

Here we can see the new access_token being returned along with a new refresh URL.  If the response from your server is JSON matching the above the SDK will be able to extract the new access_token, refresh_url, and expires_in values.  It will then start to use this refresh_url.

The refresh token should never be stored in your app on the mobile device.  Store it in your mid-tier server.  Your mid-tier server will then be able to generate refresh_urls and _it_ will be able to create new access tokens to hand back to your app using the above refresh response.



