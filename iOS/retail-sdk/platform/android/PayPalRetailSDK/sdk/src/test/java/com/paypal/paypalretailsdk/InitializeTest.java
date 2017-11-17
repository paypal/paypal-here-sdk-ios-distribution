//package com.paypal.paypalretailsdk;
//
//import java.math.BigDecimal;
//import java.util.concurrent.CountDownLatch;
//import java.util.concurrent.TimeUnit;
//
//import android.content.Context;
//import org.junit.Assert;
//import org.junit.Test;
//
//public class InitializeTest
//{
//
//  public void initialize(Context context) throws Exception
//  {
//    RetailSDK.initialize(context);
//  }
//
//  public void makeInvoice(Context context) throws Exception {
//    RetailSDK.initialize(context);
//    Invoice invoice = new Invoice("USD");
//    invoice.addItem("Item", BigDecimal.valueOf(1.5), BigDecimal.ONE, "id1", null);
//    Assert.assertEquals(invoice.getItemCount().intValue(), 1);
//    Assert.assertEquals(invoice.getTotal().toString(), "1.5");
//  }
//
//  public void initializeMerchant(Context context, String testToken) throws Exception
//  {
//    RetailSDK.initialize(context);
//    final CountDownLatch latch = new CountDownLatch(1);
//    RetailSDK.initializeMerchant(testToken, new RetailSDK.MerchantInitializedCallback()
//    {
//      @Override
//      public void merchantInitialized(RetailSDKException error, Merchant merchant)
//      {
//        Assert.assertNull(error);
//        Assert.assertNotNull(merchant);
//        Assert.assertNotNull(merchant.getEmailAddress());
//        latch.countDown();
//      }
//    });
//
//    latch.await(30, TimeUnit.SECONDS);
//  }
//}
