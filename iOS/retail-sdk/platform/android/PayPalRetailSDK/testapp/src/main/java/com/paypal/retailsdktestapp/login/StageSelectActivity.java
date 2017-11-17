/**
 * PayPalHereSDK
 * <p/>
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */
package com.paypal.retailsdktestapp.login;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.res.Configuration;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.paypal.retailsdktestapp.R;
import com.paypal.retailsdktestapp.utils.CommonUtils;

public class StageSelectActivity extends Activity {
    private static final String LOG_TAG = StageSelectActivity.class.getSimpleName();

    private EditText mStageSelection;
    private Button mStageSelectButton;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(LOG_TAG, "onCreate IN");
        setContentView(R.layout.stage_selection);

        mStageSelection = (EditText)findViewById(R.id.id_stage_selection);

        mStageSelectButton = (Button)findViewById(R.id.id_stage_selection_button);
        mStageSelectButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(LOG_TAG, "Stage Select Button onClick");
                hideKeyboard();
                String stageName = mStageSelection.getText().toString();
                if (null == stageName || stageName.length() <= 0) {
                    Toast.makeText(StageSelectActivity.this, "Please enter the valid stage name", Toast.LENGTH_SHORT).show();
                    return;
                }
                CommonUtils.setStage(StageSelectActivity.this, stageName);
                Toast.makeText(StageSelectActivity.this, "Selected "+stageName+" as environment to use", Toast.LENGTH_SHORT).show();
            }
        });
        hideKeyboard();

        Button sandbox = (Button)findViewById(R.id.id_select_sandbox);
        sandbox.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(LOG_TAG, "Sandbox environment Button onClick");
                CommonUtils.setStage(StageSelectActivity.this, CommonUtils.kSandboxService);
                Toast.makeText(StageSelectActivity.this, "Selected Sandbox as environment to use", Toast.LENGTH_SHORT).show();
            }
        });

        Button live = (Button)findViewById(R.id.id_select_live);
        live.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(LOG_TAG, "Live environment Button onClick");
                CommonUtils.setStage(StageSelectActivity.this, CommonUtils.kLiveService);
                Toast.makeText(StageSelectActivity.this, "Selected Live as environment to use", Toast.LENGTH_SHORT).show();
            }
        });
    }

    /**
     * This method is needed to make sure nothing is invoked/called when the
     * orientation of the phone is changed.
     */
    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

    }

    private void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(StageSelectActivity.this.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(mStageSelection.getWindowToken(), 0);
    }
}