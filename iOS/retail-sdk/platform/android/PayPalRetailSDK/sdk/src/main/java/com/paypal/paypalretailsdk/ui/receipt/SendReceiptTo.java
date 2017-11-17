package com.paypal.paypalretailsdk.ui.receipt;

import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.paypal.paypalretailsdk.PayPalRetailObject;

public enum SendReceiptTo {
    None("None"),
    Email("Email"),
    Sms("Sms");

    private final String _method;

    SendReceiptTo(String method) {
        _method = method;
    }

    public String getMethod() {
        return _method;
    }

    public static V8Array buildV8Args(String destination) {
        V8Array args;
        if(destination == null || destination.isEmpty()) {
            args = PayPalRetailObject.getEngine().getEmptyArray();
        } else {
            args = PayPalRetailObject.getEngine().createJsArray();
            V8Object options = PayPalRetailObject.getEngine().createJsObject();
            options.add("name", "emailOrSms");
            options.add("value", destination);
            args.pushUndefined().push(options);
        }

        return args;
    }

    public static V8Array buildV8Args(int optionIndex, String optionName) {
        V8Array args = PayPalRetailObject.getEngine().createJsArray();
        V8Object options = PayPalRetailObject.getEngine().createJsObject();
        options.add("name", optionName);
        options.add("value", optionIndex);
        args.pushUndefined().push(options);
        return args;
    }
}
