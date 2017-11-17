/**
 * PayPalHereSDK
 * <p/>
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */
package com.paypal.paypalretailsdk.readers.common;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.regex.Pattern;

import android.util.Log;

public enum CardIssuer {
    //TODO: So far, only know the code names for Amex and Discover. Need to know for the others as well.

    VISA("VISA") {
        public boolean isTypeOf(String cardNumber) {
            return (cardNumber.length() > 0 && cardNumber.charAt(0) == VISA_CONTROL_NUMBER);
        }
    },

    MASTERCARD("MASTERCARD") {
        public boolean isTypeOf(String cardNumber) {

            if (StringUtil.isEmpty(cardNumber) || cardNumber.length() < 2) {
                return false;
            }

            int firstTwo = Integer.parseInt(cardNumber.substring(0, 2));
            return (firstTwo > 50 && firstTwo < 56);
        }

    },

    MAESTRO("MAESTRO") {
        final Pattern MAESTRO_CONTROL_NUMBER = Pattern.compile("(^50[0-9]{0,17}$)|(^5[6-9][0-9]{0,17}$)|(^6[0-9]{0," +
                "18}$)");
        final Pattern MAESTRO_VALIDATION = Pattern.compile("(^50[0-9]{10,17}$)|(^5[6-9][0-9]10{0,17}$)|(^6[0-9]{11," +
                "18}$)");

        public boolean isTypeOf(String cardNumber) {
            return MAESTRO_CONTROL_NUMBER.matcher(cardNumber).matches();
        }
    },

    AMEX("AMEX") {
        public boolean isTypeOf(String cardNumber) {
            if (cardNumber.length() < 2) {
                return false;
            }
            String cardControlNumber = cardNumber.substring(0, 2);
            return (cardNumber.length() > 1 && (cardControlNumber.equals(AMEX_CONTROL_NUMBER_1) || cardControlNumber
                    .equals(AMEX_CONTROL_NUMBER_2)));
        }
    },

    JCB("JCB") {
        public boolean isTypeOf(String cardNumber) {
            if (cardNumber.length() < 4) {
                return false;
            }

            try {
                int cardControlNumber = Integer.parseInt(cardNumber.substring(0, 2));
                return (cardNumber.length() > 1 && (cardControlNumber == JCB_CONTROL_NUMBER));
            } catch (NumberFormatException nfe) {
                Log.d("Card Issuer", "Number format exception parsing: " + cardNumber);
            }
            return false;
        }
    },

    DISCOVER("DISC") {
        public boolean isTypeOf(String cardNumber) {
            int lenght = cardNumber.length();

            if (lenght >= 4 && cardNumber.substring(0, 4).equals(DISCOVER_CONTROL_NUMBER_1)) {
                return true;
            } else if (lenght > 1 && cardNumber.substring(0, 2).equals(DISCOVER_CONTROL_NUMBER_2)) {
                return true;
            }

            return false;
        }
    },
    PAYPAL("PAYPAL") {
        public boolean isTypeOf(String cardNumber) {
            if (cardNumber.length() < 2) {
                return false;
            }
            String cardControlNumber = cardNumber.substring(0, 2);
            return (cardNumber.length() > 1 && (cardControlNumber.equals(PAYPAL_CONTROL_NUMBER)));
        }
    },
    UNKNOWN("") {
        public boolean isTypeOf(String cardNumber) {
            return true;
        }
    };

    private static HashMap<String, CardIssuer> nameAndEnumMap = new HashMap<String, CardIssuer>();

    static {
        for (CardIssuer t : EnumSet.allOf(CardIssuer.class)) {
            nameAndEnumMap.put(t.getCodeName(), t);
        }
    }

    Character VISA_CONTROL_NUMBER = '4';
    Character MASTERCARD_CONTROL_NUMBER = '5';
    String AMEX_CONTROL_NUMBER_1 = "34";
    String AMEX_CONTROL_NUMBER_2 = "37";
    String DISCOVER_CONTROL_NUMBER_1 = "6011";
    String DISCOVER_CONTROL_NUMBER_2 = "65";
    String PAYPAL_CONTROL_NUMBER = "62";
    int JCB_CONTROL_NUMBER = 35;
    private String mCodeName;

    CardIssuer(String codeName) {
        this.mCodeName = codeName;
    }

    public static CardIssuer getEnum(String codeName) {
        if (StringUtil.isEmpty(codeName))
            return null;

        codeName = codeName.toUpperCase();
        for (String key : nameAndEnumMap.keySet()) {
            if (codeName.contains(key)) {
                return nameAndEnumMap.get(key);
            }
        }
        return null;
    }

    public static CardIssuer getType(String cardNumber) {
        for (CardIssuer issuer : CardIssuer.values()) {
            if (issuer.isTypeOf(cardNumber)) {
                return issuer;
            }
        }

        return null;
    }

    public String getCodeName() {
        return this.mCodeName;
    }

    public abstract boolean isTypeOf(String cardNumber);
}
