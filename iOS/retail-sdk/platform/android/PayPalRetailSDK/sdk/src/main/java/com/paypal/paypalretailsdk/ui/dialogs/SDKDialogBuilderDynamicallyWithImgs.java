package com.paypal.paypalretailsdk.ui.dialogs;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.ContextThemeWrapper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;

import static android.view.Gravity.CENTER;

/**
 * Created by muozdemir on 12/22/16.
 */

public class SDKDialogBuilderDynamicallyWithImgs extends RetailAlertBuilder
{
  TextView mMessageView;
  LinearLayout mOptionView;

  public SDKDialogBuilderDynamicallyWithImgs(Context context)
  {
    super(new ContextThemeWrapper(context, R.style.DialogStyle));
    setCancelable(false);
  }


  public void setView(Context context)
  {
    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    view = inflater.inflate(R.layout.dialog_image_dynamic_buttons, null);
    mMessageView = (TextView) view.findViewById(R.id.dialog_message);
    mOptionView = (LinearLayout) view.findViewById(R.id.optionList);
    mOptionView.removeAllViews();
    setView(view);
  }

  public SDKDialogBuilderDynamicallyWithImgs addImgButton(Context context, final Drawable img, String id,
                                                          View.OnClickListener onClickListener)
  {
    LinearLayout ll = new LinearLayout(context);
    ll.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));
    ll.setOrientation(LinearLayout.HORIZONTAL);
    ll.setGravity(CENTER);

    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);

    ImageView iv = new ImageView(context);
    iv.setImageDrawable(img);
    iv.setVisibility(View.VISIBLE);

    Button btn = new Button(context);
    btn.setText(id);
    btn.setWidth(500);
    btn.setHeight(100);
    btn.setOnClickListener(onClickListener);

    ll.addView(iv, layoutParams);
    ll.addView(btn, layoutParams);

    mOptionView.addView(ll);

    return this;
  }


  @Override
  public AlertDialog.Builder setMessage(CharSequence message)
  {
    mMessageView.setText(message);
    return this;
  }

}
