/**
 * PayPalHereSDK
 *
 * Created by PayPal Here SDK Team.
 * Copyright (c) 2013 PayPal. All rights reserved.
 */

package com.paypal.retailsdktestapp.utils;

import android.util.Log;

import com.paypal.paypalretailsdk.RetailSDK;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.StringWriter;
import java.io.Writer;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.regex.Pattern;

public class StringUtil {

    private static final String LOG_TAG = "retailsdktestapp+StringUtil";

    private static SimpleDateFormat df_e = new SimpleDateFormat("HH:mm:ss MMM d, yyyy zzz", Locale.ENGLISH);
    private static SimpleDateFormat df_us = new SimpleDateFormat("HH:mm:ss MMM d, yyyy zzz", Locale.US);

    private static Pattern mEmailValid = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,} *$");

    static public boolean validateEmail(String email) {
        return mEmailValid.matcher(email).matches();
    }

    static public boolean isAlphaNumeric(String string) {
        char c = 0;
        for (int i = 0; i < string.length(); i += 1) {
            c = string.charAt(i);
            if ((c >= 'a' && c <= 'z') ||
                    (c >= 'A' && c <= 'Z') ||
                    (c >= '0' && c <= '9'))
                continue;
            else
                return false;
        }
        return true;
    }

    public static boolean isEmpty(String string) {
        return string == null || string.trim().length() == 0;
    }

    public static boolean isNotEmpty(String string) {
        return string != null && string.trim().length() > 0;
    }

    public static String emptyIfNull(String inString) {
        return inString == null ? "" : inString;
    }

    public static Date parseDate(String inDate) {
        Date out = null;
        df_e.setLenient(true);
        try {
            out = df_e.parse(inDate);
        } catch (ParseException e) { // Phone doesn't like this locale
            df_us.setLenient(true);
            try {
                out = df_us.parse(inDate);
            } catch (ParseException e2) {
            } // Still doesn't like the locale, we give up on the date.
        }

        return out;
    }

    public static String hex(byte[] array) {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < array.length; ++i) {
            sb.append(
                    Integer.toHexString(
                            (array[i]
                                    & 0xFF) | 0x100
                    ).substring(1, 3)
            );
        }
        return sb.toString();
    }

    public static String convertHexToString(String hex) {

        StringBuilder sb = new StringBuilder();
        StringBuilder temp = new StringBuilder();

        //49204c6f7665204a617661 split into two characters 49, 20, 4c...
        for (int i = 0; i < hex.length() - 1; i += 2) {

            //grab the hex in pairs
            String output = hex.substring(i, (i + 2));
            //convert hex to decimal
            int decimal = Integer.parseInt(output, 16);
            //convert the decimal to character
            sb.append((char) decimal);

            temp.append(decimal);
        }

        return sb.toString();
    }

    public static String convertStreamToString(InputStream in) {
        java.util.Scanner s = new java.util.Scanner(in).useDelimiter("\\A");
        return s.hasNext()
                ? s.next()
                : "";
    }

    public static byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                    + Character.digit(s.charAt(i + 1), 16));
        }
        return data;
    }

    public static String encodeXml(String s) {

        if (isEmpty(s)) return "";

        String resultString = s;

        resultString = resultString.replace("&", "&amp;");
        resultString = resultString.replace("\"", "&quot;");
        resultString = resultString.replace("'", "&apos;");
        resultString = resultString.replace("\u0060", "&apos;");
        resultString = resultString.replace("<", "&lt;");
        resultString = resultString.replace(">", "&gt;");

        return resultString;

    }

    public static String getStringFromStream(InputStream is) {
        Writer writer = new StringWriter();
        char[] buffer = new char[1024];
        try {
            Reader reader = new BufferedReader(new InputStreamReader(is, "UTF-8"));
            int n;
            while ((n = reader.read(buffer)) != -1) {
                writer.write(buffer, 0, n);
            }
        } catch (IOException e) {
            RetailSDK.logViaJs("error", LOG_TAG, "File read failed: " + e.toString(), null);
        } finally {
            try {
                is.close();
            } catch (IOException e) {
            }
        }
        return writer.toString();
    }

    public static void writeToFile(OutputStream os, String data) {
        try {
            OutputStreamWriter outputStreamWriter = new OutputStreamWriter(os);
            outputStreamWriter.write(data);
            outputStreamWriter.close();
        }
        catch (IOException e) {
            Log.e(LOG_TAG, "File write failed: " + e.toString());
        } finally {
            try {
                os.close();
            } catch (IOException e) {
            }
        }
    }



    public static String defaultIfEmpty(String input, String defaultValue)
    {
        return isEmpty(input) ? defaultValue : input;
    }

    public static String defaultIfNotValid(boolean expresion, String input, String defaultValue)
    {
        return expresion ? input : defaultValue;
    }


}
