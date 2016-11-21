Pod::Spec.new do |s|
  s.name = 'HereSDK'
  s.version = '0.7.0'
  s.summary = 'Retail SDK'
  s.license = 'MS-RSL'
  s.authors = {"PayPal"=>"DL-PP-RetailSDK@paypal.com"}
  s.homepage = 'https://github.com/PayPal-Mobile/paypal-retail-sdk'
  s.description = 'Retail SDK'
  s.requires_arc = true
  s.source = { :path => '.' }

  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration', 'JavaScriptCore'

  s.ios.deployment_target    = '7.0'
  s.ios.preserve_paths       = 'HereSDK.framework'
  s.ios.public_header_files  = 'HereSDK.framework/Versions/A/Headers/*.h'
  s.ios.resource             = 'HereSDK.framework/Versions/A/Resources/**/*'
  s.ios.vendored_frameworks  = 'HereSDK.framework'
end
