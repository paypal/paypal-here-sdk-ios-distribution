package com.paypal.paypalretailsdk;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import com.eclipsesource.v8.JavaVoidCallback;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.google.gson.Gson;
import com.paypal.paypalretailsdk.exceptions.MerchantNotInitializedException;
import com.paypal.paypalretailsdk.exceptions.SdkNotInitializedException;
import com.paypal.paypalretailsdk.location.LocationService;
import com.paypal.paypalretailsdk.location.LocationServiceImpl;
import com.paypal.paypalretailsdk.pph.PPHMerchant;
import com.paypal.paypalretailsdk.pph.PPHMerchantStatus;
import com.paypal.paypalretailsdk.pph.PPHMerchantUserInfo;
import com.paypal.paypalretailsdk.readers.common.AudioJackManager;
import com.paypal.paypalretailsdk.ui.dialogs.SDKDialogPresenter;

public final class RetailSDK
{
  private static final String LOG_TAG = "PayPalHereSDK";
  public static SDK sJsSdk;
  public static Context sContext;
  public static SoundNotification sAudio;
  private static RetailSDKException sStartupError;
  private static DeviceScanner sScanner;
  private static LocationService sLocationService;
  private static AppState _appState;
  private static AudioJackManager sAudioJackManager;

  public interface AppState
  {
    Activity getCurrentActivity();

    boolean getIsTabletMode();
  }


  public static AudioJackManager getAudioJackManager()
  {
    return sAudioJackManager;
  }


  // TODO - Use enum for level
  public static void logViaJs(final String level, final String component, final String message)
  {
    logViaJs(level, component, message, null);
  }


  public static void logViaJs(final String level, final String component, final String message, final Map<String, ? super Object> extraData)
  {
    sJsSdk.logViaJs(level, component, message, extraData);
  }


  public static void setLogLevel(logLevel logLevel)
  {
    sJsSdk.setLogLevel(logLevel);
  }


  /**
   * This is the first call you should make to the PayPal Retail SDK (typically in application startup,
   * but if you are using the SDK only in certain cases or for certain customers, then at the appropriate time)
   */
  public static void initialize(final android.content.Context context, final AppState appState) throws RetailSDKException
  {
    _appState = appState;
    if (sContext == null)
    {
      sContext = context;
    }
    if (sStartupError != null)
    {
      throw sStartupError;
    }
    else if (sJsSdk != null)
    {
      return;
    }

    StringBuilder fullJs;

    try
    {
      InputStream resourceStream = context.getResources().openRawResource(R.raw.paypalretailsdk);

      InputStreamReader inputReader = new InputStreamReader(resourceStream);
      BufferedReader jsReader = new BufferedReader(inputReader);

      fullJs = new StringBuilder();
      String line;
      while ((line = jsReader.readLine()) != null)
      {
        fullJs.append(line).append('\n');
      }
    }
    catch (java.io.IOException jio)
    {
      throw new RetailSDKException(jio);
    }

    final String finalJs = fullJs.toString();

    PayPalRetailObject.createManticoreEngine(context, finalJs);
    sAudio = new SoundNotification(context);
    sScanner = new DeviceScanner();
    sLocationService = new LocationServiceImpl(context);
    sLocationService.start();
    sAudioJackManager = AudioJackManager.getInstance();
  }


  /**
   * If for some reason you want to shutdown all SDK activity and uninitialize the SDK, call shutdownSDK. You will need to
   * call initializeSDK and initializeMerchant again to start using the SDK afterwards.
   */
  // TODO Commenting this out as SDK does not currently have a way to stop executing JS code after getEngine().shutDown() is invoked and thereby throws an unhandled exception
//  private static void Shutdown()
//  {
//    getAudioJackManager().disconnect();
//    sAudio.stop();
//    sScanner.stopWatching();
//    sAudioJackManager = null;
//    sAudio = null;
//    sScanner = null;
//    sStartupError = null;
//    sJsSdk = null;
//    PayPalRetailObject.getEngine().shutDown();
//  }


  public static LocationService getLocationService()
  {
    return sLocationService;
  }


  public static SoundNotification getAudio()
  {
    return sAudio;
  }


  static void setJsSdk(V8Object sdk)
  {
    // We need to retain the sdk argument because J2V8 is about to release it.
    sJsSdk = new SDK(sdk.twin());
  }


  public static SDK getJsSdk()
  {
    return sJsSdk;
  }


  public static void setAppInfo(String appVersion, String osVersion, String payerId)
  {
    sJsSdk.setExecutingEnvironment(appVersion, osVersion, payerId);
  }


  public static AppState getAppState()
  {
    return _appState;
  }


  /**
   * The callback signature for initializeMerchant
   */
  public interface MerchantInitializedCallback
  {
    void merchantInitialized(RetailSDKException error, Merchant merchant);
  }

  @SdkInitialized
  public static void initializeMerchant(final SdkCredential credentials, final MerchantInitializedCallback callback) throws Exception
  {
    validate();

    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        final V8Object tokenObj = PayPalRetailObject.getEngine().createJsObject();
        tokenObj.add("accessToken", credentials.accessToken);
        tokenObj.add("refreshUrl", credentials.refreshUrl);
        tokenObj.add("refreshToken", credentials.refreshToken);
        tokenObj.add("appId", credentials.clientId);
        tokenObj.add("appSecret", credentials.clientSecret);
        tokenObj.add("environment", credentials.environment);
        V8Array args = jsArgs().push(tokenObj);
        try
        {
          String token = sJsSdk.impl.executeStringFunction("buildCompositeToken", args);
          initializeMerchant(token, credentials.repository, callback);
        }
        catch (Exception e)
        {
          RetailSDKException re = new RetailSDKException(e);
          callback.merchantInitialized(re, null);
        }
      }
    });
  }


  /**
   * Once you have retrieved a token for your merchant (typically from a backend server), call initializeMerchant
   * and wait for the completionHandler to be called before doing more SDK operations.
   */
  @SdkInitialized
  public static void initializeMerchant(final String token, final String repository, final MerchantInitializedCallback callback)
  {
    validate();

    final JavaVoidCallback jsCallback = new JavaVoidCallback()
    {
      @Override
      public void invoke(V8Object jsThis, V8Array v8Array)
      {
        RetailSDKException error = null;
        Merchant m = null;
        if (v8Array.length() > 0 && v8Array.get(0) != null)
        {
          error = PayPalRetailObject.getEngine().getConverter().asNative(v8Array.getObject(0), RetailSDKException.class);
        }
        if (v8Array.length() > 1 && v8Array.get(1) != null)
        {
          m = new Merchant(v8Array.getObject(1));
        }
        try
        {
          callback.merchantInitialized(error, m);
        }
        catch (Exception e)
        {
          Log.e("RetailSDK", "Exception during initializeMerchant callback.", e);
        }
      }
    };

    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        V8Object cbHolder = PayPalRetailObject.getEngine().createJsObject().registerJavaMethod(jsCallback, "_");
        V8Object cbFn = cbHolder.getObject("_");
        V8Array args = jsArgs().push(token).push(repository).push(cbFn);
        sJsSdk.impl.executeVoidFunction("initializeMerchant", args);
      }
    });
  }

  @SdkInitialized
  public static void InitializeMerchant(final PPHMerchant merchant, final MerchantInitializedCallback callback)
  {
    validate();

    if (merchant == null)
    {
      // TODO : Handle this better. Throw an exception perhaps.
      V8Object error = PayPalRetailObject.getEngine().createJsObject();
      error.add("message", "Merchant object cannot be null");
      callback.merchantInitialized(new RetailSDKException(error), null);
    }

    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        SdkCredential credentials = merchant.getCredential();
        final V8Object tokenObj = PayPalRetailObject.getEngine().createJsObject();
        tokenObj.add("accessToken", credentials.accessToken);
        tokenObj.add("environment", credentials.environment);
        tokenObj.add("repository", credentials.repository);

        PPHMerchantUserInfo merchantUserInfo = merchant.getUserInfo();
        V8Object userInfo = PayPalRetailObject.getEngine().createJsObject();
        userInfo.add("name", merchantUserInfo.getName());
        userInfo.add("given_name", merchantUserInfo.getGivenName());
        userInfo.add("family_name", merchantUserInfo.getFamilyName());
        userInfo.add("email", merchantUserInfo.getEmail());
        userInfo.add("businessCategory", merchantUserInfo.getBusinessCategory());
        userInfo.add("businessSubCategory", merchantUserInfo.getBusinessSubCategory());
        V8Object address = PayPalRetailObject.getEngine().createJsObject();
        address.add("street_address", merchantUserInfo.getAddress().getLine1());
        address.add("locality", merchantUserInfo.getAddress().getCity());
        address.add("country", merchantUserInfo.getAddress().getCountry());
        address.add("region", merchantUserInfo.getAddress().getState());
        address.add("postal_code", merchantUserInfo.getAddress().getPostalCode());
        userInfo.add("address", address);

        PPHMerchantStatus merchantStatus = merchant.getStatus();
        V8Object status = PayPalRetailObject.getEngine().createJsObject();
        status.add("status", merchantStatus.getStatus());
        status.add("currencyCode", merchantStatus.getCurrencyCode());
        status.add("categoryCode", merchantStatus.getBusinessCategoryExists());
        Gson gson = new Gson();
        String paymentTypesJson = gson.toJson(merchantStatus.getPaymentTypes());
        status.add("paymentTypes", paymentTypesJson);
        String cardSettingsJson = gson.toJson(merchantStatus.getCardSettings());
        status.add("cardSettings", cardSettingsJson);
        status.add("businessCategoryExists", merchantStatus.getBusinessCategoryExists());

        final V8Object merchantObj = PayPalRetailObject.getEngine().createJsObject();
        merchantObj.add("token", tokenObj);
        merchantObj.add("userInfo", userInfo);
        merchantObj.add("status", status);
        merchantObj.add("repository", credentials.repository);

        try
        {
          V8Array args = jsArgs().push(merchantObj);
          V8Object merchant = sJsSdk.impl.executeObjectFunction("setMerchant", args);
          callback.merchantInitialized(null, new Merchant(merchant));
        }
        catch (Exception e)
        {
          RetailSDKException re = new RetailSDKException(e);
          Log.e("RetailSDK", "Exception during MI .", re);
        }
      }
    });
  }


  /**
   * This is the primary starting point for taking a payment. First, create an invoice, then create a transaction, then
   * begin the transaction to have the SDK listen for events and go through the relevant flows for a payment type.
   */
  @SdkInitialized
  @MerchantInitialized
  public static TransactionContext createTransaction(final Invoice invoice)
  {
    validate();

    V8Object txContext = PayPalRetailObject.getEngine().getExecutor().run(new Callable<V8Object>()
    {
      @Override
      public V8Object call() throws Exception
      {
        return sJsSdk.impl.executeObjectFunction("createTransaction", jsArgs().push(invoice.impl));
      }
    });
    return new TransactionContext(txContext);
  }

  @SdkInitialized
  @MerchantInitialized
  public static void beginCardReaderDiscovery()
  {
    validate();

    if(checkIfSwiperIsEligibleForMerchant())
    {
      sAudioJackManager.register(sContext);
    }
    if (sScanner != null)
    {
      sScanner.startWatching();
    }
  }

  @SdkInitialized
  @MerchantInitialized
  public static void beginRoamSwiper()
  {
    validate();

    if(checkIfSwiperIsEligibleForMerchant())
    {
      sAudioJackManager.register(sContext);
    }
  }


  static boolean checkIfSwiperIsEligibleForMerchant()
  {
    /*
    DE91286: Swipers are available for US, CA, HK merchants only and NOT UK or AU
     */
    String currencyCode = sJsSdk.getMerchant().getCurrency();
    return currencyCode != null && (!(currencyCode.equalsIgnoreCase("GBP") || currencyCode.equalsIgnoreCase("AUD")));
  }

  @SdkInitialized
  @MerchantInitialized
  public static void endCardReaderDiscovery()
  {
    validate();

    sAudioJackManager.disconnect();
    if (sScanner != null)
    {
      sScanner.stopWatching();
    }
  }

  @SdkInitialized
  @MerchantInitialized
  public static void endRoamSwiper()
  {
    validate();

    sAudioJackManager.disconnect();
  }

  public static void logout()
  {
    RetailSDK.logViaJs("info", LOG_TAG, "SDK logout invoked");
    endCardReaderDiscovery();
    sJsSdk.logout();
    SDKDialogPresenter.getInstance().setIsStarting(false);
  }


  /**
   * At various points during a transaction flow we need to present UI. Typically, before you
   * kick off a transaction flow you should call this method to give us the launching point for
   * our activities.
   *
   * @param activity The foreground activity for your application
   */
  public static void setCurrentApplicationActivity(Activity activity)
  {
    sContext = activity;
  }


  /**
   * Provide an interceptor for all HTTP calls made by the SDK
   *
   * @param interceptor Custom implementation to handle SDK network requests
   */
  public static void setNetworkInterceptor(final NetworkInterceptorCallback interceptor)
  {
    SDK.InterceptCallback callback = new SDK.InterceptCallback()
    {
      @Override
      public void intercept(NetworkRequest request)
      {
        interceptor.networkInterceptor(request);
      }
    };
    sJsSdk.setNetworkInterceptor(callback);
  }


  public interface NetworkInterceptorCallback
  {
    void networkInterceptor(NetworkRequest request);
  }


  //<editor-fold description="Interface declarations for events">


  /**
   * A PaymentDevice has been discovered. For further events, such as device
   * readiness, removal or the need for a software upgrade, your application should
   * subscribe to the relevant events on the device
   * parameter. Please note that this doesn't always mean the device is present. In
   * certain cases (e.g. Bluetooth)
   * we may know about the device independently of whether it's currently connected
   * or available.
   */
  public interface DeviceDiscoveredObserver
  {
    void deviceDiscovered(PaymentDevice device);
  }


  /**
   * A page has been viewed
   */
  public interface PageViewedObserver
  {
    void pageViewed(RetailSDKException error, Page page);
  }

  //</editor-fold>

  //<editor-fold description="Event subscribe/unsubscribe">


  /**
   * Add an observer for the deviceDiscovered event
   */
  public static void addDeviceDiscoveredObserver(final DeviceDiscoveredObserver observer)
  {
    if (null == deviceDiscoveredMap)
    {
      deviceDiscoveredMap = new HashMap<>();
    }
    else
    {
      if (deviceDiscoveredMap.containsKey(observer))
      {
        throw new IllegalArgumentException("That observer has already been added to the deviceDiscovered event.");
      }
    }
    SDK.DeviceDiscoveredObserver proxy = new DeviceDiscoveredProxy(observer);
    sJsSdk.addDeviceDiscoveredObserver(proxy);
  }


  /**
   * Remove an observer for the deviceDiscovered event
   */
  public static void removeDeviceDiscoveredObserver(DeviceDiscoveredObserver observer)
  {
    DeviceDiscoveredProxy p = null;
    if (deviceDiscoveredMap != null && (p = deviceDiscoveredMap.get(observer)) != null)
    {
      sJsSdk.removeDeviceDiscoveredObserver(p);
    }
  }


  /**
   * Add an observer for the deviceDiscovered event
   */
  public static void addPageViewedObserver(final PageViewedObserver observer)
  {
    if (null == pageViewedMap)
    {
      pageViewedMap = new HashMap<>();
    }
    else if (pageViewedMap.containsKey(observer))
    {
      throw new IllegalArgumentException("That observer has already been added to the deviceDiscovered event.");
    }
    SDK.PageViewedObserver proxy = new PageViewedProxy(observer);
    sJsSdk.addPageViewedObserver(proxy);
  }


  /**
   * Remove an observer for the deviceDiscovered event
   */
  public static void removePageViewedObserver(PageViewedObserver observer)
  {
    if (pageViewedMap == null)
    {
      return;
    }
    PageViewedProxy p = pageViewedMap.get(observer);
    if (p == null)
    {
      return;
    }
    sJsSdk.removePageViewedObserver(p);
  }


  public static DeviceManager getDeviceManager()
  {
    return sJsSdk.getDeviceManager();
  }


  private static Map<DeviceDiscoveredObserver, DeviceDiscoveredProxy> deviceDiscoveredMap;
  private static Map<PageViewedObserver, PageViewedProxy> pageViewedMap;


  static class DeviceDiscoveredProxy implements SDK.DeviceDiscoveredObserver
  {
    public DeviceDiscoveredObserver mOriginal;


    public DeviceDiscoveredProxy(DeviceDiscoveredObserver original)
    {
      mOriginal = original;
    }


    @Override
    public void deviceDiscovered(PaymentDevice device)
    {
      mOriginal.deviceDiscovered(device);
    }
  }


  static class PageViewedProxy implements SDK.PageViewedObserver
  {
    public PageViewedObserver mOriginal;


    public PageViewedProxy(PageViewedObserver original)
    {
      mOriginal = original;
    }


    @Override
    public void pageViewed(RetailSDKException error, Page page)
    {
      mOriginal.pageViewed(error, page);
    }
  }

  public static void retrieveAuthorizedTransactions(final Date startTime, final Date endTime, final Integer pageSize, final List<AuthStatus> status, final AuthorizedTransactionsHandler handler) {
    sJsSdk.retrieveAuthorizedTransactions(startTime, endTime, pageSize, status, handler);
  }

  public static void retrieveAuthorizedTransactions(final String nextPageToken, final AuthorizedTransactionsHandler handler) {
    sJsSdk.retrieveAuthorizedTransactionsUsingNextPageToken(nextPageToken, handler);
  }
  public static abstract class AuthorizedTransactionsHandler implements SDK.RetrieveAuthorizedTransactionsCallback
  {
    public abstract void handle(RetailSDKException error, List<AuthorizedTransaction> listOfAuths, String nextPageToken);

    @Override
    public void retrieveAuthorizedTransactions(RetailSDKException error, List<AuthorizedTransaction> listOfAuths, String nextPageToken)
    {
      this.handle(error, listOfAuths, nextPageToken);
    }
  }

  public static void voidAuthorization(final String authorizationId, final VoidAuthorizationHandler handler) {
    sJsSdk.voidAuthorization(authorizationId, handler);
  }

  public static abstract class VoidAuthorizationHandler implements SDK.VoidAuthorizationCallback {
    public abstract void handle(RetailSDKException error);

    @Override
    public void voidAuthorization(RetailSDKException error) {
      this.handle(error);
    }
  }

  public static void captureAuthorization(final String authorizationId, final String invoiceId, final BigDecimal totalAmount, final BigDecimal gratuityAmount, final String currency, final CaptureAuthorizationHandler handler) {
    sJsSdk.captureAuthorizedTransaction(authorizationId, invoiceId, totalAmount, gratuityAmount, currency, handler);
  }

  public static abstract class CaptureAuthorizationHandler implements SDK.CaptureAuthorizedTransactionCallback {
    public abstract void handle(RetailSDKException error, String captureId);

    @Override
    public void captureAuthorizedTransaction(RetailSDKException error, String captureId) {
      this.handle(error, captureId);
    }
  }
  //</editor-fold>

  static V8Object getJSClass(String className)
  {
    return sJsSdk.impl.getObject(className);
  }


  public static V8Array jsArgs()
  {
    return PayPalRetailObject.getEngine().createJsArray();
  }

  @Target(ElementType.METHOD)
  @Retention(RetentionPolicy.RUNTIME)
  private @interface SdkInitialized
  {
  }

  @Target(ElementType.METHOD)
  @Retention(RetentionPolicy.RUNTIME)
  private @interface MerchantInitialized
  {
  }

  private static void validate()
  {
    /* Why throw in a Try-Catch Block.  Why introduce this to develop (v2.9.0) branch which is stable.
    try
    {
      Method method = RetailSDK.class.getMethod(Thread.currentThread().getStackTrace()[3].getMethodName());
      SdkInitialized sdkInit = method.getAnnotation(SdkInitialized.class);
      if (sdkInit != null && sJsSdk == null)
      {
        throw new SdkNotInitializedException("SDK was not initialized");
      }

      MerchantInitialized merchantInit = method.getAnnotation(MerchantInitialized.class);
      if (merchantInit != null && sJsSdk.getMerchant() == null)
      {
        throw new MerchantNotInitializedException("Merchant was not initialized");
      }
    }
    catch (NoSuchMethodException ex)
    {
    }
    */
  }
}
