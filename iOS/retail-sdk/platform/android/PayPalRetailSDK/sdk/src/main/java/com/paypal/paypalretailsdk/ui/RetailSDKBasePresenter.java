package com.paypal.paypalretailsdk.ui;

import java.util.HashMap;
import java.util.concurrent.Callable;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.V8Value;
import com.paypal.paypalretailsdk.PayPalRetailObject;
import com.paypal.paypalretailsdk.RetailSDK;

/**
 * The base presenter for all Retail Sdk activities
 * Encapsulates dealing with the V8 objects, handling dismiss from JS, and finishing the activity
 * The concrete activity and its finish should implemented in the concrete presenter
 */
public abstract class RetailSDKBasePresenter
{

  private final static String logComponent = "RetailSDKBasePresenter";

  protected V8Object mJsOptions;
  protected V8Function mJsCallback;
  protected V8Object mImpl;
  protected Intent mIntent;


  public final V8Object showActivity(final HashMap<String, String> extraData, final V8Object options, final V8Function cb)
  {
    Log.d(logComponent, "createActivityIntent");
    final V8Object handle =
        PayPalRetailObject.getEngine().getExecutor().run(new Callable<V8Object>()
        {
          @Override
          public V8Object call()
          {
            mJsOptions = options.twin();
            mJsCallback = cb.twin();
            mImpl = PayPalRetailObject.getEngine().createJsObject();
            mImpl.registerJavaMethod(RetailSDKBasePresenter.this, "dismiss", "dismiss", null);
            return mImpl.twin();
          }
        });

    this.mIntent = createActivityIntent(options, extraData);
    getCurrentActivity().startActivity(mIntent);
    Log.d(logComponent, "startActivity " + this.toString());
    return handle;
  }


  public final void finishActivity()
  {
    Log.d(logComponent, "finishActivity " + this.toString());
    finishActivityImplementation();
  }


  public final void dismiss()
  {
    Log.d(logComponent, "dismiss " + this.toString());
    finishActivity();
    release();
  }


  protected final void release()
  {
    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          mJsCallback.release();
          mJsCallback = null;
        }
        if (mImpl != null)
        {
          mImpl.release();
          mImpl = null;
        }
        if (mJsOptions != null)
        {
          mJsOptions.release();
          mJsOptions = null;
        }
      }
    });
  }


  protected String getV8OptionsStringValue(final String propName)
  {
    return PayPalRetailObject.getEngine().getExecutor().run(new Callable<String>()
    {
      @Override
      public String call()
      {
        String _value = null;
        if (mJsOptions.getType(propName) == V8Value.STRING)
        {
          _value = mJsOptions.getString(propName);
        }
        return _value;
      }
    });
  }


  protected Activity getCurrentActivity()
  {
    return RetailSDK.getAppState().getCurrentActivity();
  }


  public void finishActivityImplementation()
  {
  }


  public abstract void handleBackPressed();


  protected abstract Intent createActivityIntent(V8Object options, HashMap<String, String> extraData);


  public abstract void onLayoutInitialized(RetailSDKBaseActivity activity);

  public void initComponents(Activity activity)
  {
  }

  public void onDestroy()
  {
  }

  public void onNewIntent()
  {
  }
}
