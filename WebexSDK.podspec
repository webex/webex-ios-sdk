Pod::Spec.new do |s|
  s.name = "WebexSDK"
  s.version = "0.0.1"
  s.summary = "Webex iOS SDK"
  s.homepage = "https://developer.webex.com"
  s.license = "MIT"
  s.author = { "Webex SDK team" => "spark-sdk-crdc@cisco.com" }
  s.source = { :git => "https://github.com/webex/webex-ios-sdk.git", :tag => s.version, :submodules => true }
  s.ios.deployment_target = "10.0"
  s.source_files = "Source/**/*.{h,m,swift}"
  s.preserve_paths = 'Frameworks/*.framework'
  s.xcconfig = {'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/WebexSDK/Frameworks',
                'ENABLE_BITCODE' => 'NO',
                }
  s.vendored_frameworks = "Frameworks/*.framework"
  spec.subspec 'Alamofire' do |alamo|
    alamo.source = { :git => "https://github.com/Alamofire/Alamofire.git", :tag => "4.7.1" }
    alamo.source_files = 'Alamofire/**/*.{Source/**/*.{h,m,swift}'
  end
  spec.subspec 'ObjectMapper' do |om|
    om.source = { :git => "https://github.com/Hearst-DD/ObjectMapper.git", :tag => "3.1" }
    om.source_files = 'ObjectMapper/**/*.{Source/**/*.{h,m,swift}'
  end
  spec.subspec 'AlamofireObjectMapper' do |alamom|
    alamom.source = { :git => "https://github.com/tristanhimmelman/AlamofireObjectMapper.git", :tag => "5.0" }
    alamom.source_files = 'AlamofireObjectMapper/**/*.{Source/**/*.{h,m,swift}'
  end
  spec.subspec 'SwiftyJSON' do |sj|
    sj.source = { :git => "https://github.com/SwiftyJSON/SwiftyJSON.git", :tag => "4.0" }
    sj.source_files = 'SwiftyJSON/**/*.{Source/**/*.{h,m,swift}'
  end
  spec.subspec 'Starscream' do |sc|
    sc.source = { :git => "https://github.com/daltoniam/Starscream.git", :tag => "3.0.5" }
    sc.source_files = 'Starscream/**/*.{Source/**/*.{h,m,swift}'
  end
  spec.subspec 'KeychainAccess' do |ka|
    ka.source = { :git => "https://github.com/kishikawakatsumi/KeychainAccess.git", :tag => "3.1" }
    ka.source_files = 'KeychainAccess/**/*.{Source/**/*.{h,m,swift}'
  end
end