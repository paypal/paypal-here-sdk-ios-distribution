package com.paypal.paypalretailsdk.ui.dialogs;

import java.util.List;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.drawable.Drawable;
import android.view.ContextThemeWrapper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;

/**
 * Created by muozdemir on 12/20/16.
 */
public class SDKDialogBuilderWithMultipleOptionsWithImgs extends RetailAlertBuilder
{
  TextView mMessageView;
  LinearLayout mOptionView;
  ImageView mLeftImageView;
  ImageView mRightImageView;


  public SDKDialogBuilderWithMultipleOptionsWithImgs(Context context)
  {
    super(new ContextThemeWrapper(context, R.style.DialogStyle));
    setCancelable(false);
  }


  public void setView(Context context)
  {
    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    view = inflater.inflate(R.layout.retail_dialog_image_buttons, null);
    mMessageView = (TextView) view.findViewById(R.id.retail_dialog_message);
    mLeftImageView = (ImageView) view.findViewById(R.id.retail_left_image_button);
    mRightImageView = (ImageView) view.findViewById(R.id.retail_right_image_button);
    setView(view);
  }


  @Override
  public AlertDialog.Builder setMessage(CharSequence message)
  {
    if (null != message)
    {
      mMessageView.setText(message);
    }
    return this;
  }


  public void hideMessage()
  {
    mMessageView.setVisibility(View.GONE);
  }


  public SDKDialogBuilderWithMultipleOptionsWithImgs addLeftOptionButton(Drawable leftImg, View.OnClickListener onClickListener)
  {
    if (leftImg != null)
    {
      mLeftImageView.setImageDrawable(leftImg);
      mLeftImageView.setVisibility(View.VISIBLE);
      mLeftImageView.setOnClickListener(onClickListener);
    }
    else
    {
      mLeftImageView.setVisibility(View.GONE);
    }

    return this;
  }


  public SDKDialogBuilderWithMultipleOptionsWithImgs addRightOptionButton(Drawable rightImg, View.OnClickListener onClickListener)
  {
    if (rightImg != null)
    {
      mRightImageView.setImageDrawable(rightImg);
      mRightImageView.setVisibility(View.VISIBLE);
      mRightImageView.setOnClickListener(onClickListener);
    }
    else
    {
      mRightImageView.setVisibility(View.GONE);
    }

    return this;
  }

}

