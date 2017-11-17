//package com.paypal.paypalretailsdk;
//
//import java.io.BufferedReader;
//import java.io.File;
//import java.io.FileInputStream;
//import java.io.FileReader;
//
//import android.bluetooth.BluetoothAdapter;
//import android.os.Handler;
//import android.test.mock.MockContext;
//import android.test.mock.MockResources;
//import android.util.Log;
//import org.junit.Before;
//import org.junit.BeforeClass;
//import org.junit.Test;
//import org.junit.runner.RunWith;
//import org.mockito.invocation.InvocationOnMock;
//import org.mockito.stubbing.Answer;
//import org.powermock.api.mockito.PowerMockito;
//import org.powermock.core.classloader.annotations.PowerMockIgnore;
//import org.powermock.core.classloader.annotations.PrepareForTest;
//import org.powermock.modules.junit4.PowerMockRunner;
//
//import static org.mockito.Matchers.*;
//import static org.mockito.Mockito.mock;
//import static org.mockito.Mockito.when;
//
///**
// * Because of the fact that J2V8 can't be active in multiple class loaders, and gradle/android junit doesn't
// * support passing a forkEvery parameter (that I can find), we have to use a single class for all the tests.
// * To make it easier to undo when this problem is fixed, I've kept the individual test classes and just
// * "indexed" them here.
// *
// * Created by mmetral on 5/1/15.
// */
// @PowerMockIgnore("javax.net.ssl.*")
// @PrepareForTest({Log.class, BluetoothAdapter.class})
// @RunWith(PowerMockRunner.class)
//public class BaseTest
//{
//  static MockContext _mockContext;
//  static MockResources _mockResources;
//  static Handler _mockHandler;
//  static String _testToken;
//
//  @Before
//  public void mockAndroids() throws Exception {
//    // Mock the Android logging framework because it doesn't exist during JUnit and we like logs.
//    PowerMockito.mockStatic(Log.class);
//    PowerMockito.when(Log.d(anyString(), anyString())).thenAnswer(new Answer()
//    {
//      public Object answer(InvocationOnMock invocation)
//      {
//        Object[] args = invocation.getArguments();
//        System.out.println(args[0].toString() + " " + args[1].toString());
//        return 0;
//      }
//    });
//    PowerMockito.when(Log.e(anyString(), anyString())).thenAnswer(new Answer()
//    {
//      public Object answer(InvocationOnMock invocation)
//      {
//        Object[] args = invocation.getArguments();
//        System.out.println(args[0].toString() + " " + args[1].toString());
//        return 0;
//      }
//    });
//
//    // Mock bluetooth
//    PowerMockito.mockStatic(BluetoothAdapter.class);
//    PowerMockito.when(BluetoothAdapter.getDefaultAdapter()).thenReturn(null);
//  }
//
//  @BeforeClass
//  public static void mockJS() throws Exception
//  {
//    // Fake the javascript loading mechanism to go against the local disk since the
//    // resource loader isn't available.
//    if (_mockContext == null)
//    {
//      _mockContext = mock(MockContext.class);
//      _mockResources = mock(MockResources.class);
//
//      String basePath = BaseTest.class.getResource("BaseTest.class").getPath();
//      File basePathDir = new File(basePath);
//      while (!basePathDir.getName().equalsIgnoreCase("sdk"))
//      {
//        basePathDir = basePathDir.getParentFile();
//      }
//      File jsPath = new File(basePathDir, "src/main/res/raw/paypalretailsdk.js");
//
//      // Keep going up and get the test token
//      while (!basePathDir.getName().equalsIgnoreCase("platform")) {
//        basePathDir = basePathDir.getParentFile();
//      }
//      basePathDir = basePathDir.getParentFile();
//      _testToken = new BufferedReader(new FileReader(new File(basePathDir, "testToken.txt"))).readLine();
//      when(_mockContext.getResources()).thenReturn(_mockResources);
//      when(_mockResources.openRawResource(anyInt())).thenReturn(new FileInputStream(jsPath));
//    }
//  }
//
//  @Test
//  public void initTest() throws Exception {
//    new InitializeTest().initialize(_mockContext);
//  }
//
//  @Test
//  public void makeInvoiceTest() throws Exception {
//    new InitializeTest().makeInvoice(_mockContext);
//  }
//
//  @Test
//  public void initializeMerchantTest() throws Exception {
//    new InitializeTest().initializeMerchant(_mockContext, _testToken);
//  }
//}
