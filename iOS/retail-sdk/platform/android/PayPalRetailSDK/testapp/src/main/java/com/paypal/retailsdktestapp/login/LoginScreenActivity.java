/**
 * PayPalHereSDK
 * <p/>
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */

package com.paypal.retailsdktestapp.login;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Bundle;
import android.text.InputType;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.crashlytics.android.Crashlytics;
import com.paypal.retailsdktestapp.R;
import com.paypal.retailsdktestapp.TransactionActivity;
import com.paypal.retailsdktestapp.utils.CommonUtils;
import com.paypal.retailsdktestapp.utils.StringUtil;

import io.fabric.sdk.android.Fabric;

/**
 * This activity acts as the login screen that enables users to log in to the app. Steps to login include:
 * 1. Selecting a suitable server to connect to.
 * 2. Performing an OAuth login (handled in the activity: OAuthLoginActivity.java).
 */
public class LoginScreenActivity extends Activity {

    private static final String LOG_TAG = LoginScreenActivity.class.getSimpleName();
  private static final String DEFAULT_USERNAME = "pphan-us-b10@paypal.com";
  private static final String DEFAULT_PASSWORD = "11111111";
  private static final String DEFAULT_ENVIRONMENT = "stage2d0084";
  private static final String DEFAULT_REPO = "qa-stage-1";
    private String mUsername;
    private EditText mUserNameEditBox;
    private EditText mPasswordEditBox;
    private EditText mTokenEditBox;
  private EditText mEnvironmentBox;
  private EditText mAccessTokenBox;
  private EditText mSwRepoBox;
    private String mPassword;
    private String mToken;
  private String mAccessToken;
  private String mEnvironment;
  private String mSwRepo;
    private Button mLoginButton;
    private ProgressBar mProgressBar;
    private TextView mEnv;
    private TextView mBuildNumber;
    private String mServerName;
    private static SharedPreferences mSharedPrefs;

    /**
     * initialize the various layout elements.
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Fabric.with(this, new Crashlytics());
        // Restore preferences
        SharedPreferences settings = getSharedPreferences(TransactionActivity.PREFS_NAME, 0);
        String token = settings.getString(TransactionActivity.PREF_TOKEN_KEY_NAME, "");
        token = "stage2d0083:WyJBMTAzLnRpNnNBVm1YNW9XcDZ3eWhVVjh5RlZVeTJvcjh3NXlRVXB3S0VNZHAwWnQtR3VqS2QxZS1ZRE04YTlLTDltbWIuMWIwc29xald6MWxfZnIyMHRNZVZwSDFWUDhtIiwyODgwMCxudWxsLCJEMTAzLnR1ZnJFUHU1VE8wc1N5cWtSZF9WclFpYzdUR2R0dmhUdmZYdnR0RDc1dXMuRDdIMWUxX2c3b0duUjQ0QWM4SWU4dWZNMUdpIiwiY0hCb0xYUmxjM1F5T25Cd2FDMTBaWE4wTWc9PSJd";
    //if(StringUtil.isNotEmpty(token)){
    //    OAuthLoginActivity.proceedToMainActivity(this, token);
    //    return;
    //}
        setContentView(R.layout.activity_login_screen);

        mUserNameEditBox = (EditText) findViewById(R.id.username);
        mPasswordEditBox = (EditText) findViewById(R.id.password);
        mTokenEditBox = (EditText) findViewById(R.id.token);
    mEnvironmentBox = (EditText) findViewById(R.id.environment);

    mAccessTokenBox = (EditText) findViewById(R.id.accessToken);
    mAccessTokenBox.setVisibility(View.GONE);



    mSwRepoBox = (EditText) findViewById(R.id.swRepo);
        mEnv = (TextView) findViewById(R.id.env);
        mBuildNumber = (TextView) findViewById(R.id.app_build_number);

        mProgressBar = (ProgressBar) findViewById(R.id.login_progress);
        mProgressBar.setVisibility(View.GONE);

        mLoginButton = (Button) findViewById(R.id.login);
        mLoginButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View arg) {
                mUsername = mUserNameEditBox.getText().toString();
                mPassword = mPasswordEditBox.getText().toString();
        //mToken = mTokenEditBox.getText().toString();
        mEnvironment = mEnvironmentBox.getText().toString();
        mSwRepo = mSwRepoBox.getText().toString();
                if (!isValidInput()) {
                    Toast.makeText(LoginScreenActivity.this, R.string.invalid_user_credentials, Toast.LENGTH_SHORT).show();
                    return;
                }
                storeLoginInfo();
                performOAuthLogin(arg);
            }
        });

        mLoginButton.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                Intent i = new Intent(LoginScreenActivity.this, StageSelectActivity.class);
                startActivity(i);
                return true;
            }
        });

        CommonUtils.applicationContext = this.getApplicationContext();
        setLastKnownValues();
        updateConnectedEnvUI();
    }

    private void setLastKnownValues() {
        mServerName = CommonUtils.getStoredServer(this);
        if (null == mServerName || mServerName.length() <= 0) {
            mServerName = CommonUtils.kSandboxService;
        }
        CommonUtils.setStage(this, mServerName);
    }

    private void updateConnectedEnvUI() {
        mServerName = CommonUtils.getCurrentServer();
        if (null != mServerName) {
            mEnv.setText(mServerName);
        }

        mUserNameEditBox.setHint(R.string.username_hint);
        mPasswordEditBox.setHint(R.string.password_hint);
        mUserNameEditBox.setInputType(InputType.TYPE_CLASS_TEXT);
        mPasswordEditBox.setInputType(InputType.TYPE_TEXT_VARIATION_PASSWORD);

        String lastGoodUsername = CommonUtils.getStoredUsername(this);
        if (lastGoodUsername != null) {
            mUserNameEditBox.setText(lastGoodUsername);
    } else {
      mUserNameEditBox.setText(DEFAULT_USERNAME);
    }
    String lastEnvironment = CommonUtils.getStoredLoginEnvironment(this);
    if (lastEnvironment != null)
    {
      mEnvironmentBox.setText(lastEnvironment);
    } else {
      mEnvironmentBox.setText(DEFAULT_ENVIRONMENT);
    }
    String lastRepo = CommonUtils.getStoredSwRepo(this);
    if (lastRepo != null)
    {
      mSwRepoBox.setText(lastRepo);
    } else {
      mSwRepoBox.setText(DEFAULT_REPO);
    }
        fillPassword();

        mBuildNumber.setText("" + CommonUtils.getBuildNumber(LoginScreenActivity.this));
    }

    private void storeLoginInfo() {
        String userName = mUserNameEditBox.getText().toString();
        CommonUtils.saveUsername(this, userName);
    CommonUtils.saveLoginEnvironment(this, mEnvironmentBox.getText().toString());
    CommonUtils.saveSwRepo(this, mSwRepo);
    }

    /**
     * Method to move into the OAuth login activity.
     *
     * @param arg
     */
    private void performOAuthLogin(View arg) {
        hideKeyboard(arg);
        if (StringUtil.isNotEmpty(mToken)) {
      OAuthLoginActivity.proceedToMainActivity(this, mToken, mSwRepo);
        } else {
      if (StringUtil.isNotEmpty(mEnvironment) && StringUtil.isNotEmpty(mSwRepo))
      {
        OAuthLoginActivity.authAndProceedToMainActivity(this, mUsername,mPassword,mEnvironment, mSwRepo);
      }
      else
      {
        // Pass the username and password to the OAuth login activity for OAuth login.
        // Once the login is successful, we automatically check in the merchant in the OAuth activity.
        Intent intent = new Intent(LoginScreenActivity.this, OAuthLoginActivity.class);
        intent.putExtra("username", mUsername);
        intent.putExtra("password", mPassword);
        intent.putExtra("servername", mServerName);
        intent.putExtra("swRepo", mSwRepo);
        startActivity(intent);
        finish();
      }
    }
  }

    /**
     * Method to valid the input for null or empty.
     *
     * @return
     */
  private boolean isValidInput()
  {
    return StringUtil.isNotEmpty(mEnvironment) && StringUtil.isNotEmpty(mSwRepo) && StringUtil.isNotEmpty(mUsername) && StringUtil.isNotEmpty(mPassword) ;
  }


    /**
     * Method to hide the keyboard.
     *
     * @param v
     */
    private void hideKeyboard(View v) {
        InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(v.getWindowToken(), 0);

    }

    /**
     * Method to set the username and password to a default value.
     */
    //TODO: need to remove this before shipping the app to public
  private void fillPassword()
  {
  mPasswordEditBox.setText(DEFAULT_PASSWORD);
  }

    /**
     * This method is needed to make sure nothing is invoked/called when the
     * orientation of the phone is changed.
     */
    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateConnectedEnvUI();
    }
}
