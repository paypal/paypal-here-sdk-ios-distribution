package com.paypal.paypalretailsdk.ui.signature;

import java.util.HashMap;

import android.content.Intent;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.PayPalRetailObject;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class SignaturePresenter extends RetailSDKBasePresenter
{
  protected static SignaturePresenter _instance;
  private SignatureActivity mActivity;


  public static SignaturePresenter getInstance()
  {
    if (_instance == null)
    {
      _instance = new SignaturePresenter();
    }

    return _instance;
  }


  private SignaturePresenter()
  {

  }


  @Override
  public Intent createActivityIntent(V8Object options, HashMap<String, String> extraData)
  {
    return new Intent(getCurrentActivity(), SignatureActivity.class);
  }


  @Override
  public void onLayoutInitialized(RetailSDKBaseActivity activity)
  {
    this.mActivity = (SignatureActivity) activity;

    String title = getV8OptionsStringValue("title");
    String signHere = getV8OptionsStringValue("signHere");
    String footer = getV8OptionsStringValue("footer");
    String cancel = getV8OptionsStringValue("cancel");

    if (title != null)
    {
      mActivity.setTitleText(title);
    }
    if (signHere != null)
    {
      mActivity.setWatermark(signHere);
    }
    if (footer != null)
    {
      mActivity.setFooter(footer);
    }
    if (cancel != null)
    {
      mActivity.setCancelButtonText(cancel);
    }
    else
    {
      mActivity.setVisibilityOfCancelButton(false);
    }
  }


  public void cancelTransaction()
  {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          V8Array args = PayPalRetailObject.getEngine().createJsArray();
          args.pushUndefined().pushUndefined().push(true);
          mJsCallback.call(mImpl, args);
        }
      }
    });
  }


  public void onSignatureBitmapReceived(final String bitmap)
  {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          finishActivity();
          V8Array args = PayPalRetailObject.getEngine().createJsArray();// getEmptyArray().twin();
          args.pushUndefined().push(bitmap);
          mJsCallback.call(mImpl, args);
          release();
        }
      }
    });
  }


  public void handleBackPressed()
  {
    cancelTransaction();
  }


  @Override
  public void finishActivityImplementation()
  {
    super.finishActivityImplementation();
    mActivity.finish();
  }
}
