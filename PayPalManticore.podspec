Pod::Spec.new do |s|
  
  s.name             = "PayPalManticore"
  s.version          = "1.0.0"
  s.summary          = "A runtime to expose Javascript classes, logic and code to native components in OS X and iOS"
  s.description      = %{
paypal-manticore runs Javascript on OS X and iOS and allows interaction between native code and JS objects via "shims"
that manage type marshaling, callbacks (both directions) and objects/methods. It is most useful in cases where you want
*broad* platform compatibility (all the way to WinXP) but do not want a cross platform UI solution (e.g. React Native).
In theory, Javascript written for Manticore will also work in React Native, but sometimes you want consolidated business
logic but not consolidated UI code.
    }
  s.homepage         = "https://github.com/paypal/manticore"
  s.license          = 'PayPal'
  s.author           = { "PayPal" => "DL-PP-RetailSDK@paypal.com" }
  s.source           = { :git => "git@github.com:paypal/manticore.git", :tag => s.version.to_s }
  
  s.requires_arc = true
  
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  
  source_folders = [
    'runtime/objc/Manticore/',
  ]

  s.resource_bundle = {
    'PayPalManticoreResources' => [
      'runtime/objc/js/polyfill.pack.js',
    ]
  }
  
  s.frameworks = [
    'Foundation',
    'JavaScriptCore',
  ]
  
  s.source_files = source_folders.map {|f| f + '*.{h,m}'}
  s.public_header_files = source_folders.map {|f| f + '*.h'}
  
end