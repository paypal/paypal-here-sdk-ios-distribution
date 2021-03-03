//
//  InitializeViewModel.swift
//  PPHSDKSampleApp
//
//  Created by Pranav Bhandari on 3/2/21.
//  Copyright © 2021 cowright. All rights reserved.
//

import Foundation

class InitializeViewModel {
  var initSdkText: String {
    return "PayPalRetailSDK.initializeSDK()"
  }
  
  var initMerchText: String {
    return "PayPalRetailSDK.initializeMerchant(withCredentials: sdkCreds) { (error, merchant) in \n" +
      "     <code to handle success/failure>\n" +
      "})"
  }
  
  var initOfflineText: String {
    return "PayPalRetailSDK.initializeMerchantOffline { (error, merchant) in \n" +
      "     <code to handle success/failure>\n" +
      "})"
  }
}
