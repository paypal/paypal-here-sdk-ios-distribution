/**
 * PayPalHereSDK
 * <p/>
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */

package com.paypal.paypalretailsdk.readers.common;


import java.util.HashMap;

public interface CardReaderObserver {
    public void onDeviceDetected(boolean isValidReader, CardReaderInterface.DeviceTypes type, CardReaderInterface.DeviceFamily family);

    public void onDeviceLostConnection(CardReaderInterface.DeviceTypes type, CardReaderInterface.DeviceFamily family);

    public void onDeviceError(String error);

    public void onSwipeDetected(HashMap<String, String> decodeData, String track1);

    public void onSwipeFailed();

}
