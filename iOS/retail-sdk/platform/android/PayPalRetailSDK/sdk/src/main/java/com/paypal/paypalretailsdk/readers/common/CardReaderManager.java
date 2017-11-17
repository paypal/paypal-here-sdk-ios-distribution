/**
 * PayPalHereSDK
 *
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */

package com.paypal.paypalretailsdk.readers.common;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;

import java.util.List;

/**
 * CardReaderManager is the entry point for interacting with CardReaders used for<br>
 * credit card processing.<br>
 * The CardReaderManager lets the caller tap into feedback events from the underlying<br>
 * Card Reader without having to worry about the finer details of how the card readers work.<br>
 * Typically, application developers would want to tap into Card Reader related events together with<br>
 * the TransactionManager related events to get more context. However, in some cases, apps may just<br>
 * want to tap into the raw events from the card reader layer to implement more advanced functionality.<br>
 */
public interface CardReaderManager {

    public static final String INTENT_STRING_BLUETOOTH_DEVICE = "INTENT_STRING_BLUETOOTH_DEVICE";


    public interface CardReader {
        public String getName();

        public ReaderTypes getReaderType();
    }

    /**
     * The current list of supported card reader types.
     */
    public static enum ReaderTypes {
        MagneticCardReader,
        ChipAndPinReader,
        UnknownReader,
        NoReader
    }

}
