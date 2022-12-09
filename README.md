# Cisco Webex iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/WebexSDK.svg)](https://cocoapods.org/pods/WebexSDK)
[![license](https://img.shields.io/github/license/webex/webex-ios-sdk.svg)](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE)

The Cisco Webex iOS SDK makes it easy to integrate and secure messaging, meeting and calling features in your iOS apps.

## NOTE: This is meant to be an evaluation-only build and stability of this build is not guaranteed. Please get in touch with Cisco support for any build specific issues.

 ## Guide for integrating alpha/beta/hotfix versions of WebexSDK and WebexBroadcastextensionKit pods into your projects
 1. Download and extract `WebexSDK.zip` and `WebexBroadcastExtensionKit.zip` from the alpha/beta/hotfix branch
 2. After extraction, the pods should be inside two folders: `WebexSDK` and `WebexBroadcastExtensionKit`
 3. Modify your project `Podfile` as the following example:

    ```ruby
    target 'KitchenSink' do
    use_frameworks!

    # Pods for KitchenSink
        pod 'WebexSDK', :path => '/path/to/WebexSDK'

    target 'KitchenSinkUITests' do
        # Pods for testing
    end

    end

    target 'KitchenSinkBroadcastExtension' do
    use_frameworks!

    # Pods for KitchenSinkBroadcastExtension 
    pod 'WebexBroadcastExtensionKit',:path => '/path/to/WebexBroadcastExtensionKit'
    end
    ```

## Documentation
- [Requirements & Feature List](https://developer.webex.com/docs/sdks/ios)
- [Guides](https://github.com/webex/webex-ios-sdk/wiki)
- [API Reference](https://webex.github.io/webex-ios-sdk/)
- [Kitchen Sink Sample App](https://github.com/webex/webex-ios-sdk-example)

## Support
- [Webex Developer Support ](https://developer.webex.com/support)
- Email: devsupport@webex.com

## License

&copy; 2016-2022 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
