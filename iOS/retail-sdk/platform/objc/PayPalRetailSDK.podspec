Pod::Spec.new do |s|

  s.name             = "PayPalRetailSDK"
  s.version          = "0.5.0"
  s.summary          = "Retail SDK"
  s.description      = %{
      Retail SDK
    }
  s.homepage         = "https://github.com/PayPal-Mobile/paypal-retail-sdk"
  s.license          = 'MS-RSL'
  s.author           = { "PayPal" => "DL-PP-RetailSDK@paypal.com" }
  s.source           = { :git => "git@github.paypal.com:RetailSDK-NewGen/objc-cocoapod-release-stage.git", :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'

  s.prefix_header_contents = '#import "PayPalRetailSDK+Private.h"'
  s.requires_arc = true

  objc_dir = ''

  # Despite the documentation, installing an empty subspec fails to inherit source_files from the parent spec.
  # So, instead of NoSwiperLib being empty, we setup both WithSwiperLib and NoSwiperLib exactly the same
  # except for the vendored_libraries.
  setup = lambda {|s|
    source_folders = [
      objc_dir + 'Common/',
      objc_dir + 'Common/generated/**/',
      # Get local manticore-objc files locally rather than fetching from cocoapods repo
      # to make builds easier and mitigate the need to push packages of manticore-objc for now.
      objc_dir + 'Common/manticore-objc/Manticore/',
      objc_dir + 'pph/**/'
    ]
    ios_source_folders = [
      objc_dir + 'iOS/PayPalRetailSDK/PayPalRetailSDK/**/',
      objc_dir + 'iOS/Roam/',
    ] + source_folders
    osx_source_folders = [
      objc_dir + 'osx/PayPalRetailSDK/PayPalRetailSDK/**/',
    ] + source_folders

    s.exclude_files = [
      objc_dir + 'Common/generated/PayPalRetailTest/**/*',
      objc_dir + 'Common/Tests/**/*',
    ]

    s.resource_bundle = {
      'PayPalRetailSDKResources' => [
        objc_dir + 'Common/AllPlatforms/PayPalRetailSDK.js',
        objc_dir + 'Common/AllPlatforms/sounds/*',
        objc_dir + 'iOS/PayPalRetailSDK/assets/*',
        objc_dir + 'iOS/PayPalRetailSDK/*.png',
      ]
    }

    s.public_header_files = [
      objc_dir + 'Common/generated/*.h',
      objc_dir + 'Common/PPRetailObject.h',
      objc_dir + 'Common/PayPalRetailSDK.h',
      objc_dir + 'Common/SdkCredential.h',
      objc_dir + 'pph/*.h'
    ]

    s.ios.frameworks = [
      'Foundation',
      'UIKit',
      'ExternalAccessory',
      'JavaScriptCore',
    ]
    s.osx.frameworks = [
      'Foundation',
      'AppKit',
    ]

    s.dependency 'SimpleKeychain', '~> 0.6.1'

    s.osx.dependency 'ORSSerialPort', '~> 1.7.1'

    s.ios.source_files = ios_source_folders.map {|f| f + '*.{h,m}'}

    s.osx.source_files = osx_source_folders.map {|f| f + '*.{h,m}'}

    s.xcconfig = {
      'OTHER_LDFLAGS' => '-weak_library /usr/lib/libstdc++.dylib',
    }

    s.libraries = 'c++', 'stdc++', 'z'

  }

  s.subspec "IncludeRoam" do |sp|
    setup[sp]
    sp.xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) INCLUDE_ROAM_AUDIO',
    }
    s.ios.vendored_libraries = [
      objc_dir + 'iOS/Roam/libSwiperAPI.a',
    ]
  end

  s.subspec "Default" do |sp|
    setup[sp]
    s.osx.deployment_target = '10.10'
  end

  s.default_subspec = "Default"

end
