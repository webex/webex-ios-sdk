Pod::Spec.new do |s|
  s.name = "WebexBroadcastExtensionKit"
  s.version = "2.4.0"
  s.summary = "iOS Broadcast Extension Kit for Webex iOS SDK"
  s.homepage = "https://developer.webex.com"
  s.license = "MIT"
  s.author = { "Webex SDK team" => "spark-sdk-crdc@cisco.com" }
  s.source = { :git => "https://github.com/webex/webex-ios-sdk.git", :tag => "2.4.0" }
  s.ios.deployment_target = "11.2"  
  s.source_files = "Exts/BroadcastExtensionKit/WebexBroadcastExtensionKit/**/*.{h,m,swift}"
  s.preserve_paths = 'Frameworks/*.framework'
  s.xcconfig = {'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/WebexBroadcastExtensionKit/Frameworks',
                'ENABLE_BITCODE' => 'NO',
                }
  s.swift_version = '5.0'                
end
