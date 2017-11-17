package com.paypal.paypalretailsdk.ui.receipt;

import java.lang.ref.WeakReference;
import java.util.List;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.content.res.Resources;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import com.paypal.paypalretailsdk.R;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class ReceiptOptionsActivity extends RetailSDKBaseActivity
{

    private TextView mActionBarTitle;
    private TextView mMessage;
    private TextView mEmailButton;
    private TextView mTextButton;
    private ImageView mIcon;
    private ImageView mEditEmailButton;
    private ImageView mEditTextButton;
    private String mMaskedEmail;
    private String mMaskedPhoneNumber;
    private TextView mSendButton;

    @Override
    public void initComponents(Bundle savedInstanceState) {

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        final boolean isTabletMode = RetailSDK.getAppState().getIsTabletMode();
        if (!isTabletMode) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }
        setContentView(R.layout.sdk_receipt_options_screen_template);
        ScrollView content = (ScrollView) findViewById(R.id.content);

        View layout = getLayoutInflater().inflate(R.layout.sdk_activity_receipt_options_retail, null);
        content.addView(layout);

        mActionBarTitle = (TextView) findViewById(R.id.ab_title);
        mIcon = (ImageView) findViewById(R.id.ab_status);

        mMessage = (TextView) findViewById(R.id.payment_complete_msg_retail);

        mEmailButton = (TextView) findViewById(R.id.id_email_button_retail);
        mEmailButton.setText(getResources().getString(R.string.sdk_actvy_receipt_option_email));
        mEmailButton.setOnClickListener(new SendToButtonClickListener(SendReceiptTo.Email, this));

        mTextButton = (TextView) findViewById(R.id.id_text_button_retail);
        mTextButton.setText(getResources().getString(R.string.sdk_actvy_receipt_option_text));
        mTextButton.setOnClickListener(new SendToButtonClickListener(SendReceiptTo.Sms, this));

        mEditEmailButton = (ImageView) findViewById(R.id.id_change_receipt_email_retail);
        mEditEmailButton.setVisibility(View.GONE);
        mEditEmailButton.setOnClickListener(new EditReceiptDestination(SendReceiptTo.Email, this));

        mEditTextButton = (ImageView) findViewById(R.id.id_change_receipt_text_retail);
        mEditTextButton.setOnClickListener(new EditReceiptDestination(SendReceiptTo.Sms, this));
        mEditTextButton.setVisibility(View.GONE);

        mSendButton = (TextView)findViewById(R.id.receipt_ab_right_button);
        mSendButton.setVisibility(View.INVISIBLE);
    }

    @Override
    protected RetailSDKBasePresenter getPresenter() {
        return ReceiptOptionsPresenter.getInstance();
    }

    void setTitleText(final String title) {
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
        mActionBarTitle.setText(title);
            }
        });
    }

    void setMessage(final String message) {
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
        mMessage.setText(message);
            }
        });
    }

    void addMaskedEmail(final String maskedEmail) {
        mMaskedEmail = maskedEmail;
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
                mEmailButton.setText(mMaskedEmail);
                mEditEmailButton.setVisibility(View.VISIBLE);
            }
        });
    }

    void addMaskedPhone(final String maskedPhone) {
        mMaskedPhoneNumber = maskedPhone;
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
                mTextButton.setText(mMaskedPhoneNumber);
                mEditTextButton.setVisibility(View.VISIBLE);
            }
        });
    }

    void setEmailButtonTitle(final String emailTitle) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mTextButton.setText(emailTitle);
            }
        });
    }

    void setPhoneButtonTitle(final String phoneTitle) {
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
                mTextButton.setText(phoneTitle);
            }
        });
    }

    void setTitleIcon(final String titleIcon) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Resources resources = getResources();
                final int resourceId = resources.getIdentifier(titleIcon, "drawable",
                        getPackageName());
                mIcon.setBackgroundResource(resourceId);
            }
        });
    }

    void addButton(final String btnText, final ReceiptOptionCallback callback) {

        LinearLayout linearLayout = (LinearLayout) findViewById(R.id.id_options_layout_retail);
        if (null == linearLayout) {
            return;
        }

        LayoutInflater inflater = LayoutInflater.from(this);
        View view = inflater.inflate(R.layout.sdk_layout_receipt_options_item, null);
        TextView textView = (TextView) view.findViewById(R.id.id_receipt_options_button);

        textView.setText(btnText);

        textView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != callback) {
                    callback.onOptionSelected(ReceiptOptionsActivity.this);
                }

            }
        });

        linearLayout.addView(view);
    }

    void createAdditionalOptionsButtons(final List<String> additionalReceiptOptions) {
        if (additionalReceiptOptions != null) {
            for (final String item : additionalReceiptOptions) {
                addButton(item, new ReceiptOptionCallback() {
                    @Override
                    public void onOptionSelected(Activity activity) {
                        ReceiptOptionsPresenter.getInstance().additionalReceiptOptionCallback(additionalReceiptOptions.indexOf(item), item);
                    }
                });
            }
        }
    }

    void addNoReceiptButton(String btnText) {
        addButton(btnText != null && !btnText.isEmpty() ? btnText : getString(R.string.sdk_actvy_receipt_option_no_receipt), new ReceiptOptionCallback() {
            @Override
            public void onOptionSelected(Activity activity) {
                ReceiptOptionsPresenter.getInstance().sendReceipt(null);
            }
        });
    }

    @Override
    protected void onDestroy()
    {
        mEditEmailButton.setOnClickListener(null);
        mEditTextButton.setOnClickListener(null);
        mEmailButton.setOnClickListener(null);
        mTextButton.setOnClickListener(null);
        super.onDestroy();
    }


    private static class SendToButtonClickListener implements View.OnClickListener {

        private final WeakReference<ReceiptOptionsActivity> _activityWeakReference;
        private SendReceiptTo mSendTo;

        SendToButtonClickListener(SendReceiptTo sendTo, ReceiptOptionsActivity receiptOptionsActivity) {
            mSendTo = sendTo;
            _activityWeakReference = new WeakReference<ReceiptOptionsActivity>(receiptOptionsActivity);
        }

        @Override
        public void onClick(View v) {
            if(mSendTo == SendReceiptTo.Email) {
                if(_activityWeakReference.get().mMaskedEmail == null || _activityWeakReference.get().mMaskedEmail.isEmpty()) {
                    ReceiptOptionsPresenter.getInstance().openReceiptSendToActivity(mSendTo);
                } else {
                    ReceiptOptionsPresenter.getInstance().sendReceipt(_activityWeakReference.get().mMaskedEmail);
                }
            } else {
                if(_activityWeakReference.get().mMaskedPhoneNumber == null || _activityWeakReference.get().mMaskedPhoneNumber.isEmpty()) {
                    ReceiptOptionsPresenter.getInstance().openReceiptSendToActivity(mSendTo);
                } else {
                    ReceiptOptionsPresenter.getInstance().sendReceipt(_activityWeakReference.get().mMaskedPhoneNumber);
                }
            }
        }
    }

    private static class EditReceiptDestination implements View.OnClickListener {

        private final WeakReference<ReceiptOptionsActivity> _activityWeakReference;
        private SendReceiptTo mSendTo;

        EditReceiptDestination(SendReceiptTo sendTo, ReceiptOptionsActivity receiptOptionsActivity) {
            _activityWeakReference = new WeakReference<ReceiptOptionsActivity>(receiptOptionsActivity);
            mSendTo = sendTo;
        }

        @Override
        public void onClick(View v) {
            ReceiptOptionsPresenter.getInstance().openReceiptSendToActivity(mSendTo);
        }
    }

    public interface ReceiptOptionCallback {
        void onOptionSelected(Activity activity);
    }


    @Override
    public void onBackPressed()
    {

    }
}