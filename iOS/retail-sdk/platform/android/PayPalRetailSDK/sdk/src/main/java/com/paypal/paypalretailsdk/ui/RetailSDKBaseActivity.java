package com.paypal.paypalretailsdk.ui;

import android.app.Activity;
import android.content.res.Configuration;
import android.os.Bundle;

public abstract class RetailSDKBaseActivity extends Activity
{

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    this.initComponents(savedInstanceState);
    getPresenter().onLayoutInitialized(this);
  }


  protected abstract RetailSDKBasePresenter getPresenter();


  public abstract void initComponents(Bundle savedInstanceState);


  @Override
  public void onConfigurationChanged(Configuration newConfig)
  {
    super.onConfigurationChanged(newConfig);
  }
}
