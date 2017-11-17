package com.paypal.paypalretailsdk.ui.receipt;

import java.util.HashMap;

import android.content.Intent;
import android.util.Patterns;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.NativeInterface;
import com.paypal.paypalretailsdk.PayPalRetailObject;
import com.paypal.paypalretailsdk.ReceiptEmailEntryViewContent;
import com.paypal.paypalretailsdk.ReceiptSMSEntryViewContent;
import com.paypal.paypalretailsdk.ReceiptViewContent;
import com.paypal.paypalretailsdk.readers.common.StringUtil;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class ReceiptSendToPresenter extends RetailSDKBasePresenter
{

  private static ReceiptSendToPresenter mInstance;
  private ReceiptSendToActivity mActivity;
  private ReceiptViewContent viewContent;
  private SendReceiptTo sendTo;


  public static ReceiptSendToPresenter getInstance()
  {
    if (mInstance == null)
    {
      mInstance = new ReceiptSendToPresenter();
    }
    return mInstance;
  }


  private ReceiptSendToPresenter()
  {
  }


  @Override
  protected Intent createActivityIntent(final V8Object jsOptions, HashMap<String, String> extraData)
  {
    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        viewContent = NativeInterface.GetReceiptViewContent(jsOptions.getObject("viewContent"));
      }
    });
    sendTo = SendReceiptTo.valueOf(extraData.get("SendTo"));
    Intent myIntent = new Intent(getCurrentActivity(), ReceiptSendToActivity.class);
    /*
    Adding this flag makes the ReceiptSendToActivity to not be maintained in the activity stack
    This helps when navigating back to the app's screens and not sdk screens.
     */
    myIntent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
    return myIntent;
  }


  @Override
  public void onLayoutInitialized(RetailSDKBaseActivity activity)
  {
    mActivity = (ReceiptSendToActivity) activity;
    if (sendTo == SendReceiptTo.Email)
    {
      ReceiptEmailEntryViewContent emailViewContent = viewContent.getReceiptEmailEntryViewContent();
      mActivity.setReceiptTypeIcon("ic_email");
      mActivity.setTitle(emailViewContent.getTitle());
      mActivity.setSendButtonTitle(emailViewContent.getSendButtonTitle());
      mActivity.setDisclaimer(emailViewContent.getDisclaimer());
      mActivity.setEmailInputType();
      mActivity.setDestinationType(SendReceiptTo.Email.toString());
    }
    else
    {
      mActivity.setReceiptTypeIcon("ic_text");
      ReceiptSMSEntryViewContent smsViewContent = viewContent.getReceiptSMSEntryViewContent();
      mActivity.setTitle(smsViewContent.getTitle());
      mActivity.setSendButtonTitle(smsViewContent.getSendButtonTitle());
      mActivity.setDisclaimer(smsViewContent.getDisclaimer());
      mActivity.setPhoneInputType();
      mActivity.setDestinationType(SendReceiptTo.Sms.toString());
    }
  }


  @Override
  public void finishActivityImplementation()
  {
    super.finishActivityImplementation();
    mActivity.finish();
  }


  @Override
  public void handleBackPressed()
  {
    finishActivityImplementation();
  }


  /**
   * Validate the email that is being entered in the email field.
   * @param email The email input
   * @return true if the email is valid; false if invalid
   */
  public boolean validateEmail(String email)
  {
    return StringUtil.isNotEmpty(email) && Patterns.EMAIL_ADDRESS.matcher(email).matches();
  }


  /**
   * Validate the phone number being entered in the phone field.
   * Note: This doesn't actually verify if the number is an actual phone or not. Just verifies the right input type.
   * @param phone The phone input
   * @return true if the email is valid; false if invalid
   */
  public boolean validatePhone(String phone)
  {
    return StringUtil.isNotEmpty(phone) && Patterns.PHONE.matcher(phone).matches();
  }


  public void sendReceipt(final String destination)
  {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        if (mJsCallback != null)
        {
          finishActivity();
          mJsCallback.call(mImpl, SendReceiptTo.buildV8Args(destination));
          release();
        }
      }
    });
  }


  public void viewReceiptOptions()
  {
    finishActivity();
    ReceiptOptionsPresenter.getInstance().showActivity(null, this.mJsOptions, this.mJsCallback);
    release();
  }
}
