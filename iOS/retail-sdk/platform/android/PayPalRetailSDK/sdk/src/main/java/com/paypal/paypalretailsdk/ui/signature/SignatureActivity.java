package com.paypal.paypalretailsdk.ui.signature;

import java.io.ByteArrayOutputStream;
import java.lang.ref.WeakReference;

import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Base64;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class SignatureActivity extends RetailSDKBaseActivity
{

  private SignatureCanvas mSignatureCanvas;
  private ImageView mClearSignature;
  private TextView mSignHereTextView;
  private TextView mDoneButton;
  private TextView mCancelButton;
  private TextView mAmountDetailsView;
  private TextView mFooterTextView;
  private boolean mCanHitDoneButton = true;


  @Override
  public void initComponents(Bundle savedInstanceState)
  {
    final boolean isTabletMode = RetailSDK.getAppState().getIsTabletMode();
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
    setContentView(R.layout.sdk_activity_signature_retail);

    mCancelButton = (TextView) findViewById(R.id.ab_left_button);
    mCancelButton.setText(getString(R.string.sdk_actvy_signature_cancel));
    mCancelButton.setVisibility(View.VISIBLE);

    mDoneButton = (TextView) findViewById(R.id.ab_right_button);
    mDoneButton.setText(getString(R.string.sdk_actvy_signature_done));
    mDoneButton.setVisibility(View.VISIBLE);
    mDoneButton.setEnabled(false);
    mDoneButton.setTextColor(getResources().getColor(R.color.sdk_button_disabled));

    mAmountDetailsView = (TextView) findViewById(R.id.ab_title);
    mSignHereTextView = (TextView) findViewById(R.id.sign_here_retail);
    mFooterTextView = (TextView) findViewById(R.id.id_agreement_txt_retail);
    mClearSignature = (ImageView) findViewById(R.id.id_cancel_sig_retail);
    mSignatureCanvas = (SignatureCanvas) findViewById(R.id.signature_retail);
    mSignatureCanvas.setSignatureListener(new MySignatureListener(this));
    mDoneButton.setOnClickListener(new DoneButtonListener(this));
    mClearSignature.setOnClickListener(new ClearSignatureListener(this));
    mCancelButton.setOnClickListener(new CancelButtonListener());
  }


  @Override
  protected RetailSDKBasePresenter getPresenter()
  {
    return SignaturePresenter.getInstance();
  }


  public void setTitleText(final String title)
  {
    runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        mAmountDetailsView.setText(title);
      }
    });
  }


  public void setWatermark(final String watermark)
  {
    runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        mSignHereTextView.setText(watermark);
      }
    });
  }


  public void setFooter(final String footer)
  {
    runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        mFooterTextView.setText(footer);
      }
    });
  }


  public void setCancelButtonText(final String cancel)
  {

    runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        mCancelButton.setText(cancel);
      }
    });
  }


  @Override
  public void onResume()
  {
    super.onResume();
  }


  @Override
  public void onBackPressed()
  {
    getPresenter().handleBackPressed();
  }


  private void signatureProvided()
  {
    mDoneButton.setEnabled(true);
    mDoneButton.setTextColor(Color.WHITE);
    mClearSignature.setVisibility(View.VISIBLE);
    mSignHereTextView.setVisibility(View.GONE);
  }


  private void clearSignature()
  {
    mDoneButton.setEnabled(false);
    mDoneButton.setTextColor(getResources().getColor(R.color.sdk_button_disabled));
    mClearSignature.setVisibility(View.GONE);
    mSignHereTextView.setVisibility(View.VISIBLE);
  }


  private static class CancelButtonListener implements View.OnClickListener
  {
    @Override
    public void onClick(View v)
    {
      SignaturePresenter.getInstance().cancelTransaction();
    }
  }


  private static class DoneButtonListener implements View.OnClickListener
  {
    private final WeakReference<SignatureActivity> _activityWeakReference;

    public DoneButtonListener(SignatureActivity signatureActivity)
    {
      _activityWeakReference = new WeakReference<SignatureActivity>(signatureActivity);
    }


    @Override
    public void onClick(View view)
    {
      if (_activityWeakReference.get().mCanHitDoneButton)
      {
        _activityWeakReference.get().mCanHitDoneButton = false;
        //ToDo: Can we get the stream without compress?
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        _activityWeakReference.get().mSignatureCanvas.getBitmap().compress(Bitmap.CompressFormat.WEBP, 50, stream);
        byte[] bytes = stream.toByteArray();
        String encoded = Base64.encodeToString(bytes, Base64.DEFAULT);
        SignaturePresenter.getInstance().onSignatureBitmapReceived(encoded);
      }
    }
  }


  private static class MySignatureListener implements SignatureCanvas.SignatureListener
  {
    private final WeakReference<SignatureActivity> _activityWeakReference;

    public MySignatureListener(SignatureActivity signatureActivity)
    {
      _activityWeakReference = new WeakReference<SignatureActivity>(signatureActivity);
    }



    @Override
    public void onSignaturePresent(boolean signature)
    {
      if (signature)
      {
        _activityWeakReference.get().signatureProvided();
      }
      else
      {
        _activityWeakReference.get().clearSignature();
      }
    }
  }


  private static class ClearSignatureListener implements View.OnClickListener
  {
    private final WeakReference<SignatureActivity> _activityWeakReference;

    public ClearSignatureListener(SignatureActivity signatureActivity)
    {
      _activityWeakReference = new WeakReference<SignatureActivity>(signatureActivity);
    }


    @Override
    public void onClick(View view)
    {
      _activityWeakReference.get().mSignatureCanvas.clear();
    }
  }


  public void setVisibilityOfCancelButton(boolean isVisible)
  {
    if (isVisible)
    {
      mCancelButton.setVisibility(View.VISIBLE);
      mCancelButton.setEnabled(true);
    }
    else
    {
      mCancelButton.setVisibility(View.GONE);
      mCancelButton.setEnabled(false);
    }
  }

  @Override
  protected void onDestroy()
  {
    mDoneButton.setOnClickListener(null);
    mCancelButton.setOnClickListener(null);
    mClearSignature.setOnClickListener(null);
    mSignatureCanvas = null;
    super.onDestroy();
  }
}

