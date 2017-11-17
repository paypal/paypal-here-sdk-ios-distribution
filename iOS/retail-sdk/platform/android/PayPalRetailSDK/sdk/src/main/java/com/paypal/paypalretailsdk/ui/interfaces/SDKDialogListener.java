package com.paypal.paypalretailsdk.ui.interfaces;

/**
 * Created by sashar on 4/21/2016.
 */
public interface SDKDialogListener
{
  public void onPositiveButtonClick();


  public void onNegativeButtonClick();


  public void onOptionSelected(int option);


  public boolean isCancelable();


  public void onCancelled();
}
