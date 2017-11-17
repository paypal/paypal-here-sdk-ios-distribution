package com.paypal.paypalretailsdk;

import com.eclipsesource.v8.V8Object;
import com.paypal.manticore.DefaultTypeConverter;
import com.paypal.manticore.ManticoreEngine;

/**
 * Created by mmetral on 6/18/15.
 */
public class RetailSDKTypeConverter extends DefaultTypeConverter
{
  public RetailSDKTypeConverter(ManticoreEngine engine) {
    super(engine);
  }

  @Override
  public <T> T asNative(Object value, Class<T> type) {
    if (value == null) {
      return null;
    }

    if (value instanceof V8Object) {
      if (((V8Object)value).isUndefined()) {
        return null;
      }
    }
    if (PayPalRetailObject.class.isAssignableFrom(type)) {
      PayPalRetailObject returnValue = null;
      try {
        returnValue = (PayPalRetailObject)type.getDeclaredConstructor(V8Object.class).newInstance(value);
      } catch (Exception e) {
        e.printStackTrace();
      }
      returnValue.impl = (V8Object)value;
      return type.cast(returnValue);
    } else if (type == RetailSDKException.class) {
      return type.cast(new RetailSDKException((V8Object)value));
    }
    return super.asNative(value, type);
  }

  @Override
  public V8Object asJs(Object nativeInstance) {
    if (nativeInstance instanceof PayPalRetailObject) {
      return ((PayPalRetailObject)nativeInstance).impl;
    }
    return super.asJs(nativeInstance);
  }}
