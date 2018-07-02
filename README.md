# Cisco Webex iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/Webex.svg)](https://cocoapods.org/pods/Webex)
[![Travis CI](https://travis-ci.org/webex/webex-ios-sdk.svg?branch=master)](https://travis-ci.org/webex/webex-ios-sdk)
[![license](https://img.shields.io/github/license/webex/webex-ios-sdk.svg)](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE)

The Cisco Webex iOS SDK makes it easy to integrate secure and convenient Cisco Webex messaging and calling features in your iOS apps.

This SDK is written in [Swift 4](https://developer.apple.com/swift) and requires **iOS 10** or later.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [License](#license)

## Install

Assuming you already have an Xcode project, e.g. _MyWebexApp_, for your iOS app, here are the steps to integrate the Webex iOS SDK into your Xcode project using [CocoaPods](http://cocoapods.org):

1. Install CocoaPods:

    ```bash
    gem install cocoapods
    ```

2. Setup CocoaPods:

    ```bash
    pod setup
    ```

3. Create a new file, `Podfile`, with following content in your _MyWebexApp_ project directory:

    ```ruby
    source 'https://github.com/CocoaPods/Specs.git'
    
    use_frameworks!

    target 'MyWebexApp' do
      platform :ios, '10.0'
      pod 'WebexSDK'
    end
    
    target 'MyWebexAppBroadcastExtension' do
        platform :ios, '11.2'
        pod 'WebexBroadcastExtensionKit'
    end
    ```

4. Install the Webex iOS SDK from your _MyWebexApp_ project directory:

    ```bash
    pod install
    ```

## Usage

To use the SDK, you will need Cisco Webex integration credentials. If you do not already have a Cisco Webex account, visit [Webex for Developers](https://developer.webex.com/) to create your account and [register your integration](https://developer.webex.com/authentication.html#registering-your-integration). Your app will need to authenticate users via an [OAuth](https://oauth.net/) grant flow for existing Cisco Webex users or a [JSON Web Token](https://jwt.io/) for guest users without a Cisco Webex account.

See the [iOS SDK area](https://developer.webex.com/sdk-for-ios.html) of the Webex for Developers site for more information about this SDK.

### Example

Here are some examples of how to use the iOS SDK in your app.

1. Create the Webex instance using Webex ID authentication ([OAuth](https://oauth.net/)-based):

    ```swift
    let clientId = "$YOUR_CLIENT_ID"
    let clientSecret = "$YOUR_CLIENT_SECRET"
    let scope = "webex:all"
    let redirectUri = "Webexdemoapp://response"

    let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, scope: scope, redirectUri: redirectUri)
    let webex = Webex(authenticator: authenticator)

    if !authenticator.authorized {
        authenticator.authorize(parentViewController: self) { success in
            if !success {
                print("User not authorized")
            }
        }
    }
    ```

2. Create the Webex instance with Guest ID authentication ([JWT](https://jwt.io/)-based):

    ```swift
    let authenticator = JWTAuthenticator()
    let webex = Webex(authenticator: authenticator)

    if !authenticator.authorized {
        authenticator.authorizedWith(jwt: myJwt)
    }
    ```

3. Register the device to send and receive calls:

    ```swift
    webex.phone.register() { error in
        if let error = error {
            // Device not registered, and calls will not be sent or received
        } else {
            // Device registered
        }
    }
    ```

4. Use Webex service:

    ```swift
    webex.rooms.create(title: "Hello World") { response in
        switch response.result {
        case .success(let room):
            // ...
        case .failure(let error):
            // ...
        }
    }

    // ...

    webex.memberships.create(roomId: roomId, personEmail: email) { response in
        switch response.result {
        case .success(let membership):
            // ...
        case .failure(let error):
            // ...
        }
    }
    
    ```

5. Make an outgoing call:

    ```swift
    webex.phone.dial("coworker@acm.com", option: MediaOption.audioVideo(local: ..., remote: ...)) { ret in
        switch ret {
        case .success(let call):
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
        case .failure(let error):
            // failure
        }
    }
    ```

6. Receive a call:

    ```swift
    webex.phone.onIncoming = { call in
        call.answer(option: MediaOption.audioVideo(local: ..., remote: ...)) { error in
        if let error = error {
            // success
        }
        else {
            // failure
        }
    }
    ```

7. Make an room call:

    ```swift
    webex.phone.dial(roomId, option: MediaOption.audioVideo(local: ..., remote: ...)) { ret in
        switch ret {
        case .success(let call):
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
            call.onCallMembershipChanged = { changed in
                switch changed {
                case .joined(let membership):
                    //
                case .left(let membership):
                    //
                default:
                    //
                }                
            }            
        case .failure(let error):
            // failure
        }
    }
    ```
    
8. Screen share (view only):

    ```swift
    webex.phone.dial("coworker@acm.com", option: MediaOption.audioVideoScreenShare(video: (local: ..., remote: ...))) { ret in
        switch ret {
        case .success(let call):
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
            call.onMediaChanged = { changed in
                switch changed {
                    ...
                case .remoteSendingScreenShare(let sending):
                    call.screenShareRenderView = sending ? view : nil
                }
            }
        case .failure(let error):
            // failure
        }
    }
    ```
9. Post a message:
    ```
    webex.messages.post(personEmail: email, text: "Hello there") { response in
        switch response.result {
        case .success(let message):
            // ...
        case .failure(let error):
            // ...
        }
    }
    ```
10. Receive a message:
    ```
    webex.messages.onEvent = { messageEvent in
        switch messageEvent{
        case .messageReceived(let message):
            // ...
            break
        case .messageDeleted(let messageId):
            // ...
            break
        }
    }
    ```
11. Screen share (sending):

    11.1 In your containing app:
    ```swift
    webex.phone.dial("coworker@acm.com", option: MediaOption.audioVideoScreenShare(video: ..., screenShare: ..., applicationGroupIdentifier: "group.your.application.group.identifier"))) { ret in
        switch ret {
        case .success(let call):
            call.oniOSBroadcastingChanged = {
                event in
                if #available(iOS 11.2, *) {
                    switch event {
                    case .extensionConnected :
                        call.startSharing() {
                            error in
                            // ...
                        }
                        break
                    case .extensionDisconnected:
                        call.stopSharing() {
                            error in
                            // ...
                        }
                        break
                    }
                }
            }
            }
        case .failure(let error):
            // failure
        }
    }
    ```
    11.2 In your broadcast upload extension sample handler:
    ```swift
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        WebexBroadcastExtension.sharedInstance.start(applicationGroupIdentifier: "group.your.application.group.identifier") {
            error in
            if let webexError = error {
               // ...
            } else {
                WebexBroadcastExtension.sharedInstance.onError = {
                    error in
                    // ...
                }
                WebexBroadcastExtension.sharedInstance.onStateChange = {
                    state in
                    // state change
                }
            }
        }
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        WebexBroadcastExtension.sharedInstance.finish()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
            case RPSampleBufferType.video:
                // Handle video sample buffer
                WebexBroadcastExtension.sharedInstance.handleVideoSampleBuffer(sampleBuffer: sampleBuffer)
                break
            case RPSampleBufferType.audioApp:
                // Handle audio sample buffer for app audio
                break
            case RPSampleBufferType.audioMic:
                // Handle audio sample buffer for mic audio
                break
        }
    }
    ```
    11.3 Get more technical details about the [Containing App & Broadcast upload extension](https://github.com/webex/webex-ios-sdk/wiki/Implementation-Broadcast-upload-extension) and [Set up an App Group](https://github.com/webex/webex-ios-sdk/wiki/Set-up-an-App-Group)
    
## License

&copy; 2016-2018 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
