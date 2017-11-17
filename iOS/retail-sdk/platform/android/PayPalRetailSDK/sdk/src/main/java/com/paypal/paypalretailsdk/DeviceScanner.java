package com.paypal.paypalretailsdk;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.os.AsyncTask;

public class DeviceScanner
{
  private static final String LOG_COMPONENT = "native.deviceScanner";
  ScheduledExecutorService executor;
  ScheduledFuture next;
  Runnable checker;
  private volatile boolean _cancelRequested = false;
  private final Object lock = new Object();

  RoamSwiperDevice mRoamSwiperDevice = null;

  public static ConcurrentHashMap<String, MiuraBluetoothDevice> knownDevices = new ConcurrentHashMap<>();


  public DeviceScanner()
  {
    checker = new Runnable()
    {
      @Override
      public void run()
      {
        initializeSwiper();
        scan();
        try
        {
          next = executor.schedule(checker, 5, TimeUnit.SECONDS);
        }
        catch (Exception ex)
        {
          RetailSDK.logViaJs("warn", LOG_COMPONENT, "Could not schedule the next device scan. Perhaps the scheduler was shut down");
        }
      }
    };
  }


  public void startWatching()
  {
    _cancelRequested = false;
    if (executor == null || executor.isShutdown())
    {
      RetailSDK.logViaJs("info", LOG_COMPONENT, "Starting device discovery");
      synchronized (lock)
      {
        executor = Executors.newScheduledThreadPool(1);
        AsyncTask.execute(checker);
      }
    }
    else
    {
      RetailSDK.logViaJs("debug", LOG_COMPONENT, "Skip device discovery as it was already enabled");
    }
  }

  private void initializeSwiper()
  {
    /*
    DE91286: Swipers are available for US, CA, HK merchants only and NOT UK or AU
    So don't create a RoamSwiper device at all
     */
    if(RetailSDK.checkIfSwiperIsEligibleForMerchant())
    {
      if (null == mRoamSwiperDevice)
      {
        mRoamSwiperDevice = new RoamSwiperDevice();
      }

      if ((null != mRoamSwiperDevice) && (!mRoamSwiperDevice.isRegistered()))
      {
        mRoamSwiperDevice.register();

        if (mRoamSwiperDevice.isRegistered())
        {
          PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
          {
            @Override
            public void run()
            {
              mRoamSwiperDevice.createJSReader();
            }
          });
        }
      }
    }
  }

  public void stopWatching()
  {
    if (executor == null || executor.isShutdown())
    {
      RetailSDK.logViaJs("debug", LOG_COMPONENT, "Device discovery already shutdown. Will ignore call to stopWatching()");
      return;
    }

    RetailSDK.logViaJs("info", LOG_COMPONENT, "Shutting down device discovery");
    _cancelRequested = true;
    if (next != null)
    {
      next.cancel(false);
    }
    synchronized (lock)
    {
      executor.shutdown();
    }
  }


  void scan()
  {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    if (adapter == null)
    {
      return;
    }
    Set<BluetoothDevice> devices = adapter.getBondedDevices();
    if (devices != null)
    {
      Set<String> deviceAddress = new HashSet<>();
      for (BluetoothDevice d : devices)
      {
        deviceAddress.add(d.getAddress());
      }
      for(Map.Entry<String, MiuraBluetoothDevice> knownDevice: knownDevices.entrySet())
      {
        if(!deviceAddress.contains(knownDevice.getKey()))
        {
          knownDevices.get(knownDevice.getKey()).removePaymentDevice();
        }
      }
      for (BluetoothDevice device : devices)
      {
        if (knownDevices.containsKey(device.getAddress()))
        {
          continue;
        }
        if (device.getName() != null && device.getName().startsWith("PayPal "))
        {
          if (_cancelRequested)
          {
            return;
          }
          synchronized (this)
          {
            RetailSDK.logViaJs("info", LOG_COMPONENT, "Found Miura reader device " + device.getName() + ". Will provision it");
            final MiuraBluetoothDevice newReader = new MiuraBluetoothDevice(device);
            knownDevices.put(device.getAddress(), newReader);
            PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
            {
              @Override
              public void run()
              {
                newReader.createJSReader();
              }
            });
          }
        }
      }
    }
  }
}
