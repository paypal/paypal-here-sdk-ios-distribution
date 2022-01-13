Pod::Spec.new do |s|
  s.name             = "PayPalHereSDKv2"
  s.version          = "2.4.0021363000"
  s.homepage         = 'https://developer.paypal.com/docs/integration/paypal-here/'
  s.source           = { :git => 'https://github.com/paypal/paypal-here-sdk-ios-distribution.git', :tag => "sdk_v#{s.version}" }
  s.summary          = 'SDK for interfacing with PayPal card readers and mobile payment processing APIs.'
  s.description      = 'The PayPal Here SDK v2 for iOS provides access to a group of PayPal transaction services which contain an extensive set of point-of-sale functions for merchants.'
  s.license          = { :type => 'PAYPAL', :file => 'LICENSE.md' }
  s.authors          = { 'PayPal' => 'DL-PP-PPH-SDK-Admin@paypal.com' }
  

  s.requires_arc = true
  s.ios.deployment_target    = '10.0'

  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited)'
  }

  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration', 'JavaScriptCore', 'CoreBluetooth', 'UIKit', 'CoreLocation'

  s.default_subspec = 'Debug'

  s.subspec 'Debug' do |sp|
    sp.vendored_frameworks = 'RSDK/Debug/PayPalRetailSDK.xcframework', 'frameworks/PPHSwiper.xcframework', 'frameworks/PPHR_BLE.xcframework', 'frameworks/PPHSDK_BLE.xcframework'
  end

  s.subspec 'Release' do |sp|
    sp.vendored_frameworks = 'RSDK/Release/PayPalRetailSDK.xcframework', 'frameworks/PPHSwiper.xcframework', 'frameworks/PPHR_BLE.xcframework', 'frameworks/PPHSDK_BLE.xcframework'
  end


  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.dependency 'SimpleKeychain', '~> 0.11.1'
  s.dependency 'PPRetailInstrumentInterface'
  s.dependency 'TrustKit', '~> 1.6.5'

end
