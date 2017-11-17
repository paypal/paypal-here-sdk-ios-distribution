package com.paypal.paypalretailsdk;

import android.content.Context;
import com.eclipsesource.v8.V8Object;
import com.paypal.manticore.ManticoreEngine;

/**
 * A marker class for objects related to the PayPal Retail SDK. Internally provides some common logging
 * and debugging services.
 */
public class PayPalRetailObject
{
  protected V8Object impl;

  protected PayPalRetailObject() {
  }

  protected PayPalRetailObject(V8Object object) {
    this.impl = object;
  }

  private static ManticoreEngine jsEngine;
  private static NativeInterface nativeInterface;




  public static ManticoreEngine getEngine() {
    return jsEngine;
  }

  static void createManticoreEngine(Context context, String script) {
    ManticoreEngine me = new ManticoreEngine(context);
    nativeInterface = NativeInterface.getInstance();
    me.setConverter(new RetailSDKTypeConverter(me));
    nativeInterface.register(me);
    // Make sure to set the engine before loading the script because some JS things may call
    // BACK into Java upon loading and you need an engine to do stuff with those calls.
    jsEngine = me;
    me.loadScript(script);
  }

}
