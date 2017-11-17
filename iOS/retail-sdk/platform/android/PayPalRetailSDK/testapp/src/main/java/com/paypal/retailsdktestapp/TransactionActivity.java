package com.paypal.retailsdktestapp;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.IdRes;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.crashlytics.android.Crashlytics;
import com.paypal.paypalretailsdk.Card;
import com.paypal.paypalretailsdk.DeviceManager;
import com.paypal.paypalretailsdk.DeviceUpdate;
import com.paypal.paypalretailsdk.Invoice;
import com.paypal.paypalretailsdk.InvoiceAddress;
import com.paypal.paypalretailsdk.ManuallyEnteredCard;
import com.paypal.paypalretailsdk.Merchant;
import com.paypal.paypalretailsdk.NetworkRequest;
import com.paypal.paypalretailsdk.NetworkResponse;
import com.paypal.paypalretailsdk.Page;
import com.paypal.paypalretailsdk.PaymentDevice;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.RetailSDKException;
import com.paypal.paypalretailsdk.SdkCredential;
import com.paypal.paypalretailsdk.TransactionBeginOptions;
import com.paypal.paypalretailsdk.TransactionContext;
import com.paypal.paypalretailsdk.TransactionRecord;
import com.paypal.paypalretailsdk.pph.PPHMerchant;
import com.paypal.paypalretailsdk.pph.PPHMerchantCardSettings;
import com.paypal.paypalretailsdk.pph.PPHMerchantStatus;
import com.paypal.paypalretailsdk.pph.PPHMerchantUserInfo;
import com.paypal.retailsdktestapp.login.LoginScreenActivity;
import com.paypal.retailsdktestapp.utils.StringUtil;

import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

import java.math.BigDecimal;
import java.util.Arrays;

import io.fabric.sdk.android.Fabric;

@EActivity
public class TransactionActivity extends ActionBarActivity
{
  private final static String logComponent = "TransactionActivity";
  private DeviceManager mDeviceManager;
  public static final String PREFS_NAME = "RetailSdkTestAppPreferences";
  public static final String PREF_TOKEN_KEY_NAME = "lastToken";
  public static SdkCredential credential;

  @ViewById
  TextView statusText;

  @ViewById
  Button chargeButton;

  @ViewById
  EditText amountField;

  @ViewById
  EditText gratuityField;

  @ViewById
  CheckBox testModeCheckBox;

  @ViewById
  CheckBox quickChipCheckBox;

  @ViewById
  Button refundButton;


  @ViewById
  RadioGroup paymentOptionsGroup;

  @ViewById
  RadioButton auth;

  @ViewById
  RadioButton cardPresent;

  @ViewById
  RadioButton cardReader;

  @ViewById
  RadioButton cash;

  @ViewById
  RadioButton check;

  @ViewById
  RadioButton keyin;

  @ViewById
  TextView ccNumberText;

  @ViewById
  TextView cvvText;

  @ViewById
  TextView expText;

  TransactionContext currentTransaction;
  Merchant currentMerchant;
  Invoice invoiceForRefund;

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    Fabric.with(this, new Crashlytics());
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
    setContentView(R.layout.transaction_activity);
    statusText.setText("Initializing SDK");
    try
    {
      RetailSDK.initialize(this, new RetailSDK.AppState()
      {
        @Override
        public Activity getCurrentActivity()
        {
          return TransactionActivity.this;
        }


        @Override
        public boolean getIsTabletMode()
        {
          return false;
        }
      });
      // credential = new SdkCredential("stage2d0065", "A23AAGz47nUrd-a3z1SXAtp5n9pq8z43mhHeRpl_e2fKGZ5Bk8h2uMpT3fWUHD8OdqEC0GyOJZKgkysSdr8kgM8_kOGgX0Mpg", "production");
      String mEnvironment = getIntent().getStringExtra("environment");
      String mAccessToken = getIntent().getStringExtra("accessToken");
      String mSwRepo = getIntent().getStringExtra("swRepo");
      if(com.paypal.paypalretailsdk.readers.common.StringUtil.isEmpty(mSwRepo))
      {
        mSwRepo = "production"; // Default Sw Repo = production
      }
      if (StringUtil.isNotEmpty(mAccessToken) && StringUtil.isNotEmpty(mEnvironment) && StringUtil.isNotEmpty(mSwRepo)) {
        credential = new SdkCredential(mEnvironment, mAccessToken, mSwRepo);
      }
      if (credential != null) {
        initializeMerchant(credential);
      } else {
        String token = getIntent().getStringExtra("token");
        //Read the saved token... if available, use that...
        initializeMerchant(token, mSwRepo);
      }
      RetailSDK.addDeviceDiscoveredObserver(new DeviceDiscoveredObserver());
      mDeviceManager = RetailSDK.getDeviceManager();
      Log.d(logComponent, "Connected devices: " + mDeviceManager.getDiscoveredDevices().size());
      if (mDeviceManager.getDiscoveredDevices().size() > 0) {
        PaymentDevice device = mDeviceManager.getDiscoveredDevices().get(0);
        device.addConnectedObserver(new DeviceConnectedObserver(device));
        device.addUpdateRequiredObserver(_updateRequiredObserver);
        device.connect(true);
      }

      RetailSDK.setNetworkInterceptor(new RetailSDK.NetworkInterceptorCallback() {
        @Override
        public void networkInterceptor(NetworkRequest request) {
          request.continueWithResponse(null, false, new NetworkResponse());
        }
      });
      RetailSDK.addPageViewedObserver(new RetailSDK.PageViewedObserver() {
        @Override
        public void pageViewed(RetailSDKException error, Page page) {
          Log.d("PageViewTracker", page.getName() + (StringUtil.isNotEmpty(page.getAction()) ? ", action:'" + page.getAction() + "'" : ""));
        }
      });
      statusText.setText("SDK Initialized");
//      credential = new SdkCredential("live", "-", "production");
//      if (credential != null) {
//        initializeMerchant(credential);
//      } else {
//        String token = getIntent().getStringExtra("token");
//        //Read the saved token... if available, use that...
//        initializeMerchant(token, "production");
//      }
    } catch (Exception x) {
      try {
        statusText.setText(x.toString());
      } catch (Exception ignore) {
        ignore.printStackTrace();
      }
      x.printStackTrace();
    }

    //Enable disable keyin text fields based on selected radio button
    paymentOptionsGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(RadioGroup radioGroup, @IdRes int checkedID) {
        boolean enableKeyInData = checkedID == R.id.keyin ? true : false;
        ccNumberText.setEnabled(enableKeyInData);
        cvvText.setEnabled(enableKeyInData);
        expText.setEnabled(enableKeyInData);
      }
    });
  }

  @UiThread
  void onDeviceDiscovered(final PaymentDevice device) {
    try {
      Toast.makeText(TransactionActivity.this, "Discovered" + device.getId(), Toast.LENGTH_SHORT).show();
    } catch(Exception ex) {
      Log.e(logComponent, ex.toString());
    }
    device.addConnectedObserver(new DeviceConnectedObserver(device));
    device.addUpdateRequiredObserver(_updateRequiredObserver);
    device.connect(true);
  }

  @UiThread
  void onDeviceConnected(PaymentDevice device) {
    try {
      Toast.makeText(TransactionActivity.this, "Successfully connected to " + device.getId(), Toast.LENGTH_LONG).show();
    } catch(Exception ex) {
      Log.e(logComponent, ex.toString());
    }
  }

  private class DeviceDiscoveredObserver implements RetailSDK.DeviceDiscoveredObserver {

    @Override
    public void deviceDiscovered(final PaymentDevice device) {
      onDeviceDiscovered(device);
    }
  }

  private class DeviceConnectedObserver implements PaymentDevice.ConnectedObserver {

    PaymentDevice _device;
    DeviceConnectedObserver(PaymentDevice device) {
      _device = device;
    }

    @Override
    public void connected() {
      onDeviceConnected(_device);
    }
  }

  private PaymentDevice.UpdateRequiredObserver _updateRequiredObserver = new PaymentDevice.UpdateRequiredObserver()
  {
    @Override
    public void updateRequired(DeviceUpdate update)
    {
      update.offer(new DeviceUpdate.CompletedCallback()
      {
        @Override
        public void completed(RetailSDKException error, final Boolean deviceUpgraded)
        {
          runOnUiThread(new Runnable()
          {
            @Override
            public void run()
            {
              statusText.setText("Update complete. Was upgraded: " + deviceUpgraded);
            }
          });
        }
      });
    }
  };

  public void onResume() {
    super.onResume();  // Always call the superclass method first
    Log.d("#### onResume", "Resume TransactionActivity.");
    RetailSDK.sContext = this;
  }


  @Override
  protected void onPause()
  {
    super.onPause();
  }


  @Override
  protected void onDestroy()
  {
    super.onDestroy();
    Log.d("#### onDestroy", "Destroy TransactionActivity.");
    RetailSDK.endCardReaderDiscovery();
  }

  @Override
  public void onBackPressed() {
    Intent i = new Intent(this, LoginScreenActivity.class);
    i.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
    startActivity(i);
  }

  private void saveToken(String token){
    SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
    SharedPreferences.Editor editor = settings.edit();
    editor.putString(PREF_TOKEN_KEY_NAME, token);
    editor.commit();
  }

  private void initializeMerchant(final SdkCredential credential) {
    try {
      statusText.setText("Initializing merchant");
      RetailSDK.initializeMerchant(credential, new RetailSDK.MerchantInitializedCallback() {
        @Override
        public void merchantInitialized(RetailSDKException error, Merchant merchant) {
          TransactionActivity.this.merchantReady(error, merchant);
          RetailSDK.beginCardReaderDiscovery();
        }
      });
    } catch (Exception x) {
      try {
        statusText.setText(x.toString());
      } catch (Exception ignore) {
        ignore.printStackTrace();
      }
      x.printStackTrace();
    }
  }

  private void initializeMerchant(final String token, String repository) {
    try {
      statusText.setText("Initializing merchant");
      RetailSDK.initializeMerchant(token, repository, new RetailSDK.MerchantInitializedCallback() {
        @Override
        public void merchantInitialized(RetailSDKException error, Merchant merchant) {
          saveToken(token);
          TransactionActivity.this.merchantReady(error, merchant);
          RetailSDK.beginCardReaderDiscovery();
        }
      });
    } catch (Exception x) {
      try {
        statusText.setText(x.toString());
      } catch (Exception ignore) {
        ignore.printStackTrace();
      }
      x.printStackTrace();
    }
  }

  private void initializeMerchant() {
    try {
      statusText.setText("Initializing merchant");
      InvoiceAddress address = new InvoiceAddress();
      address.setLine1("114 C Street 42104 12th Street");
      address.setCity("Irvine");
      address.setState("CA");
      address.setCountry("US");
      address.setPostalCode("92602");

      PPHMerchantUserInfo userInfo = new PPHMerchantUserInfo(
              "Ryan Merchant",
              "Ryan",
              "Merchant",
              "sathya-us@paypal.com",
              "Arts",
              "ARTSANDCRAFTS-Painting",
              address);

      PPHMerchantCardSettings cardSettings = new PPHMerchantCardSettings(
              "1",
              "10000",
              "50",
              Arrays.asList(new String[]{"discover_contactless", "amex_contactless"}));
      PPHMerchantStatus status = new PPHMerchantStatus(
              "Ready",
              Arrays.asList(new String[]{"tab", "key", "card"}),
              cardSettings,
              "USD",
              true);

      PPHMerchant merchant = new PPHMerchant(credential, userInfo, status);
      RetailSDK.InitializeMerchant(merchant, new RetailSDK.MerchantInitializedCallback() {
        @Override
        public void merchantInitialized(RetailSDKException error, Merchant merchant) {
          TransactionActivity.this.merchantReady(error, merchant);

        }
      });
    } catch (Exception x) {
      try {
        statusText.setText(x.toString());
      } catch (Exception ignore) {
        ignore.printStackTrace();
      }
      x.printStackTrace();
    }
  }



  @Override
  public void onConfigurationChanged(Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
  }

  @UiThread
  void merchantReady(RetailSDKException error, Merchant merchant) {
    if (error != null) {
      statusText.setText(error.toString());
    } else {
      currentMerchant = merchant;
      statusText.setText(String.format("Ready for %s", merchant.getEmailAddress()));
      chargeButton.setEnabled(true);
    }
  }

  @Click(R.id.chargeButton)
  void chargeClicked() {
    chargeButton.setEnabled(false);
    invoiceForRefund = null;
    refundButton.setEnabled(false);

    boolean isCertMode = testModeCheckBox.isChecked();
    currentMerchant.setIsCertificationMode(isCertMode);
    Invoice invoice = new Invoice(null);
    invoice.addItem("Item", new BigDecimal(1), new BigDecimal(amountField.getText().toString()), 1, null);
    BigDecimal gratuityAmt = new BigDecimal(gratuityField.getText().toString());
    if(gratuityAmt.intValue() > 0){
      invoice.setGratuityAmount(gratuityAmt);
    }
    currentTransaction = RetailSDK.createTransaction(invoice);
    currentTransaction.setCompletedHandler(new TransactionContext.TransactionCompletedCallback() {
      @Override
      public void transactionCompleted(RetailSDKException error, TransactionRecord record) {
        TransactionActivity.this.transactionCompleted(error, record);
      }
    });

    statusText.setText("Ready for payment.");
    TransactionBeginOptions options = new TransactionBeginOptions();
    options.setShowPromptInCardReader(true);
    options.setShowPromptInApp(true);
    options.setQuickChipEnabled(quickChipCheckBox.isChecked());
    options.setIsAuthCapture(auth.isChecked());
    currentTransaction.beginPaymentWithOptions(options);
    final Handler handler = new Handler();
    if (cash.isChecked()) {
      handler.postDelayed(new Runnable() {
        @Override
        public void run() {
          currentTransaction.continueWithCash();
        }
      }, 2000);

    } else if (check.isChecked()) {
      handler.postDelayed(new Runnable() {
            @Override
            public void run() {
              currentTransaction.continueWithCheck();
            }
          }, 2000);
    } else if (keyin.isChecked()) {
      handler.postDelayed(new Runnable() {
        @Override
        public void run() {
          ManuallyEnteredCard card = new ManuallyEnteredCard();
          card.setCardNumber(ccNumberText.getText().toString());
          card.setCVV(cvvText.getText().toString());
          card.setExpiration(expText.getText().toString());
          currentTransaction.continueWithCard(card);
        }
      }, 2000);
    }
  }

  @Click(R.id.refundButton)
  void refundClicked() {
    if(null == invoiceForRefund || invoiceForRefund.getPayments().size()<1)
    {
      return;
    }

    processRefund(amountField.getText().toString(), cardPresent.isChecked());
  }
  protected void processRefund(String amount, Boolean cardPresent){
    RetailSDK.setCurrentApplicationActivity(this);
    statusText.setText("Processing refund... Thread: "+ Thread.currentThread().toString());
    currentTransaction = RetailSDK.createTransaction(invoiceForRefund);
    currentTransaction.setCompletedHandler(new TransactionContext.TransactionCompletedCallback() {
      @Override
      public void transactionCompleted(RetailSDKException error, TransactionRecord record) {
        TransactionActivity.this.refundCompleted(error, record);
      }
    });
    if(cardPresent) {
      currentTransaction.beginRefund(true, new BigDecimal(amount));
    } else {
      TransactionContext noCardTransaction =  currentTransaction.beginRefund(false, new BigDecimal(amount));
      //ToDo: modify gen to generate nowait for continueWithCard
      //ToDo: check the windows code
      noCardTransaction.continueWithCard(null);
    }
  }

  private void refundCompleted(RetailSDKException error, TransactionRecord record) {
    if (error != null) {
      final String errorTxt = error.toString();
      this.runOnUiThread(new Runnable() {
        @Override
        public void run() {
          statusText.setText(errorTxt);
        }
      });

    } else {
      invoiceForRefund = currentTransaction.getInvoice();
      final String txnNumber = record.getTransactionNumber();
      this.runOnUiThread(new Runnable() {
        @Override
        public void run() {
          statusText.setText(String.format("Completed refund for Transaction %s", txnNumber));
          chargeButton.setEnabled(true);
          refundButton.setEnabled(true);
        }
      });
    }
  }

  void loginClicked(){
    saveToken("");
    Intent loginIntent = new Intent(this, LoginScreenActivity.class);
    startActivity(loginIntent);
    finish();
  }


  @UiThread
  void cardWasPresented(Card card) {
    statusText.setText("Card presented.");
  }

  @UiThread
  void transactionCompleted(RetailSDKException error, TransactionRecord record) {
    if (error != null) {
      final String errorTxt = error.toString();
      this.runOnUiThread(new Runnable() {
        @Override
        public void run() {
          statusText.setText(errorTxt);
          refundButton.setEnabled(false);
        }
      });
    } else {
      invoiceForRefund = currentTransaction.getInvoice();
      final String recordTxt =  record.getTransactionNumber();
      this.runOnUiThread(new Runnable() {
        @Override
        public void run() {
          refundButton.setEnabled(!auth.isChecked());
          statusText.setText(String.format("Completed Transaction %s", recordTxt));
        }
      });
    }
    chargeButton.setEnabled(true);
  }

  @Override
  public boolean onCreateOptionsMenu(Menu menu)
  {
    // Inflate the menu; this adds items to the action bar if it is present.
    getMenuInflater().inflate(R.menu.menu_transaction, menu);
    return true;
  }


  @Override
  public boolean onOptionsItemSelected(MenuItem item)
  {
    // Handle action bar item clicks here. The action bar will
    // automatically handle clicks on the Home/Up button, so long
    // as you specify a parent activity in AndroidManifest.xml.
    int id = item.getItemId();

    //noinspection SimplifiableIfStatement
    if (id == R.id.action_testAlert)
    {
      return true;
    }

    if(id == R.id.action_login){
      loginClicked();
      return true;
    }

    if(id == R.id.action_listAuth) {
      listOfAuthClicked();
      return true;
    }

    return super.onOptionsItemSelected(item);
  }

  void listOfAuthClicked() {
    Intent listAuthIntent = new Intent(this, AuthActivity_.class);
    startActivity(listAuthIntent);
  }

}
