Pod::Spec.new do |s|
  s.name             = 'PayPalHereSDK'
  s.version          = '1.6.8'
  s.summary          = 'SDK for interfacing with PayPal card readers and mobile payment processing APIs.'
  s.license          = 'COMMERCIAL'
  s.homepage         = 'https://developer.paypal.com/docs/integration/paypal-here/ios-dev/overview/'
  s.author           = { 'PayPal' => 'paypal' }
  s.source           = { :git => 'https://github.com/PayPal-Mobile/ios-here-sdk-dist.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited)',
    'OTHER_LDFLAGS' => '$(inherited) -lstdc++ -stdlib=libstdc++ -ObjC',
  }

  s.ios.libraries = 'sqlite3', 'z', 'xml2'
  s.ios.frameworks = 'AudioToolbox', 'MobileCoreServices', 'Security', 'CFNetwork', 'AVFoundation', 'ExternalAccessory', 'MediaPlayer', 'CoreTelephony', 'Foundation', 'CoreBluetooth', 'SystemConfiguration'

  s.default_subspec = 'Debug'

  s.subspec 'Debug' do |sp|
    sp.vendored_frameworks = 'SDK/Debug/PayPalHereSDK.framework'
    sp.resource = 'SDK/Debug/PayPalHereSDK.bundle'
  end

  s.subspec 'Release' do |sp|
    sp.vendored_frameworks = 'SDK/Release/PayPalHereSDK.framework'
    sp.resource = 'SDK/Release/PayPalHereSDK.bundle'
  end

  s.subspec 'Debug-nohw' do |sp|
    sp.vendored_frameworks = 'SDK/nohw/Debug/PayPalHereSDK.framework'
    sp.resource = 'SDK/nohw/Debug/PayPalHereSDK.bundle'
  end

  s.subspec 'Release-nohw' do |sp|
    sp.vendored_frameworks = 'SDK/nohw/Release/PayPalHereSDK.framework'
    sp.resource = 'SDK/nohw/Release/PayPalHereSDK.bundle'
  end
end
