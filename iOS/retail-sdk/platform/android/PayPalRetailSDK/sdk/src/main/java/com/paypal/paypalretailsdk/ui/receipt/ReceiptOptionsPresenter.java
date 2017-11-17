package com.paypal.paypalretailsdk.ui.receipt;

import java.util.HashMap;

import android.content.Intent;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.NativeInterface;
import com.paypal.paypalretailsdk.PayPalRetailObject;
import com.paypal.paypalretailsdk.ReceiptViewContent;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class ReceiptOptionsPresenter extends RetailSDKBasePresenter
{

  private static ReceiptOptionsPresenter _instance;
  private ReceiptOptionsActivity mActivity;
  private ReceiptViewContent viewContent;


  public static ReceiptOptionsPresenter getInstance()
  {
    if (_instance == null)
    {
      _instance = new ReceiptOptionsPresenter();
    }
    return _instance;
  }


  private ReceiptOptionsPresenter()
  {
  }


  @Override
  public Intent createActivityIntent(final V8Object jsOptions, HashMap<String, String> extraData)
  {
    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        viewContent = NativeInterface.GetReceiptViewContent(jsOptions.getObject("viewContent"));
      }
    });

    /*
    Changing the way start activity is called for receipt options as finish on the
    signature activity is not explicitly called. Also, trying to avoid the signature activity
    showing up for a split second
     */
    Intent intent = new Intent(getCurrentActivity(), ReceiptOptionsActivity.class);
    return intent;
  }


  @Override
  public void onLayoutInitialized(RetailSDKBaseActivity activity)
  {
    mActivity = (ReceiptOptionsActivity) activity;

    //DE92712: For some reason viewContent is null.. This is just defensive code
    //TODO: Investigate and monitor LIVE to see why this happens
    if(viewContent != null)
    {
      mActivity.setTitleText(viewContent.getReceiptOptionsViewContent().getTitle());
      mActivity.setMessage(viewContent.getReceiptOptionsViewContent().getMessage());
      mActivity.setTitleIcon(viewContent.getReceiptOptionsViewContent().getTitleIconFilename());
      mActivity.createAdditionalOptionsButtons(viewContent.getReceiptOptionsViewContent().getAdditionalReceiptOptions());
      mActivity.addNoReceiptButton(viewContent.getReceiptOptionsViewContent().getNoThanksButtonTitle());

      String maskedEmail = viewContent.getReceiptOptionsViewContent().getMaskedEmail();
      if (maskedEmail != null && !maskedEmail.isEmpty())
      {
        mActivity.addMaskedEmail(maskedEmail);
      }
      else
      {
        mActivity.setEmailButtonTitle(viewContent.getReceiptOptionsViewContent().getEmailButtonTitle());
      }

      String maskedPhone = viewContent.getReceiptOptionsViewContent().getMaskedPhone();
      if (maskedPhone != null && !maskedPhone.isEmpty())
      {
        mActivity.addMaskedPhone(maskedPhone);
      }
      else
      {
        mActivity.setPhoneButtonTitle(viewContent.getReceiptOptionsViewContent().getSmsButtonTitle());
      }
    }
    else
    {
      // If null, default to sendReceipt with no destination
      // NOTE: This would skip the receipt screen, But would ensure no crashes happen.
      sendReceipt(null);
    }
  }


  @Override
  public void finishActivityImplementation()
  {
    super.finishActivityImplementation();
    mActivity.finish();
  }


  void sendReceipt(final String destination)
  {
    finishActivity();
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          mJsCallback.call(mImpl, SendReceiptTo.buildV8Args(destination));
        }
        release();
      }
    });
  }

  void additionalReceiptOptionCallback(final int optionIndex, final String optionName) {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          mJsCallback.call(mImpl, SendReceiptTo.buildV8Args(optionIndex, optionName));
        }
      }
    });
  }

  void openReceiptSendToActivity(SendReceiptTo sendTo)
  {
    finishActivity();
    HashMap<String, String> extraData = new HashMap<>();
    extraData.put("SendTo", sendTo.getMethod());
    ReceiptSendToPresenter.getInstance().showActivity(extraData, this.mJsOptions, this.mJsCallback);
    release();
  }


  @Override
  public void handleBackPressed()
  {

  }
}
