package com.paypal.paypalretailsdk.readers.common;

import android.bluetooth.BluetoothDevice;


public interface AudioJackCardReaderInterface extends CardReaderInterface{

    void markAudioJackDeviceAsPlugged(boolean pluggedIn);
    boolean isAudioJackDevicePlugged();
}
