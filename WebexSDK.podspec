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

  s.subspec 'Alamofire' do |af|
    af.source_files = 'Frameworks/External/Alamofire/Source/**/*.{h,m,swift}'
  end

  s.subspec 'ObjectMapper' do |ob|
    ob.source_files = 'Frameworks/External/ObjectMapper/Sources/**/*.{h,m,swift}'
  end

  s.subspec 'AlamofireObjectMapper' do |ao|
    ao.source_files = 'Frameworks/External/AlamofireObjectMapper/AlamofireObjectMapper/**/*.{h,m,swift}'
  end

  s.subspec 'SwiftyJSON' do |sj|
    sj.source_files = 'Frameworks/External/SwiftyJSON/Source/**/*.{h,m,swift}'
  end

  s.subspec 'Starscream' do |st|
    st.resources = 'Frameworks/External/Starscream/zlib/**/*'
    st.source_files = 'Frameworks/External/Starscream/Sources/**/*.{h,m,swift}'
  end

  s.subspec 'KeychainAccess' do |ka|
    ka.source_files = 'Frameworks/External/KeychainAccess/Lib/KeychainAccess/**/*.{h,m,swift}'
  end

  s.module_map = 'Frameworks/External/Starscream/zlib/module.modulemap'

end