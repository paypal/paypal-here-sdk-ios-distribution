package com.paypal.paypalretailsdk;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import android.content.Context;
import android.content.SharedPreferences;
import android.location.Location;
import android.util.Base64;
import android.util.Log;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;
import com.paypal.manticore.ManticoreEngine;
import com.paypal.paypalretailsdk.ui.dialogs.SDKDialogProxy;
import com.paypal.paypalretailsdk.ui.receipt.ReceiptOptionsPresenter;
import com.paypal.paypalretailsdk.ui.signature.SignaturePresenter;

// TODO this class needs to be hidden, but you can't call methods on package/private classes from Rhino (AFAICT).


/**
 * The main clearing house for events and methods called into the native layer from Javascript
 */
public class NativeInterface
{
  private final static String logComponent = "RetailSDKNative";

  private static String SECURE_TYPE = "S";
  private static String STRING_TYPE = "V";
  private static String SECURE_BLOB_TYPE = "E";
  private static String BLOB_TYPE = "B";
  private ManticoreEngine engine;
  private static NativeInterface sInstance;


  private NativeInterface()
  {

  }


  public static NativeInterface getInstance()
  {
    if (sInstance == null)
    {
      sInstance = new NativeInterface();
    }
    return sInstance;
  }


  public void inspect(Object object)
  {
    Log.d(logComponent, object.toString());
  }


  public void ready(V8Object sdk)
  {
    RetailSDK.setJsSdk(sdk);
  }


  public V8Object alert(final V8Object options, final V8Function callback)
  {
    return SDKDialogProxy.displayAlert(options, callback).impl.twin();
  }


  public V8Object collectSignature(final V8Object options, final V8Function callback)
  {
    Log.d(logComponent, "collectSignature");
    SDKDialogProxy.clearAlertDialog();
    V8Object signatureHandle = SignaturePresenter.getInstance().showActivity(null, options, callback);
    return signatureHandle;
  }


  public void offerReceipt(V8Object options, V8Function callback)
  {
    Log.d(logComponent, "offerReceipt");
    SDKDialogProxy.clearAlertDialog();
    ReceiptOptionsPresenter.getInstance().showActivity(null, options, callback);
  }


  public void getLocation(V8Function cb)
  {
    Log.d(logComponent, "getLocation");
    final V8Function callback = cb.twin();
    Location location = RetailSDK.getLocationService().getCurrentLocation();
    final V8Object locationObj = PayPalRetailObject.getEngine().createJsObject();
    double latitude = 0.0;
    double longitude = 0.0;
    float accuracy = 0;
    if (location != null)
    {
      latitude = location.getLatitude();
      longitude = location.getLongitude();
      accuracy = location.getAccuracy();
    }
    locationObj.add("latitude", latitude);
    locationObj.add("longitude", longitude);
    locationObj.add("accuracy", accuracy);
    callback.call(engine.getManticoreJsObject(), engine.createJsArray().pushUndefined().push(locationObj));
  }


  // TODO Secure is not really secure yet...
  public void getItem(String name, String storage, V8Function callback)
  {
    V8Array result = RetailSDK.jsArgs();
    if (BLOB_TYPE.equals(storage) || SECURE_BLOB_TYPE.equals(storage))
    {
      try
      {
        File f = RetailSDK.sContext.getFileStreamPath(filenameForStorage(storage, name));
        FileInputStream inputStream = RetailSDK.sContext.openFileInput(filenameForStorage(storage, name));
        InputStreamReader sr = new InputStreamReader(inputStream, "UTF8");
        StringBuilder content = new StringBuilder((int) f.length());
        char[] buffer = new char[Math.min((int) f.length(), 65535)];
        int n;
        while ((n = sr.read(buffer)) != -1)
        {
          content.append(buffer, 0, n);
        }
        inputStream.close();
        result.pushNull().push(content.toString());
      }
      catch (IOException io)
      {
        callback.call(null, RetailSDK.jsArgs().push(engine.asJsError(io.getMessage(), "1", io.getStackTrace().toString())));
        return;
      }
    }
    else
    {
      SharedPreferences sharedPref = RetailSDK.sContext.getSharedPreferences(RetailSDK.sContext.getString(R.string.preference_file_key), Context.MODE_PRIVATE);
      String value = sharedPref.getString(name + storage, null);
      result.pushNull().push(value);
    }
    callback.call(null, result);
  }


  public boolean hasItem(String name, String storage)
  {
    if (BLOB_TYPE.equals(storage) || SECURE_BLOB_TYPE.equals(storage))
    {
      File f = RetailSDK.sContext.getFileStreamPath(filenameForStorage(storage, name));
      return f.exists();
    }
    else
    {
      SharedPreferences sharedPref = RetailSDK.sContext.getSharedPreferences(RetailSDK.sContext.getString(R.string.preference_file_key), Context.MODE_PRIVATE);
      return sharedPref.contains(name + storage);
    }
  }


  // TODO Secure is not really secure yet...
  public void setItem(String name, String storage, String value, V8Function callback)
  {
    if (BLOB_TYPE.equals(storage) || SECURE_BLOB_TYPE.equals(storage))
    {
      String filename = SHA256(name);
      try
      {
        FileOutputStream outputStream = RetailSDK.sContext.openFileOutput(filenameForStorage(storage, name), Context.MODE_PRIVATE);
        outputStream.write(value.getBytes("UTF8"));
        outputStream.close();
      }
      catch (IOException io)
      {
        if (callback != null)
        {
          callback.call(null, RetailSDK.jsArgs().push(engine.asJsError(io.getMessage(), "2", io.getStackTrace().toString())));
        }
        return;
      }
    }
    else
    {
      SharedPreferences sharedPref = RetailSDK.sContext.getSharedPreferences(RetailSDK.sContext.getString(R.string.preference_file_key), Context.MODE_PRIVATE);
      SharedPreferences.Editor editor = sharedPref.edit();
      String key = name + storage;
      editor.putString(key, value);
      editor.commit();
    }
    if (callback != null)
    {
      callback.call(null, null);
    }
  }


  public void register(final ManticoreEngine engine)
  {
    this.engine = engine;
    engine.getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        V8Object nativeObject = engine.getManticoreJsObject();
        Class<?>[] optsCallback = new Class<?>[]{V8Object.class, V8Function.class};

        nativeObject.registerJavaMethod(NativeInterface.this, "ready", "ready", new Class<?>[]{V8Object.class});
        nativeObject.registerJavaMethod(NativeInterface.this, "inspect", "inspect", new Class<?>[]{Object.class});
        nativeObject.registerJavaMethod(NativeInterface.this, "alert", "alert", optsCallback);
        nativeObject.registerJavaMethod(NativeInterface.this, "collectSignature", "collectSignature", optsCallback);
        nativeObject.registerJavaMethod(NativeInterface.this, "offerReceipt", "offerReceipt", optsCallback);
        nativeObject.registerJavaMethod(NativeInterface.this, "getItem", "getItem", new Class<?>[]{String.class, String.class, V8Function.class});
        nativeObject.registerJavaMethod(NativeInterface.this, "setItem", "setItem", new Class<?>[]{String.class, String.class, String.class, V8Function.class});
        nativeObject.registerJavaMethod(NativeInterface.this, "hasItem", "hasItem", new Class<?>[]{String.class, String.class});
        nativeObject.registerJavaMethod(NativeInterface.this, "getLocation", "getLocation", new Class<?>[]{V8Function.class});
      }
    });
  }


  private String filenameForStorage(String storage, String name)
  {
    String filename = SHA256(name).replace('/', '_');
    return String.format("PayPalRetailSDK-%s-%s", storage, filename);
  }


  private static String SHA256(String text)
  {
    try
    {
      MessageDigest md = MessageDigest.getInstance("SHA-256");

      md.update(text.getBytes());
      byte[] digest = md.digest();

      return Base64.encodeToString(digest, Base64.NO_WRAP);
    }
    catch (NoSuchAlgorithmException n)
    {
      throw new RuntimeException("Core cryptography systems are broken. SHA-256 algorithm not found.");
    }
  }


  public static ReceiptViewContent GetReceiptViewContent(V8Object viewContent)
  {
    return ReceiptViewContent.nativeInstanceForObject(viewContent);
  }
}