package com.paypal.paypalretailsdk.ui.dialogs;

import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.PayPalRetailObject;

public class SDKDialogProxy extends PayPalRetailObject
{
  private SDKDialogProxy()
  {
    this.impl = PayPalRetailObject.getEngine().createJsObject();
    this.impl.registerJavaMethod(this, "jsIsShowing", "isShowing", null);
    this.impl.registerJavaMethod(this, "jsDismiss", "dismiss", null);
  }

  public V8Object getJsObject()
  {
    return this.impl;
  }

  public static SDKDialogProxy displayAlert(V8Object options, V8Function callback)
  {
    SDKDialogProxy dialogProxy = new SDKDialogProxy();
    SDKDialogPresenter.getInstance().onNewCommand(new SDKDialogCommand(dialogProxy, SDKDialogCommand.CommandType.SHOW, options, callback));
    return dialogProxy;
  }


  public boolean jsIsShowing()
  {
    return SDKDialogPresenter.getInstance().isShowing();
  }


  /**
   * JavaScript's (manticore.alert).dismiss() points to this function
   */
  public void jsDismiss()
  {
    SDKDialogPresenter.getInstance().onNewCommand(SDKDialogCommand.getDismissCommand(this));
  }


  /**
   * Clear SDK Alert dialog without invoking JS callback... Typically used in scenarios where the dialog needs to be dismissed when a new SDK activity (like signature, receipt, etc.)
   * should replace the alert dialog activity
   */
  public static void clearAlertDialog()
  {
    SDKDialogPresenter.getInstance().onNewCommand(SDKDialogCommand.getDismissCommand(null));
  }
}
