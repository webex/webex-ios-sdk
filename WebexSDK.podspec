Pod::Spec.new do |s|
  s.name = "WebexSDK"
  s.version = "2.7.0"
  s.summary = "Webex iOS SDK"
  s.homepage = "https://developer.webex.com"
  s.license = "MIT"
  s.author = { "Webex SDK team" => "spark-sdk-crdc@cisco.com" }
  s.source = { :git => "https://github.com/webex/webex-ios-sdk.git", :tag => s.version }
  s.ios.deployment_target = "10.0"
  s.source_files = "Source/**/*.{h,m,swift}"
  s.preserve_paths = 'Frameworks/*.framework'
  s.vendored_frameworks = 'Frameworks/*.framework'
  s.xcconfig = {'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/WebexSDK/Frameworks',
                'ENABLE_BITCODE' => 'NO',
                }
  s.swift_version = '4.2'                
  s.dependency 'Alamofire', '~> 5.2.0'
  s.dependency 'ObjectMapper', '~> 4.2.0'
  s.dependency 'SwiftyJSON', '~> 4.1'
  s.dependency 'Starscream', '~> 4.0.4'
  s.dependency 'KeychainAccess', '~> 3.1'

end
