package com.paypal.paypalretailsdk.ui.dialogs;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.logLevel;
import com.paypal.paypalretailsdk.ui.RetailSDKBaseActivity;
import com.paypal.paypalretailsdk.ui.RetailSDKBasePresenter;

public class SDKDialogPresenter extends RetailSDKBasePresenter
{
  private static final String LOG_TAG = "SDKDialog.Presenter";
  private static SDKDialogPresenter _sdkDialogPresenter;
  private SDKDialogActivity _activity;
  private boolean _isStarting = false;
  private static Deque<SDKDialogCommand> _commandStack = new ArrayDeque<>();

  private SDKDialogPresenter()
  {

  }


  public synchronized static SDKDialogPresenter getInstance()
  {
    if(_sdkDialogPresenter == null)
    {
      _sdkDialogPresenter = new SDKDialogPresenter();
    }
    return _sdkDialogPresenter;
  }


  private synchronized SDKDialogCommand getLatestCommand()
  {
    try
    {
      if (_commandStack.size() > 0)
      {
        final SDKDialogCommand command = _commandStack.pop();
        _commandStack.clear();
        return command;
      }
    }
    catch (Exception ex)
    {
      Log.w(LOG_TAG, "Unable to dequeue commands " + ex.toString());
    }
    return null;
  }


  @Override
  public synchronized void initComponents(Activity activity)
  {
    _activity = (SDKDialogActivity)activity;
    _isStarting = false;
    SDKDialogCommand command = getLatestCommand();
    if (command != null)
    {
      if (command.getCommandType().equals(SDKDialogCommand.CommandType.DISMISS))
      {
        _activity.dismissDialog();
      }
      else if (command.getCommandType().equals(SDKDialogCommand.CommandType.SHOW))
      {
        _activity.updateView(command);
      }
    }
  }


  @Override
  public synchronized void onDestroy()
  {
    _activity = null;
    _isStarting = false;
    SDKDialogCommand command = getLatestCommand();
    if (command != null)
    {
      if (command.getCommandType().equals(SDKDialogCommand.CommandType.SHOW))
      {
        startActivity(command);
      }

      // Ignore dismiss command as the dialog was already dismissed
    }
  }


  synchronized void onNewCommand(SDKDialogCommand command)
  {
    Log.d(LOG_TAG, "NEW COMMAND received [CurrentQueued: " + _commandStack.size() + "]: " + command.toString());

    // SDK Dialog was not started or has been destroyed
    if (_activity == null && !_isStarting)
    {
      if (command.getCommandType().equals(SDKDialogCommand.CommandType.DISMISS))
      {
        RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Ignoring dismiss() as there is no active dialog activity");
      }

      if (command.getCommandType().equals(SDKDialogCommand.CommandType.SHOW))
      {
        RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Starting a new activity");
        startActivity(command);
      }
    }
    else if (_isStarting || _activity.isFinishing()) // SDK Dialog is starting or finishing
    {
      RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Enqueuing command for later use as activity is starting or finishing. isStarting: " + _isStarting + ". isFinishing: " + (_activity != null && _activity.isFinishing()));
      _commandStack.push(command);
    }
    else if (_activity != null) // SDK Dialog is showing
    {
      if (command.getCommandType().equals(SDKDialogCommand.CommandType.DISMISS))
      {
        RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Dismissing an active dialog - " + _activity.hashCode());
        _isStarting = false;
        _activity.dismissDialog();
      }
      else if (command.getCommandType().equals(SDKDialogCommand.CommandType.SHOW))
      {
        RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Updating view on an active dialog - " + _activity.hashCode());
        _activity.updateView(command);
      }
    }
    else
    {
      RetailSDK.logViaJs(logLevel.error.name(), LOG_TAG, "Unhandled SDK Dialog command " + command.toString());
    }
  }


  private synchronized void startActivity(SDKDialogCommand command)
  {
    _commandStack.push(command); // Command will be executed in initComponent()
    _isStarting = true;
    Intent intent = new Intent(getCurrentActivity(), SDKDialogActivity.class);
    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
    getCurrentActivity().startActivity(intent);
  }


  @Override
  public void handleBackPressed()
  {
    if (_activity != null)
    {
      _activity.finish();
    }
  }


  public boolean isShowing()
  {
    return _activity != null && _activity.isShowing();
  }


  @Override
  protected Intent createActivityIntent(V8Object options, HashMap<String, String> extraData)
  {
    return null;
  }


  @Override
  public void onLayoutInitialized(RetailSDKBaseActivity activity)
  {
  }

  public void setIsStarting(boolean value)
  {
    _isStarting = false;
  }
}
