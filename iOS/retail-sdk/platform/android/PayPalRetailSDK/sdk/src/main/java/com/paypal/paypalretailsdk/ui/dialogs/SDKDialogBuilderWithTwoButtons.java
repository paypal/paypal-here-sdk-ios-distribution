package com.paypal.paypalretailsdk.ui.dialogs;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.ContextThemeWrapper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.paypal.paypalretailsdk.R;

public class SDKDialogBuilderWithTwoButtons extends RetailAlertBuilder
{
  TextView mTitleView;
  TextView mMessageView;
  Button mPositiveButton;
  Button mNegativeButton;
  ImageView mImageView;


  public SDKDialogBuilderWithTwoButtons(Context context)
  {
    super(new ContextThemeWrapper(context, R.style.DialogStyle));
    setCancelable(false);
  }


  public void setView(Context context)
  {
    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    view = inflater.inflate(R.layout.sdk_alert_dialog_with_2_buttons, null);
    mTitleView = (TextView) view.findViewById(R.id.title);
    mMessageView = (TextView) view.findViewById(R.id.message);
    mPositiveButton = (Button) view.findViewById(R.id.positiveBtn);
    mNegativeButton = (Button) view.findViewById(R.id.negativeBtn);
    mImageView = (ImageView) view.findViewById(R.id.image);
    setView(view);
  }


  @Override
  public AlertDialog.Builder setTitle(CharSequence title)
  {
    mTitleView.setText(title);
    return this;
  }


  @Override
  public AlertDialog.Builder setMessage(CharSequence message)
  {
    mMessageView.setText(message);
    return this;
  }


  public void setPositiveButtonClickListener(String text, View.OnClickListener listener)
  {
    if (null != text)
    {
      mPositiveButton.setText(text);
    }
    mPositiveButton.setOnClickListener(listener);
  }


  public void setNegativeButtonClickListener(String text, View.OnClickListener listener)
  {
    if (null != text)
    {
      mNegativeButton.setText(text);
    }
    mNegativeButton.setOnClickListener(listener);
  }


  public void hidePositiveButton()
  {
    mPositiveButton.setVisibility(View.GONE);
  }


  public void hideNegativeButton()
  {
    mNegativeButton.setVisibility(View.GONE);
  }


  public void hideTitle()
  {
    mTitleView.setVisibility(View.GONE);
  }


  public void hideMessage()
  {
    mMessageView.setVisibility(View.GONE);
  }


  public void hideImage()
  {
    mImageView.setVisibility(View.GONE);
  }


  public void setmImageView(Drawable image)
  {
    mImageView.setBackgroundDrawable(image);
  }
}
