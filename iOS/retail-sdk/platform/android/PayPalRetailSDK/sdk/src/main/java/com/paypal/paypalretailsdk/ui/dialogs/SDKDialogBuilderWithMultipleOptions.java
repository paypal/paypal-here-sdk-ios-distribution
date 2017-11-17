package com.paypal.paypalretailsdk.ui.dialogs;

import java.util.List;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.res.Resources;
import android.graphics.drawable.Drawable;
import android.util.TypedValue;
import android.view.ContextThemeWrapper;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;

/**
 * Created by sashar on 7/5/2016.
 */
public class SDKDialogBuilderWithMultipleOptions extends RetailAlertBuilder
{
  TextView mTitleView;
  TextView mMessageView;
  LinearLayout mOptionView;
  ImageView mImageView;


  public SDKDialogBuilderWithMultipleOptions(Context context)
  {
    super(new ContextThemeWrapper(context, R.style.DialogStyle));
    setCancelable(false);
  }


  public void setView(Context context)
  {
    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    view = inflater.inflate(R.layout.sdk_alert_dialog_with_options, null);
    mTitleView = (TextView) view.findViewById(R.id.title);
    mMessageView = (TextView) view.findViewById(R.id.message);
    mOptionView = (LinearLayout) view.findViewById(R.id.optionList);
    mOptionView.removeAllViews();
    mImageView = (ImageView) view.findViewById(R.id.image);
    setView(view);
  }

  private int getPixelsForDp(Context context, int dp) {
    Resources r = context.getResources();
    return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp, r.getDisplayMetrics());
  }


  public SDKDialogBuilderWithMultipleOptions setOptions(Context context, final List<String> list, final DialogInterface.OnClickListener listener)
  {
    mOptionView.removeAllViews();
    LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);

    params.setMargins(0, 0, 0, getPixelsForDp(context, 6));
    params.gravity = Gravity.CENTER;

    for (int i = 0; i < list.size(); i++)
    {
      String optionTxt = list.get(i);
      Button optionBtn = new Button(new ContextThemeWrapper(context, R.style.SDKButton_ActionItem_Primary_Blue), null, R.style.SDKButton_ActionItem_Primary_Blue);
      optionBtn.setLayoutParams(params);
      optionBtn.setText(optionTxt);
      optionBtn.setTextSize(TypedValue.COMPLEX_UNIT_SP, 24);
      optionBtn.setPadding(getPixelsForDp(context, 16), getPixelsForDp(context, 10), getPixelsForDp(context, 16), getPixelsForDp(context, 10));
      final int optionIndex = i;
      optionBtn.setOnClickListener(new View.OnClickListener()
      {
        @Override
        public void onClick(View v)
        {
          listener.onClick(null, optionIndex);
        }
      });
      mOptionView.addView(optionBtn);
    }
    return this;
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
