Pod::Spec.new do |s|
  s.name             = "PayPalRetailSDK"
  s.version          = "3.0.6"
  s.summary          = "SDK for interfacing with PayPal card readers and mobile payment processing APIs."
  s.license          = "COMMERCIAL"
  s.authors          = {"PayPal"=>"DL-PP-RetailSDK@paypal.com"}
  s.homepage         = "https://github.com/PayPal-Mobile/paypal-retail-sdk"
  s.description      = "Retail SDK"
  s.source           = { :git => 'https://github.com/PayPal-Mobile/ios-here-sdk-dist.git', :tag => "v#{s.version}" }

  s.requires_arc = true
  s.ios.deployment_target    = '8.1'
  s.ios.vendored_framework   = 'ios/PayPalRetailSDK.framework'

  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration', 'JavaScriptCore', 'CoreBluetooth', 'UIKit', 'CoreLocation'


  s.subspec 'Debug' do |sp|
    sp.vendored_frameworks      = 'SDK/Debug/PayPalHereSDK.framework', 'frameworks/G4XSwiper.framework', 'frameworks/RUA_BLE.framework', 'frameworks/LandiSDK_BLE.framework'
    sp.resource                 = 'SDK/Debug/PayPalHereSDK.bundle'
    sp.ios.preserve_paths       = 'SDK/Debug/PayPalRetailSDK.framework'
    sp.ios.public_header_files  = 'SDK/Debug/PayPalRetailSDK.framework/Versions/A/Headers/*.h'
    sp.ios.resource             = 'SDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/**/*'
  end

  s.subspec 'Release' do |sp|
    sp.vendored_frameworks      = 'SDK/Release/PayPalHereSDK.framework', 'frameworks/G4XSwiper.framework', 'frameworks/RUA_BLE.framework', 'frameworks/LandiSDK_BLE.framework'
    sp.resource                 = 'SDK/Release/PayPalHereSDK.bundle'
    sp.ios.preserve_paths       = 'SDK/Release/PayPalRetailSDK.framework'
    sp.ios.public_header_files  = 'SDK/Release/PayPalRetailSDK.framework/Versions/A/Headers/*.h'
    sp.ios.resource             = 'SDK/Release/PayPalRetailSDK.framework/Versions/A/Resources/**/*'
  end

  s.dependency 'SimpleKeychain', '~> 0.6.1'

end