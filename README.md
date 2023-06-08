# Cisco Webex iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/WebexSDK.svg)](https://cocoapods.org/pods/WebexSDK)
[![license](https://img.shields.io/github/license/webex/webex-ios-sdk.svg)](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE)

The Cisco Webex iOS SDK makes it easy to integrate and secure messaging, meeting and calling features in your iOS apps.

## SDK types:

- WebexCalling SDK : WebexSDK/Wxc
     - This SDK supports only WebexCalling feature
     - It does not support CUCM calling

Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK/Wxc'
end
```

 - Meeting SDK : WebexSDK/Meeting
     - This SDK supports Messaging and Meeting features
     - It does not support CUCM Calling or Webex Calling
     
Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK/Meeting'
end
```

 - Full SDK : WebexSDK
     - Supports all the features.
     - Details of all features can be found [here](https://developer.webex.com/docs/sdks/ios)
     
Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK'
end
```

#If you face the Problem: "Getting multiple commands produce error"
#The root-cause: If we don't explicitly specify the flavour(subspec) in pod file(eg: WebexSDK/Full), Xcode's new build system's build optimizer is not able to infer which version of the embedded frameworks to use and throws this error.
#Solution:
#solution 1) pod 'WebexSDK/Full','~> 3.9.0'
#solution 2) add  install! 'cocoapods', :disable_input_output_paths => true in pod file.

 All the SDKs are independent of each other. Developers can use either one of them to fulfil their use case.
 
## Documentation
- [Requirements & Feature List](https://developer.webex.com/docs/sdks/ios)
- [Guides](https://github.com/webex/webex-ios-sdk/wiki)
- [API Reference](https://webex.github.io/webex-ios-sdk/)
- [Kitchen Sink Sample App](https://github.com/webex/webex-ios-sdk-example)

## Support
- [Webex Developer Support ](https://developer.webex.com/support)
- Email: devsupport@webex.com

## License

&copy; 2016-2023 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
