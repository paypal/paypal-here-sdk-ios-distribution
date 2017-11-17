package com.paypal.paypalretailsdk.ui.dialogs;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.support.v4.content.res.ResourcesCompat;
import android.view.ContextThemeWrapper;
import android.view.View;
import android.widget.Button;
import com.paypal.paypalretailsdk.R;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.logLevel;
import com.paypal.paypalretailsdk.readers.common.StringUtil;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class SDKDialogActivity extends RetailSDKBaseActivity
{
  private static final String LOG_TAG = "SDKDialog.Activity";
  private SDKDialogPresenter _presenter;
  private AlertDialog _dialog;

  @Override
  protected RetailSDKBasePresenter getPresenter()
  {
    return _presenter;
  }


  @Override
  public void initComponents(Bundle savedInstanceState)
  {
    RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "INIT_COMPONENTS - " + this.hashCode());
    _presenter = SDKDialogPresenter.getInstance();
    _presenter.initComponents(this);
  }


  @Override
  public void onNewIntent(Intent intent)
  {
    _presenter.initComponents(this);
  }


  @Override
  protected void onStop()
  {
    super.onStop();
    if (isShowing())
    {
      _dialog.cancel();
    }
    RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "ON_STOP - " + this.hashCode());
  }


  @Override
  protected void onStart()
  {
    super.onStart();
    RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "ON_START - " + this.hashCode());
  }


  @Override
  protected void onDestroy()
  {
    super.onDestroy();
    RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "ON_DESTROY - " + this.hashCode());
    _presenter.onDestroy();
  }


  @Override
  public void onBackPressed()
  {
    getPresenter().handleBackPressed();
  }


  public void updateView(final SDKDialogCommand command)
  {
    if (!command.getCommandType().equals(SDKDialogCommand.CommandType.SHOW))
    {
      return;
    }

    final RetailAlertBuilder builder;
    ContextThemeWrapper wrapper = new ContextThemeWrapper(this, R.style.SDKTheme_AlertDialog);

    // Progress bar with spinner
    if (command.showProgressSpinner())
    {
      SDKDialogBuilderWithNoButtonsAndProgressBar progressBarBuilder = new SDKDialogBuilderWithNoButtonsAndProgressBar(wrapper);
      progressBarBuilder.setView(this);
      if (StringUtil.isNotEmpty(command.getTitle()))
      {
        progressBarBuilder.setTitle(command.getTitle());
      }

      if (StringUtil.isNotEmpty(command.getMessage()))
      {
        progressBarBuilder.setMessage(command.getMessage());
      }
      progressBarBuilder.setProgressBarVisibility(true);
      progressBarBuilder.setCancelable(command.isCancellable());
      builder = progressBarBuilder;
    }
    // Dialog with more than one button
    else if (command.getButtons().size() > 1)
    {
      SDKDialogBuilderWithMultipleOptions multiButtonBuilder = new SDKDialogBuilderWithMultipleOptions(wrapper);
      multiButtonBuilder.setView(this);

      if (StringUtil.isNotEmpty(command.getTitle()))
      {
        multiButtonBuilder.setTitle(command.getTitle());
      }
      else
      {
        multiButtonBuilder.hideTitle();
      }

      if (StringUtil.isNotEmpty(command.getMessage()))
      {
        multiButtonBuilder.setMessage(command.getMessage());
      }
      else
      {
        multiButtonBuilder.hideMessage();
      }

      multiButtonBuilder.setCancelable(command.isCancellable());
      multiButtonBuilder.setOptions(wrapper, command.getButtons(), new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(DialogInterface dialogInterface, int i)
        {
          command.onClick(i);
        }
      });

      builder = multiButtonBuilder;
    }
    // Exactly 2 images
    else if (command.getButtonImgs().size() == 2)
    {
      SDKDialogBuilderWithMultipleOptionsWithImgs twoImageButtonBuilder = new SDKDialogBuilderWithMultipleOptionsWithImgs(wrapper);
      twoImageButtonBuilder.setView(this);

      if (StringUtil.isNotEmpty(command.getMessage()))
      {
        twoImageButtonBuilder.setMessage(command.getMessage());
      }

      for (int i = 0; i < command.getButtonImgs().size(); i++)
      {
        SDKDialogCommand.ImageButton imgButton = command.getButtonImgs().get(i);
        Drawable img = this.getDrawableFromId(imgButton.getImageIcon());
        if (img == null)
        {
          throw new RuntimeException("Unable to locate Drawable for " + imgButton.getImageIcon());
        }

        final int index = i;
        if (index == 0)
        {
          twoImageButtonBuilder.addLeftOptionButton(img, new Button.OnClickListener()
          {
            @Override
            public void onClick(View v)
            {
              command.onClick(index);
            }
          });
        }
        else
        {
          twoImageButtonBuilder.addRightOptionButton(img, new Button.OnClickListener()
          {
            @Override
            public void onClick(View v)
            {
              command.onClick(index);
            }
          });
        }
      }
      twoImageButtonBuilder.setCancelable(command.isCancellable());
      builder = twoImageButtonBuilder;
    }
    // 1, 3 or more button images
    else if (command.getButtonImgs().size() > 0)
    {
      SDKDialogBuilderDynamicallyWithImgs dynamicImageButtonBuilder = new SDKDialogBuilderDynamicallyWithImgs(wrapper);
      dynamicImageButtonBuilder.setView(this);

      if (StringUtil.isNotEmpty(command.getMessage()))
      {
        dynamicImageButtonBuilder.setMessage(command.getMessage());
      }

      for (int i = 0; i < command.getButtonImgs().size(); i++)
      {
        SDKDialogCommand.ImageButton imgButton = command.getButtonImgs().get(i);
        String id = imgButton.getId();
        Drawable img = this.getDrawableFromId(imgButton.getImageIcon());
        if (img == null)
        {
          throw new RuntimeException("Unable to locate Drawable for " + imgButton.getImageIcon());
        }
        final int index = i;
        dynamicImageButtonBuilder.addImgButton(wrapper, img, id, new Button.OnClickListener()
        {
          @Override
          public void onClick(View v)
          {
            command.onClick(index);
          }
        });
      }
      dynamicImageButtonBuilder.setCancelable(command.isCancellable());
      builder = dynamicImageButtonBuilder;
    }
    // Default progress bar with 'Cancel' button
    else
    {
      final SDKDialogBuilderWithTwoButtons oneButtonBuilder = new SDKDialogBuilderWithTwoButtons(wrapper);
      oneButtonBuilder.setView(this);
      if (StringUtil.isNotEmpty(command.getTitle()))
      {
        oneButtonBuilder.setTitle(command.getTitle());
      }
      else
      {
        oneButtonBuilder.hideTitle();
      }

      if (StringUtil.isNotEmpty(command.getMessage()))
      {
        oneButtonBuilder.setMessage(command.getMessage());
      }
      else
      {
        oneButtonBuilder.hideMessage();
      }
      oneButtonBuilder.hidePositiveButton();
      String cancelButton = command.getButtons().size() > 0 ? command.getButtons().get(0) : null;
      if (StringUtil.isNotEmpty(cancelButton))
      {
        oneButtonBuilder.setNegativeButtonClickListener(cancelButton, new View.OnClickListener()
        {
          @Override
          public void onClick(View v)
          {
            command.onClick(0);
          }
        });
      }
      else
      {
        oneButtonBuilder.hideNegativeButton();
      }

      Drawable img = this.getDrawableFromId(command.getImg());
      if (img == null)
      {
        oneButtonBuilder.hideImage();
      }
      else
      {
        oneButtonBuilder.setmImageView(img);
      }
      oneButtonBuilder.setCancelable(command.isCancellable());
      builder = oneButtonBuilder;
    }

    runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        if (isShowing())
        {
          RetailSDK.logViaJs("debug", LOG_TAG, "Update existing content view to (" + command.getTitle() + ":" + command.getMessage() + ")");
          _dialog.setContentView(builder.getView());
        }
        else
        {
          RetailSDK.logViaJs("debug", LOG_TAG, "CREATE NEW dialog for (" + command.getTitle() + ":" + command.getMessage() + ")");
          _dialog = builder.create();
          _dialog.setOnCancelListener(new DialogInterface.OnCancelListener()
          {
            @Override
            public void onCancel(DialogInterface dialogInterface)
            {
              RetailSDK.logViaJs("debug", LOG_TAG, "CLOSED for (" + command.getTitle() + ":" + command.getMessage() + ")... Finishing activity");
              finish();
            }
          });
          if(_dialog.getWindow() != null)
          {
            _dialog.getWindow().getAttributes().windowAnimations = R.style.SdkDialogAnimation;
            _dialog.show();
          }
        }
        playAudio(command.getAudio());
      }
    });
  }

  private void playAudio(SDKDialogCommand.Audio audio)
  {
    if (audio == null || StringUtil.isEmpty(audio.getFile()))
    {
      return;
    }

    if (audio.getFile().equalsIgnoreCase("beep"))
    {
      RetailSDK.getAudio().playAudibleBeep(audio.getPlayCount());
    }
    else if (audio.getFile().equalsIgnoreCase("success_card_read.mp3"))
    {
      RetailSDK.getAudio().playSound(R.raw.success_card_read);
    }
  }


  private Drawable getDrawableFromId(String imageId)
  {
    if (imageId == null)
    {
      return null;
    }
    int imgId = this.getResources().getIdentifier(imageId, "drawable", this.getPackageName());
    if (imgId > 0)
    {
      return ResourcesCompat.getDrawable(this.getResources(), imgId, null);
    }
    return null;
  }


  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    RetailSDK.logViaJs("debug", LOG_TAG, "ON_CREATE");
    super.onCreate(savedInstanceState);
    setContentView(R.layout.sdk_activity_transparent);
  }


  @Override
  protected void onResume()
  {
    super.onResume();
  }

  public synchronized void dismissDialog()
  {
    RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Try process DISMISS command");
    if (isShowing())
    {
      _dialog.dismiss();
      RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Dismissed dialog");
    }
    else
    {
      RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Ignored dismiss command as dialog not showing");
    }

    try
    {
      RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Completing activity... - " + this.hashCode());
      finish();
    }
    catch (Exception ex)
    {
      RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Exception on finish() " + ex.toString());
    }
  }


  public boolean isShowing()
  {
    return _dialog != null && _dialog.isShowing();
  }
}
