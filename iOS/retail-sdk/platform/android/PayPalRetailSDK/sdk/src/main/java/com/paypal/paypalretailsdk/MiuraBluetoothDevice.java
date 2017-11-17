package com.paypal.paypalretailsdk;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.os.AsyncTask;
import android.util.Base64;
import android.util.Log;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;

class MiuraBluetoothDevice extends PayPalRetailObject
{
  private static final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
  private static final String LOG_TAG = MiuraBluetoothDevice.class.getSimpleName();

  public enum ConnectionStatus
  {
    None,
    Connecting,
    Connected
  }

  private ConnectionStatus status = ConnectionStatus.None;
  private BluetoothDevice device;
  private BluetoothSocket socket;
  private InputStream deviceIn;
  private V8Object nativeReader;
  private Thread readerThread;


  public MiuraBluetoothDevice(BluetoothDevice device)
  {
    this.device = device;
  }


  public void createJSReader()
  {
    nativeReader = PayPalRetailObject.getEngine().createJsObject();
    nativeReader.registerJavaMethod(this, "isConnected", "isConnected", null);
    nativeReader.registerJavaMethod(this, "jsConnect", "connect", new Class<?>[]{V8Function.class});
    nativeReader.registerJavaMethod(this, "jsDisconnect", "disconnect", new Class<?>[]{V8Function.class});
    nativeReader.registerJavaMethod(this, "send", "send", new Class<?>[]{Object.class, V8Object.class});
    nativeReader.registerJavaMethod(this, "jsRemoved", "removed", new Class<?>[]{V8Function.class});

    final V8Object deviceBuilder = PayPalRetailObject.getEngine().createJsObject("DeviceBuilder", RetailSDK.jsArgs());
    final V8Array args = getEngine().createJsArray()
            .push("MIURA")
            .push(this.device.getName())
            .push(false)
            .push(this.nativeReader);

    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        MiuraBluetoothDevice.this.impl = deviceBuilder.executeObjectFunction("build", args);
        PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
        {
          @Override
          public void run()
          {
            RetailSDK.getJsSdk().discoveredPaymentDevice(new PaymentDevice(MiuraBluetoothDevice.this.impl));
          }
        });
      }
    });
  }

  private void connectRfComm() throws IOException
  {
    socket = device.createInsecureRfcommSocketToServiceRecord(MY_UUID);
    socket.connect();
    startReadLoop(3);
  }

  private void forceDisconnect(final Exception ioException)
  {
    RetailSDK.logViaJs("error", LOG_TAG, "Forcing disconnect on " + this.device.getName() + " due to " + ioException);
    ioException.printStackTrace();
    this.disconnect();
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        MiuraBluetoothDevice.this.impl.executeVoidFunction("onDisconnected", RetailSDK.jsArgs().push(getEngine().asJsError(ioException)));
      }
    });
  }

  private void startReadLoop(final int remainingAttempts) throws IOException
  {
    deviceIn = socket.getInputStream();
    final InputStream myDevice = deviceIn;
    readerThread = new Thread(new Runnable()
    {
      @Override
      public void run()
      {
        byte[] buffer = new byte[2048];
        while (deviceIn == myDevice)
        {
          try
          {
            int bytes = deviceIn.read(buffer);
            if (bytes > 0)
            {
              final String base64Buffer = Base64.encodeToString(buffer, 0, bytes, Base64.NO_WRAP);
              PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
              {
                @Override
                public void run()
                {
                  MiuraBluetoothDevice.this.impl.executeVoidFunction("received", RetailSDK.jsArgs().push(base64Buffer));
                }
              });
            }
          }
          catch (final IOException ioException)
          {
            if (!MiuraBluetoothDevice.this.isConnected())
            {
              RetailSDK.logViaJs("warn", LOG_TAG, "Device disconnected. Exiting read loop on " + MiuraBluetoothDevice.this.device.getName() + " with exception " + ioException);
              return;
            }
            RetailSDK.logViaJs("warn", LOG_TAG, "IOException from startReadLoop (Remaining attempts : " + remainingAttempts + ") on " + MiuraBluetoothDevice.this.device.getName() + ", " + ioException);
            if (remainingAttempts > 0)
            {
              try
              {
                startReadLoop(remainingAttempts - 1);
              }
              catch (Exception ex)
              {
                MiuraBluetoothDevice.this.forceDisconnect(ex);
              }
            }
            else
            {
              MiuraBluetoothDevice.this.forceDisconnect(ioException);
            }
            return;
          }
          catch(Exception ex)
          {
            RetailSDK.logViaJs("error", LOG_TAG, "Exception from startReadLoop on " + MiuraBluetoothDevice.this.device.getName() + ", " + ex);
          }
        }
      }
    });
    readerThread.start();
  }


  private void disconnect()
  {
    RetailSDK.logViaJs("debug", LOG_TAG, "Disconnecting " + MiuraBluetoothDevice.this.device.getName());

    if (socket != null)
    {
      this.status = ConnectionStatus.None;
      try
      {
        readerThread.interrupt();
      }
      catch (Exception x)
      {
        Log.d(LOG_TAG, "Error on interrupting read loop " + x);
      }
      try
      {
        deviceIn.close();
      }
      catch (Exception x)
      {
        Log.d(LOG_TAG, "Error on closing device input stream " + x);
      }
      try
      {
        socket.close();
      }
      catch (Exception x)
      {
        Log.d(LOG_TAG, "Error on closing bt socket " + x);
      }
      socket = null;
      deviceIn = null;
    }
  }


  public boolean isConnected()
  {
    return this.socket != null && this.status == ConnectionStatus.Connected;
  }


  private boolean isPairedToDevice()
  {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    if (adapter == null)
    {
      // When bluetooth is switched-off, we don't know if the card reader is paired/not.
      // Returning false here might remove all the discovered card readers causing the SDK to do a full re-discovery when
      // the bluetooth is turned back on
      return true;
    }

    Set<BluetoothDevice> devices = adapter.getBondedDevices();
    if (devices == null)
    {
      return false;
    }

    Set<String> deviceAddress = new HashSet<>();
    for (BluetoothDevice d : devices)
    {
      deviceAddress.add(d.getAddress());
    }
    return deviceAddress.contains(this.device.getAddress());
  }


  public void jsConnect(V8Function jsCallback)
  {
    final V8Function callback = jsCallback.twin();
    AsyncTask.execute(new Runnable()
    {
      @Override
      public void run()
      {
        if (!isPairedToDevice())
        {
          RetailSDK.logViaJs(logLevel.debug.name(), LOG_TAG, "Device " + device.getName() + " not paired to the phone");
          MiuraBluetoothDevice.this.sendConnectionStatus(PayPalHereSdkError.CardReaderNotAvailable.getError(), callback);
          return;
        }

        if (!MiuraBluetoothDevice.this.isConnected())
        {
          IOException err = null;
          try {
            MiuraBluetoothDevice.this.connectRfComm();
          } catch (final IOException x) {
            RetailSDK.logViaJs("error", LOG_TAG, "Device connection failed with error " + x.toString());
            err = x;
          }
          MiuraBluetoothDevice.this.sendConnectionStatus(err, callback);
        }
      }
    });
  }

  private void sendConnectionStatus(final PayPalError err, final V8Function callback)
  {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        final V8Array args = RetailSDK.jsArgs();
        if (err == null) {
          args.pushUndefined();
        } else {
          args.push(err.impl);
        }
        MiuraBluetoothDevice.this.status = (err == null) ? ConnectionStatus.Connected : ConnectionStatus.None;
        callback.call(nativeReader, args);
      }
    });
  }

  private void sendConnectionStatus(final IOException err, final V8Function callback)
  {
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        final V8Array args = RetailSDK.jsArgs();
        if (err == null) {
          args.pushUndefined();
        } else {
          args.push(PayPalRetailObject.getEngine().asJsError(err.getMessage(), "-1", Arrays.toString(err.getStackTrace())));
        }

        MiuraBluetoothDevice.this.status = (err == null) ? ConnectionStatus.Connected : ConnectionStatus.None;
        callback.call(nativeReader, args);
      }
    });
  }

  public void jsDisconnect(V8Function jsCallback)
  {
    if (this.isConnected())
    {
      this.disconnect();
    }
    final V8Function callback = jsCallback.twin();
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        callback.call(nativeReader, RetailSDK.jsArgs().pushUndefined());
      }
    });
  }


  public void jsRemoved(V8Function jsCallback)
  {
    if (this.isConnected())
    {
      this.disconnect();
    }
    MiuraBluetoothDevice removedDevice = DeviceScanner.knownDevices.remove(this.device.getAddress());
    RetailSDK.logViaJs("debug", LOG_TAG, "jsRemoved triggered for : " + MiuraBluetoothDevice.this.device.getName());
    final V8Function callback = jsCallback.twin();
    PayPalRetailObject.getEngine().getExecutor().runNoWait(new Runnable()
    {
      @Override
      public void run()
      {
        callback.call(nativeReader, RetailSDK.jsArgs().pushUndefined());
      }
    });
  }
   protected void removePaymentDevice()
   {
     PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
     {
       @Override
       public void run()
       {
         MiuraBluetoothDevice.this.impl.executeVoidFunction("removed", RetailSDK.jsArgs().pushUndefined());
       }
     });
   }

  public boolean send(Object data, V8Object callback)
  {
    byte[] decoded;
    if (data instanceof String) {
      decoded = Base64.decode(data.toString(), 0);
    } else {
      // Object with data, offset, len
      V8Object dataInfo = (V8Object) data;
      int offset = dataInfo.getInteger("offset");
      int len = dataInfo.getInteger("len");
      // TODO may be able to be smarter about decoding a portion of the base64.
      decoded = Arrays.copyOfRange(Base64.decode(dataInfo.getString("data"), 0), offset, len + offset);
    }
    V8Function jsCallback = null;
    if (callback != null && !callback.isUndefined())
    {
      jsCallback = (V8Function) callback;
    }
    try
    {
      this.socket.getOutputStream().write(decoded);
      if (jsCallback != null && !jsCallback.isUndefined())
      {
        jsCallback.call(nativeReader, RetailSDK.jsArgs().pushUndefined());
      }
      return true;
    }
    catch (IOException x)
    {
      if (jsCallback != null && !jsCallback.isUndefined())
      {
        // TODO don't throw string error...
        jsCallback.call(nativeReader, RetailSDK.jsArgs().push(PayPalRetailObject.getEngine().asJsError(x)));
      }
      return false;
    }
  }
}
