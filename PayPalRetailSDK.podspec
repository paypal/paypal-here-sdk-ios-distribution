Pod::Spec.new do |s|
  s.name             = "PayPalRetailSDK"
  s.version          = "2.0.0.201801"
  s.summary          = "SDK for interfacing with PayPal card readers and mobile payment processing APIs."
  s.license          = { :file => 'License.md' }
  s.authors          = {"PayPal"=>"DL-PP-RetailSDK@paypal.com"}
  s.homepage         = "https://github.com/paypal/paypal-here-sdk-ios-distribution"
  s.description      = "PayPal Retail SDK"
  s.source           = { :git => 'https://github.com/PayPal-Mobile/ios-here-sdk-dist.git', :tag => "v#{s.version}" }

  s.requires_arc = true
  s.ios.deployment_target    = '8.1'

  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited)',
    'OTHER_LDFLAGS' => '-weak_library /usr/lib/libstdc++.dylib -lstdc++ -ObjC',
  }

  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration', 'JavaScriptCore', 'CoreBluetooth', 'UIKit', 'CoreLocation'

  s.default_subspec = 'Debug'

  s.subspec 'Debug' do |sp|
    sp.vendored_frameworks      = 'RSDK/Debug/PayPalRetailSDK.framework', 'frameworks/PPHSwiper.framework', 'frameworks/PPHR_BLE.framework', 'frameworks/PPHSDK_BLE.framework'
    sp.ios.preserve_paths       = 'RSDK/Debug/PayPalRetailSDK.framework'   
    sp.ios.public_header_files  = 'RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Headers/*.h'   
    sp.ios.resource             = 'RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/**/*'
  end

  s.subspec 'Release' do |sp|
    sp.vendored_frameworks      = 'RSDK/Release/PayPalRetailSDK.framework', 'frameworks/PPHSwiper.framework', 'frameworks/PPHR_BLE.framework', 'frameworks/PPHSDK_BLE.framework'
    sp.ios.preserve_paths       = 'RSDK/Release/PayPalRetailSDK.framework'   
    sp.ios.public_header_files  = 'RSDK/Release/PayPalRetailSDK.framework/Versions/A/Headers/*.h'   
    sp.ios.resource             = 'RSDK/Release/PayPalRetailSDK.framework/Versions/A/Resources/**/*'    
  end

  s.dependency 'SimpleKeychain', '~> 0.6.1'

end