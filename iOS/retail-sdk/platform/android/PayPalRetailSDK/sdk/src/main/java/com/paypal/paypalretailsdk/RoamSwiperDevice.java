package com.paypal.paypalretailsdk;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.HashMap;
import java.util.UUID;

import android.content.Context;
import android.util.Base64;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;

import com.paypal.paypalretailsdk.readers.common.AudioJackManager;
import com.paypal.paypalretailsdk.readers.common.CardReaderInterface;
import com.paypal.paypalretailsdk.readers.common.CardReaderObserver;

import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;
import org.json.JSONObject;

/**
 * Created by muozdemir on 11/16/16.
 */

public class RoamSwiperDevice extends PayPalRetailObject implements CardReaderObserver
{
  private static final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
  private static final String LOG_TAG = RoamSwiperDevice.class.getSimpleName();


  public enum ConnectionStatus
  {
    None,
    Connecting,
    Connected
  }


  private ConnectionStatus mStatus = ConnectionStatus.None;
  private AudioJackManager mDevice;
  private V8Object mNativeReader;
  private boolean mIsRegistered = false;
  private boolean mIsRemoved = false;


  public RoamSwiperDevice()
  {
    mDevice = RetailSDK.getAudioJackManager();
    Log.d(LOG_TAG, "Found PayPal Reader Device: " + mDevice.getName());
  }


  public void createJSReader()
  {
    Log.d(LOG_TAG, " createJSReader for : " + mDevice.getName());
    mIsRemoved = false;
    // if you change any argument in the following methods, please update here as well!!!
    mNativeReader = PayPalRetailObject.getEngine().createJsObject();
    mNativeReader.registerJavaMethod(this, "isConnected", "isConnected", null);
    mNativeReader.registerJavaMethod(this, "jsConnect", "connect", new Class<?>[]{V8Function.class});
    mNativeReader.registerJavaMethod(this, "jsDisconnect", "disconnect", new Class<?>[]{V8Function.class});
    mNativeReader.registerJavaMethod(this, "send", "send", new Class<?>[]{Object.class, V8Object.class});
    mNativeReader.registerJavaMethod(this, "jsRemoved", "removed", new Class<?>[]{V8Function.class});

    final V8Object deviceBuilder = PayPalRetailObject.getEngine().createJsObject("DeviceBuilder", RetailSDK.jsArgs());
    final V8Array args = getEngine().createJsArray()
        .push("ROAM")
        .push(mDevice.getName())
        .push(false)
        .push(mNativeReader);


    this.impl = PayPalRetailObject.getEngine().createJsObject("RoamSwiperDevice", RetailSDK.jsArgs().push(mDevice.getName()).push(mNativeReader));
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        RoamSwiperDevice.this.impl = deviceBuilder.executeObjectFunction("build", args);
        PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
        {
          @Override
          public void run()
          {
            RetailSDK.getJsSdk().discoveredPaymentDevice(new PaymentDevice(RoamSwiperDevice.this.impl));
            RoamSwiperDevice.this.impl.executeVoidFunction("connect", RetailSDK.jsArgs());
          }
        });
      }
    });


  }


  private void disconnect()
  {
    Log.d(LOG_TAG, "Disconnect Roam Swiper Device : " + mDevice.getName());
    try
    {
      if (mDevice.isConnected())
      {
        mDevice.disconnect();
      }
      mIsRegistered = false;
      mStatus = ConnectionStatus.None;
    }
    catch (Exception x)
    {
      Log.d(LOG_TAG, "Roam Swiper Error happened during the disconnect " + x.toString());
    }
  }


  public boolean isConnected()
  {
    return mStatus == ConnectionStatus.Connected;
  }


  public void register()
  {
    if (mDevice.isConnected())
    {
      Log.d(LOG_TAG, "registering Roam Swiper Device : " + mDevice.getName());
      mDevice.registerObserverToRoamSwiper(this);
      mIsRegistered = true;
    }
  }


  public boolean isRegistered()
  {
    return mIsRegistered;
  }


  public void jsConnect(V8Function jsCallback)
  {
    Log.d(LOG_TAG, "connect to Roam Swiper Reader Device: " + mDevice.getName());
    final V8Function callback = (V8Function) jsCallback.twin();
    if (!this.isConnected())
    {
      if (mDevice.isConnected())
      {
        PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
        {
          @Override
          public void run()
          {
            mStatus = ConnectionStatus.Connected;
            Log.d(LOG_TAG, "Found PayPal Reader Device connected to : " + mDevice.getName());
            callback.call(mNativeReader, RetailSDK.jsArgs().pushUndefined());
          }
        });
      }
      else
      {
        //ToDo: what error to send back?
        Log.d(LOG_TAG, "Roam swiper is not connected!");
      }
    }
  }


  public void jsDisconnect(V8Function jsCallback)
  {
    final V8Function callback = (V8Function) jsCallback.twin();
    if (this.isConnected())
    {
      Log.d(LOG_TAG, "disconnect to Roam Swiper Reader Device: " + mDevice.getName());
      this.disconnect();
      PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
      {
        @Override
        public void run()
        {
          Log.d(LOG_TAG, "Found PayPal Reader Device disconnect callback executed ");
          callback.call(mNativeReader, RetailSDK.jsArgs().pushUndefined());
        }
      });

    }
  }


  public void jsRemoved(V8Function jsCallback)
  {
    if (this.isConnected())
    {
      this.disconnect();
    }

    final V8Function callback = (V8Function) jsCallback.twin();
    Log.d(LOG_TAG, "removed Roam Swiper Reader Device: " + mDevice.getName());
    this.mIsRemoved = true;
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        Log.d(LOG_TAG, "Found PayPal Reader Device removed callback executed ");
        callback.call(mNativeReader, RetailSDK.jsArgs().pushUndefined());
      }
    });

  }

  public boolean isRemoved()
  {
    return mIsRemoved;
  }


  public boolean send(Object data, V8Object callback)
  {
    if (data instanceof String)
    {
      Log.d(LOG_TAG, "RoamSwiperDevice - send data: " + data.toString());
      if (data.equals("listenForCardEvents"))
      {
        mDevice.listenForCardEvents();
      }
      else if (data.equals("stopListeningForCardEvents"))
      {
        mDevice.stopListeningForCardEvents();
      }
    }
    else
    {
      Log.d(LOG_TAG, "RoamSwiperDevice - unknown data: " + data.toString());
    }

    V8Function jsCallback = null;
    if (callback != null && !callback.isUndefined())
    {
      jsCallback = (V8Function) callback;
    }
    try
    {
      if (jsCallback != null && !jsCallback.isUndefined())
      {
        jsCallback.call(mNativeReader, RetailSDK.jsArgs().pushUndefined());
      }
      return true;
    }
    catch (Exception x)
    {
      if (jsCallback != null && !jsCallback.isUndefined())
      {
        // TODO don't throw string error...
        jsCallback.call(mNativeReader, RetailSDK.jsArgs().push(PayPalRetailObject.getEngine().asJsError(x)));
      }
      return false;
    }
  }


  public void onDeviceDetected(boolean isValidReader, CardReaderInterface.DeviceTypes type, CardReaderInterface.DeviceFamily family)
  {
    Log.d(LOG_TAG, "onDeviceDetected isValidReader: " + isValidReader + " type: " + type + " Family: " + family);
    if (type.equals(CardReaderInterface.DeviceTypes.RoamPayReader) && isValidReader)
    {
      Log.d(LOG_TAG, "onDeviceDetected RoamPayReader detected");
      mStatus = ConnectionStatus.Connected;
    }
  }


  public void onDeviceLostConnection(final CardReaderInterface.DeviceTypes type, final CardReaderInterface.DeviceFamily family)
  {
    RetailSDK.logViaJs("info", LOG_TAG, "onDeviceLostConnection deviceType: " + type + " deviceFamily: " + family);
    if (type.equals(CardReaderInterface.DeviceTypes.RoamPayReader))
    {
      PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
      {
        @Override
        public void run()
        {
          RetailSDK.logViaJs("error", LOG_TAG, "startReadLoop Invoking jsRemoved() on deviceType: " + type + " deviceFamily: " + family);
          RoamSwiperDevice.this.impl.executeVoidFunction("removed", RetailSDK.jsArgs());
        }
      });
    }
  }


  public void onDeviceError(String error)
  {
    Log.e(LOG_TAG, "Decode error? error = " + error);
  }


  public void onSwipeDetected(final HashMap<String, String> decodeData, final String track1)
  {
    Log.d(LOG_TAG, "Hey look...we have a card swipe");

    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        try
        {
          final V8Object returnValue = PayPalRetailObject.getEngine().createJsObject();
          JSONObject decodedJsonData = new JSONObject(decodeData);
          final String base64Data = Base64.encodeToString(decodedJsonData.toString().getBytes(), Base64.NO_WRAP);
          Log.d(LOG_TAG, "onSwipeDetected: " + decodedJsonData.toString());
          returnValue.add("decodeData", base64Data);
          returnValue.add("track1", track1);
          RoamSwiperDevice.this.impl.executeVoidFunction("received", RetailSDK.jsArgs().push(returnValue));
        }
        catch (Exception x)
        {
          StringWriter sw = new StringWriter();
          PrintWriter pw = new PrintWriter(sw);
          x.printStackTrace(pw);
          Log.d("ERROR", "RoamSwiperDevice", x);
        }
      }
    });

  }

  private void showSwipeFailedToast() {
    Context currentActivity = RetailSDK.getAppState().getCurrentActivity();
    Toast toast = new Toast(currentActivity);
    LayoutInflater inflater = (LayoutInflater) currentActivity.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    View toastView = inflater.inflate(R.layout.toast_swipe_failed, null);
    ImageView imageView = (ImageView) toastView.findViewById(R.id.swipe_failed_image);
    imageView.setImageResource(R.drawable.ic_swipe_failed);

    toast.setGravity(Gravity.CENTER_VERTICAL, 0, 0);
    toast.setDuration(Toast.LENGTH_SHORT);
    toast.setView(toastView);
    toast.show();
  }

  public void onSwipeFailed()
  {
    Log.d(LOG_TAG, "Hey look...Swipe has failed");
    showSwipeFailedToast();
  }


}
