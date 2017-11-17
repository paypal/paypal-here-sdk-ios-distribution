package com.paypal.paypalretailsdk.ui.dialogs;

import android.app.AlertDialog;
import android.content.Context;
import android.content.res.Resources;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.paypal.paypalretailsdk.R;

public class SDKDialogBuilderWithNoButtonsAndProgressBar extends RetailAlertBuilder
{
  TextView mTitleView;
  TextView mMessageView;
  ProgressBar mProgressBar;
  int mTitleFontSizeId = -1;
  int mMessageFontSizeId = -1;


  public SDKDialogBuilderWithNoButtonsAndProgressBar(Context context)
  {
    super(context);
  }


  public SDKDialogBuilderWithNoButtonsAndProgressBar(Context context, int titleFontSizeResId, int messageFontSizeResId)
  {
    super(context);
    mTitleFontSizeId = titleFontSizeResId;
    mMessageFontSizeId = messageFontSizeResId;
  }


  public void setView(Context context)
  {
    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    view = inflater.inflate(R.layout.sdk_alert_dialog_with_no_buttons, null);
    mTitleView = (TextView) view.findViewById(R.id.title);
    mMessageView = (TextView) view.findViewById(R.id.message);
    mProgressBar = (ProgressBar) view.findViewById(R.id.progress_bar);
    updateFontSize(context);
    setView(view);
  }


  @Override
  public AlertDialog.Builder setTitle(CharSequence title)
  {
    if (null != title)
    {
      mTitleView.setText(title);
      mTitleView.setVisibility(View.VISIBLE);
    }
    else
    {
      mTitleView.setVisibility(View.GONE);
    }
    return this;
  }


  @Override
  public AlertDialog.Builder setMessage(CharSequence message)
  {
    if (null != message)
    {
      mMessageView.setText(message);
      mMessageView.setVisibility(View.VISIBLE);
    }
    else
    {
      mMessageView.setVisibility(View.GONE);
    }
    return this;
  }


  public void setProgressBarVisibility(boolean visible)
  {
    if (visible)
    {
      mProgressBar.setVisibility(View.VISIBLE);
    }
    else
    {
      mProgressBar.setVisibility(View.GONE);
    }
  }


  private void updateFontSize(Context context)
  {
    final Resources resources = context.getResources();
    if (mTitleFontSizeId > 0)
    {
      mTitleView.setTextSize(TypedValue.COMPLEX_UNIT_PX, resources.getDimensionPixelSize(mTitleFontSizeId));
    }

    if (mMessageFontSizeId > 0)
    {
      mMessageView.setTextSize(TypedValue.COMPLEX_UNIT_PX, resources.getDimensionPixelSize(mMessageFontSizeId));
    }
  }

}
