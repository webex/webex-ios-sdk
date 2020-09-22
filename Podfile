source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared_pods
    platform :ios, '10.0'
    pod 'Alamofire', '= 4.9.0'
    pod 'ObjectMapper', '~> 3.1'
    pod 'AlamofireObjectMapper', '~> 5.0'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'Starscream', '~> 4.0.4'
    pod 'KeychainAccess', '~> 3.1'
end

target 'WebexSDK' do
	shared_pods
end

target 'WebexSDKTests' do
	shared_pods
end

target 'WebexBroadcastExtensionKit' do
	platform :ios, '11.2'
end

target 'WebexBroadcastExtensionKitTests' do
	platform :ios, '11.2'
end
