package com.paypal.paypalretailsdk.ui.receipt;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.content.res.Resources;
import android.os.Bundle;
import android.text.InputType;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.animation.AnimationUtils;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class ReceiptSendToActivity extends RetailSDKBaseActivity implements OnClickListener {

    private ImageView mReceiptTypeIcon;
    private ImageView mBackButton;
    private TextView mTitle;
    private EditText mDestination;
    private TextView mDisclaimer;
    private Button mSendButton;
    private static final String LOG_TAG = ReceiptSendToActivity.class.getSimpleName();

    private String destinationType = "";
    boolean isValid = false;

    @Override
    protected RetailSDKBasePresenter getPresenter() {
        return ReceiptSendToPresenter.getInstance();
    }

    @Override
    public void initComponents(Bundle savedInstanceState) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        final boolean isTabletMode = RetailSDK.getAppState().getIsTabletMode();
        if (!isTabletMode) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }

        setContentView(R.layout.sdk_receipt_send_to_template);
        ScrollView content = (ScrollView) findViewById(R.id.content);
        View layout = getLayoutInflater().inflate(R.layout.sdk_activity_receipt_sent_to, null);
        content.addView(layout);

        findViewById(R.id.ab_status).setVisibility(View.INVISIBLE);
        mBackButton = (ImageView)findViewById(R.id.receipt_ab_back);
        mBackButton.setVisibility(View.VISIBLE);
        mTitle = (TextView)findViewById(R.id.ab_title);
        mDestination = (EditText) findViewById(R.id.send_location);
        mReceiptTypeIcon = (ImageView)findViewById(R.id.receipt_type_icon);
        mDisclaimer = (TextView)findViewById(R.id.receipts_disclaimer);
        mSendButton = (Button) findViewById(R.id.receipt_ab_right_button);
        mSendButton.setVisibility(View.VISIBLE);

        mSendButton.setOnClickListener(this);
        mBackButton.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        if(view.getId() == R.id.receipt_ab_right_button) {
            if(validateInputs())
            {
                hideSoftKeyboard();
                ReceiptSendToPresenter.getInstance().sendReceipt(mDestination.getText().toString());
            }
            else
            {
                animateErrors();
            }
            // Dont make the sendReceipt request
        }

        if(view.getId() == R.id.receipt_ab_back) {
            ReceiptSendToPresenter.getInstance().viewReceiptOptions();
        }

    }


    private void hideSoftKeyboard()
    {
        try
        {
            View currentView = this.getCurrentFocus();
            if (currentView != null) {
                InputMethodManager imm = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(currentView.getWindowToken(), 0);
            }
        }
        catch (Exception ex)
        {
            RetailSDK.logViaJs("warn", LOG_TAG, "Error on hiding soft-keyboard");
        }
    }


    void setReceiptTypeIcon(final String iconName) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Resources resources = getResources();
                final int resourceId = resources.getIdentifier(iconName, "drawable", getPackageName());
                mReceiptTypeIcon.setImageResource(resourceId);
            }
        });
    }

    void setEmailInputType() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mDestination.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
            }
        });
    }

    void setPhoneInputType() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mDestination.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_CLASS_PHONE);
            }
        });
    }

    public void setDestinationType(String destinationType)
    {
        this.destinationType = destinationType;
    }

    public String getDestinationType()
    {
        return this.destinationType;
    }

    private void animateErrors()
    {
        runOnUiThread(new Runnable()
        {
            @Override
            public void run()
            {
                mDestination.startAnimation(AnimationUtils.loadAnimation(ReceiptSendToActivity.this, R.anim.shake));
                isValid = false;
            }
        });
    }

    public boolean validateInputs()
    {
        if (getDestinationType().equalsIgnoreCase(SendReceiptTo.Email.toString()))
        {
            return ((ReceiptSendToPresenter.getInstance().validateEmail(mDestination.getText().toString())));
        }
        else if (getDestinationType().equalsIgnoreCase(SendReceiptTo.Sms.toString()))
        {
            return ((ReceiptSendToPresenter.getInstance().validatePhone(mDestination.getText().toString())));
        }
        return false;
    }

    void setTitle(final String title) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mTitle.setText(title);
            }
        });
    }

    void setSendButtonTitle(final String title) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mSendButton.setText(title);
            }
        });
    }

    void setDisclaimer(final String disclaimer) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mDisclaimer.setText(disclaimer);
            }
        });
    }

    @Override
    public void onBackPressed() {
        ReceiptSendToPresenter.getInstance().viewReceiptOptions();
    }
}
