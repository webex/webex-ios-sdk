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

  s.vendored_frameworks = "Frameworks/*.framework"

   s.subspec 'Alamofire' do |af|
    af.resources = 'Frameworks/External/Alamofire/Source/**/*'
  end

  s.subspec 'ObjectMapper' do |ob|
    ob.resources = 'Frameworks/External/ObjectMapper/Sources/**/*'
  end

  s.subspec 'SwiftyJSON' do |sj|
    sj.resources = 'Frameworks/External/SwiftyJSON/Source/**/*'
  end

  s.subspec 'Starscream' do |st|
    st.resources = 'Frameworks/External/Starscream/Sources/**/*'
  end

  s.subspec 'KeychainAccess' do |ka|
    ka.resources = 'Frameworks/External/KeychainAccess/Lib/KeychainAccess/**/*'
  end

  s.script_phase = { :name => 'Hello World', 
                     :script => 'xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/KeyChainAccess/Lib/KeyChainAccess.xcodeproj -scheme "KeychainAccess" build -derivedDataPath Build/
                                 xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/StarScream/Starscream.xcodeproj -scheme "Starscream" build -derivedDataPath Build/
                                 xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/Alamofire/Alamofire.xcodeproj -scheme "Alamofire iOS" build -derivedDataPath Build/  
                                 xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/ObjectMapper/ObjectMapper.xcodeproj -scheme "ObjectMapper-iOS" build -derivedDataPath Build/
                                 xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/SwiftyJSON/SwiftyJSON.xcodeproj -scheme "SwiftyJSON iOS" build -derivedDataPath Build/
                                 xcodebuild -project ${PODS_ROOT}/WebexSDK/Frameworks/External/AlamofireObjectMapper/AlamofireObjectMapper.xcodeproj -scheme "AlamofireObjectMapper iOS" build -derivedDataPath Build/
                                 dst=${PODS_ROOT}/WebexSDK/Frameworks
                                 from=${PODS_ROOT}/WebexSDK/Build/Build/Products/Debug-iphoneos
                                 mkdir -p "${dst}"
                                 cp -r "$from/Alamofire.framework" "$dst"
                                 cp -r "$from/ObjectMapper.framework" "$dst"
                                 cp -r "$from/SwiftyJSON.framework" "$dst"
                                 cp -r "$from/AlamofireObjectMapper.framework" "$dst"
                                 from=${PODS_ROOT}/WebexSDK/Build/Build/Products/Debug
                                 cp -r "$from/Starscream.framework" "$dst"
                                 cp -r "$from/KeychainAccess.framework" "$dst"', 
    :execution_position => :before_compile }

  s.xcconfig = {'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/WebexSDK/Frameworks',
              'ENABLE_BITCODE' => 'NO',
              }

end
