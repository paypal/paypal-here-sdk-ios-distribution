package com.paypal.paypalretailsdk;

import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.V8Value;

import java.util.concurrent.Callable;

/**
 * Created by mmetral on 3/27/15.
 */
public class RetailSDKException extends Exception
{
  V8Object _jsError = null;

  RetailSDKException(V8Object jsError) {
    super(jsError.getString("message"));
    _jsError = jsError;
  }

  RetailSDKException(Exception inner) {
    super(inner);
  }

  public String getCode() {
    return PayPalRetailObject.getEngine().getExecutor().run(new Callable<String>() {
      @Override public String call() {
        int _jsType = _jsError.getType("code");
        if (_jsType == V8Value.UNDEFINED || _jsType == V8Value.NULL) {
          return null;
        }
        return _jsError.getString("code");
      }
    });
  }

  public String getDeveloperMessage() {
    return PayPalRetailObject.getEngine().getExecutor().run(new Callable<String>() {
      @Override public String call() {
        int _jsType = _jsError.getType("developerMessage");
        if (_jsType == V8Value.UNDEFINED || _jsType == V8Value.NULL) {
          return null;
        }
        return _jsError.getString("developerMessage");
      }
    });
  }

  public String getDebugId() {
    return PayPalRetailObject.getEngine().getExecutor().run(new Callable<String>() {
      @Override public String call() {
        int _jsType = _jsError.getType("debugId");
        if (_jsType == V8Value.UNDEFINED || _jsType == V8Value.NULL) {
          return null;
        }
        return _jsError.getString("debugId");
      }
    });
  }
}
