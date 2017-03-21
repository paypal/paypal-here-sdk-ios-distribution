Pod::Spec.new do |s|
  s.name = 'PayPalRetailSDK'
  s.version = '0.6.0'
  s.summary = 'Retail SDK'
  s.license = 'MS-RSL'
  s.authors = {"PayPal"=>"DL-PP-RetailSDK@paypal.com"}
  s.homepage = 'https://github.com/PayPal-Mobile/paypal-retail-sdk'
  s.description = 'Retail SDK'
  s.requires_arc = true
  s.source = { :path => '.' }

  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration', 'JavaScriptCore'

  s.ios.deployment_target    = '7.0'
  s.ios.preserve_paths       = 'ios/PayPalRetailSDK.framework'
  s.ios.public_header_files  = 'ios/PayPalRetailSDK.framework/Versions/A/Headers/*.h'
  s.ios.resource             = 'ios/PayPalRetailSDK.framework/Versions/A/Resources/**/*'
  s.ios.vendored_frameworks  = 'ios/PayPalRetailSDK.framework'
  s.osx.deployment_target    = '10.10'
  s.osx.preserve_paths       = 'osx/PayPalRetailSDK.framework'
  s.osx.public_header_files  = 'osx/PayPalRetailSDK.framework/Versions/A/Headers/*.h'
  s.osx.resource             = 'osx/PayPalRetailSDK.framework/Versions/A/Resources/**/*'
  s.osx.vendored_frameworks  = 'osx/PayPalRetailSDK.framework'
end
