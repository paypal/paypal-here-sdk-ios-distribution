/**
 * PayPalHereSDK
 *
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */

package com.paypal.paypalretailsdk.readers.common;

public class Constants {

    public static final String CC_Other = "OTHER";

    ;
    public static final String EmptyString = "";

    ;

    public static enum ReaderConnectionStatus {
        NoReaderAvailable,
        Disconnected,
        AvailableButNotConnected,
        AvailableButNotSupported,
        Connected
    }

    ;

    public static enum CardBrand {
        Visa,
        MasterCard,
        Amex,
        DiscoverCard
    }
    public static enum CardSecurityType {
        StandardMagStripe,
        ChipAndPin
    }
}
