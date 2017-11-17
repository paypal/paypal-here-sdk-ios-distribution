package com.paypal.paypalretailsdk.ui.dialogs;

import android.app.AlertDialog;
import android.content.Context;
import android.view.View;

public abstract class RetailAlertBuilder extends AlertDialog.Builder
{
  protected View view;

  public RetailAlertBuilder(Context context)
  {
    super(context);
  }

  public View getView()
  {
    return view;
  }
}
