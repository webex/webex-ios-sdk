source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared_pods
	platform :ios, '10.0'
    pod 'Alamofire', '~> 4.7.3'
    pod 'ObjectMapper', '~> 3.3'
    pod 'AlamofireObjectMapper', '~> 5.1'
    pod 'SwiftyJSON', '~> 4.1'
    pod 'Starscream', '~> 3.0.5'
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
