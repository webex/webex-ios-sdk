# Cisco Webex iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/WebexSDK.svg)](https://cocoapods.org/pods/WebexSDK)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![license](https://img.shields.io/github/license/webex/webex-ios-sdk.svg)](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE)

The Cisco Webex iOS SDK makes it easy to integrate and secure messaging, meeting and calling features in your iOS apps.

## Installation

> **Important — CocoaPods stops accepting new versions on 2 December 2026.**
> The CocoaPods trunk becomes permanently read-only on that date and will no longer accept new pod versions, as announced in the [CocoaPods Trunk Read-only Plan](https://blog.cocoapods.org/CocoaPods-Specs-Repo/). WebexSDK releases published after that date will be available through Swift Package Manager only, so you must migrate to Swift Package Manager to keep receiving new releases, including fixes and security updates. Existing Podfiles continue to resolve the versions published before the cutoff, so current builds will not break.

The SDK can be integrated using either CocoaPods or Swift Package Manager. Both channels deliver the same binaries, and in both cases you write `import WebexSDK` in your code.

- **CocoaPods** — available for releases published up to 2 December 2026. Minimum iOS deployment target 13.0.
- **Swift Package Manager** — available from WebexSDK `3.17.0` onward, and the only channel for releases published after 2 December 2026. Requires Xcode 15 or later and a minimum iOS deployment target of 15.0. Releases `3.16.2` and earlier are CocoaPods only.

## SDK types:

- Message SDK : WebexSDK/Message
     - This is a lightweight SDK which supports only messaging features
     - It does not support calling and meeting related features

Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK/Message'
end
```

Swift Package Manager product: `WebexSDKMessage`

- WebexCalling SDK : WebexSDK/Wxc
     - This SDK supports only WebexCalling feature
     - It does not support CUCM calling

Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK/Wxc'
end
```

Swift Package Manager product: `WebexSDKWxc`

 - Meeting SDK : WebexSDK/Meeting
     - This SDK supports Messaging and Meeting features
     - It does not support CUCM Calling or Webex Calling
     
Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK/Meeting'
end
```

Swift Package Manager product: `WebexSDKMeeting`

 - Full SDK : WebexSDK
     - Supports all the features.
     - Details of all features can be found [here](https://developer.webex.com/calling/docs/sdks/ios-sdk-overview)
     
Pod usage:

```
target 'MyApp' do
  pod 'WebexSDK'
end
```

Swift Package Manager product: `WebexSDK`

 All the SDKs are independent of each other. Developers can use either one of them to fulfil their use case.

 - Broadcast Extension Kit : WebexBroadcastExtensionKit
     - Required only for screen sharing from a Broadcast Upload Extension
     - Added to your Broadcast Upload Extension target, not your app target

Pod usage:

```
target 'MyBroadcastExtension' do
  pod 'WebexBroadcastExtensionKit'
end
```

Swift Package Manager product: `WebexBroadcastExtensionKit`

## Using Swift Package Manager

From WebexSDK `3.17.0` onward the SDK can be integrated with Swift Package Manager, in addition to CocoaPods. From 2 December 2026 it becomes the only channel for new releases, so existing CocoaPods integrations should plan to migrate before then.

In Xcode, choose **File ▸ Add Package Dependencies…** and enter the package URL:

```
https://github.com/webex/webex-ios-sdk
```

Set the dependency rule to **Up to Next Major Version** starting at `3.17.0`, then add **one** WebexSDK product to your app target.

If your app is itself a Swift package, declare the dependency in `Package.swift`:

```
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyWebexApp",
    platforms: [.iOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/webex/webex-ios-sdk", from: "3.17.0")
    ],
    targets: [
        .target(
            name: "MyWebexApp",
            dependencies: [
                .product(name: "WebexSDK", package: "webex-ios-sdk")
            ]
        )
    ]
)
```

The five products map to the CocoaPods flavors as follows:

| Swift Package Manager product | Equivalent pod |
| --- | --- |
| `WebexSDK` | `pod 'WebexSDK'` (Full) |
| `WebexSDKMeeting` | `pod 'WebexSDK/Meeting'` |
| `WebexSDKWxc` | `pod 'WebexSDK/Wxc'` |
| `WebexSDKMessage` | `pod 'WebexSDK/Message'` |
| `WebexBroadcastExtensionKit` | `pod 'WebexBroadcastExtensionKit'` |

Add only one of the four WebexSDK products to your app target. Whichever you pick, the module name is always `WebexSDK`, so the import statement is always `import WebexSDK`.

`WebexBroadcastExtensionKit` is the exception: attach it to your Broadcast Upload Extension target rather than your app target, and import it as `import WebexBroadcastExtensionKit`. See [Broadcast Upload Extension for Screen Sharing](https://github.com/webex/webex-ios-sdk/wiki/Broadcast-Upload-Extension-for-Screen-Sharing).

For the full walkthrough, see [Integrating SDK with App using Swift Package Manager](https://github.com/webex/webex-ios-sdk/wiki/Integrating-SDK-with-App-using-Swift-Package-Manager).

## Documentation
- [Requirements & Feature List](https://developer.webex.com/calling/docs/sdks/ios-sdk-overview)
- [Guides](https://github.com/webex/webex-ios-sdk/wiki)
- [Integrating SDK with App using Swift Package Manager](https://github.com/webex/webex-ios-sdk/wiki/Integrating-SDK-with-App-using-Swift-Package-Manager)
- [API Reference](https://webex.github.io/webex-ios-sdk/)
- [Kitchen Sink Sample App](https://github.com/webex/webex-ios-sdk-example)

## Support
- [Webex Developer Support ](https://developer.webex.com/support)
- Email: devsupport@webex.com

## License

&copy; 2016-2026 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
