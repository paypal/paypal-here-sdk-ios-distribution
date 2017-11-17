package com.paypal.paypalretailsdk.readers.common;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.Handler;
import android.os.Message;
import android.telephony.TelephonyManager;
import android.util.Log;
import com.paypal.paypalretailsdk.readers.swipers.RoamSwiper;

public class AudioJackManager extends BroadcastReceiver
{
  private static final String LOG_TAG = AudioJackManager.class.getSimpleName();

  protected CardReaderInterface.DeviceTypes mCurrentDeviceType;
  private RoamSwiper mCurrentActiveModule = null;
  private Context mContext = null;
  private static AudioJackManager sInstance;

  public synchronized static AudioJackManager getInstance()
  {
    if (sInstance == null)
    {
      sInstance = new AudioJackManager();
    }
    return sInstance;
  }


  private AudioJackManager()
  {
  }

  public void register(Context context)
  {
    mContext = context;
    if (null != mContext)
    {
      try
      {
        disconnect();
      }
      catch (Exception e)
      {
        Log.d(LOG_TAG, "Exception received while clearing the context. Ignore this.");
      }

      mContext.registerReceiver(sInstance, new IntentFilter(Intent.ACTION_HEADSET_PLUG));
      mContext.registerReceiver(sInstance, new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY));
    }
  }


  public boolean isConnected()
  {
    if (null != mCurrentActiveModule)
    {
      return mCurrentActiveModule.isConnected();
    }

    return false;
  }


  public void disconnect()
  {
    if (null != mContext)
    {
      try
      {
        mContext.unregisterReceiver(sInstance);
      }
      catch (Exception e)
      {
        Log.d(LOG_TAG, "Exception received while unregistering receiver. Ignore this.");
      }
    }
    unInitializeSwiper();
  }


  public void listenForCardEvents()
  {
    if (null != mCurrentActiveModule)
    {
      mCurrentActiveModule.listenForCardEvents();
    }
  }

  public void stopListeningForCardEvents()
  {
    if (null != mCurrentActiveModule)
    {
      mCurrentActiveModule.stopTransaction();
    }
  }

  public void registerObserverToRoamSwiper(CardReaderObserver observer)
  {
    if (null != mCurrentActiveModule)
    {
      mCurrentActiveModule.setObserver(observer);
    }
  }


  public String getName()
  {
    if (null != mCurrentActiveModule)
    {
      return mCurrentActiveModule.getName();
    }
    return null;
  }


  @Override
  public void onReceive(Context context, Intent intent)
  {
    try
    {
      Log.d(LOG_TAG, "onReceive " + intent.getAction());

      if (intent.getAction().equals(Intent.ACTION_HEADSET_PLUG))
      {
        TelephonyManager telephonyManager = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
        int callState = telephonyManager.getCallState();
        int headSetState = intent.getIntExtra("state", 1);
        int hasMicrophone = intent.getIntExtra("microphone", 0);

        if (1 == headSetState && 1 == hasMicrophone
            && (TelephonyManager.CALL_STATE_OFFHOOK != callState))
        {
          //Adding a one second delay to the card reader detection.  This is to take into account some phones which detect devices inserted into the
          //headphone jack and report on it before the device is fully plugged in.
          Handler delaySwiperDetection = new Handler(new DelaySwiperDetectionCallBack());
          delaySwiperDetection.sendEmptyMessageDelayed(0, 1000);
        }
        else if (0 == headSetState)
        {
          Log.d(LOG_TAG, "onReceive Headset unplugged");
          unInitializeSwiper();
        }
      }
      else if (intent.getAction().equals(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
      {
        unInitializeSwiper();
      }

    }
    catch (Exception ex)
    {
      ex.printStackTrace();
    }
  }


  private class DelaySwiperDetectionCallBack implements android.os.Handler.Callback
  {

    @Override
    public boolean handleMessage(Message msg)
    {
      initializeRoamSwiper();
      return true;
    }
  }


  private void initializeRoamSwiper()
  {
    Log.d(LOG_TAG, "initializeRoamSwiper");
    mCurrentDeviceType = CardReaderInterface.DeviceTypes.RoamPayReader;
    mCurrentActiveModule = RoamSwiper.getInstance(mContext);
    if (null != mCurrentActiveModule)
    {
      mCurrentActiveModule.markAudioJackDeviceAsPlugged(true);
    }
  }


  private void unInitializeSwiper()
  {
    Log.d(LOG_TAG, "unInitializeSwiper currentReaderType: " + mCurrentDeviceType);

    if (null == mCurrentActiveModule)
    {
      Log.d(LOG_TAG, "currentActiveModule is null. Hence there is nothing initialized to unInitialize");
      return;
    }

    if (!mCurrentActiveModule.isAudioJackDevicePlugged())
    {
      return;
    }

    mCurrentActiveModule.stopTransaction();
    mCurrentActiveModule.markAudioJackDeviceAsPlugged(false);
  }
}
