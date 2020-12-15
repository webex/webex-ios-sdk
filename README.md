# Cisco Webex iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/WebexSDK.svg)](https://cocoapods.org/pods/WebexSDK)
[![Travis CI](https://travis-ci.org/webex/webex-ios-sdk.svg?branch=master)](https://travis-ci.org/webex/webex-ios-sdk)
[![license](https://img.shields.io/github/license/webex/webex-ios-sdk.svg)](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE)

The Cisco Webex iOS SDK makes it easy to integrate secure and convenient Cisco Webex messaging and calling features in your iOS apps.

This SDK is written in [Swift 5](https://developer.apple.com/swift) and requires **iOS 11** or later.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [License](#license)
- [Migration From SparkSDK](#migration-from-cisco-sparksdk)

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
      platform :ios, '11.0'
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

To use the SDK, you will need Cisco Webex integration credentials. If you do not already have a Cisco Webex account, visit [Webex for Developers](https://developer.webex.com/) to create your account and [register your integration](https://developer.webex.com/docs/integrations#registering-your-integration). Your app will need to authenticate users via an [OAuth](https://oauth.net/) grant flow for existing Cisco Webex users or a [JSON Web Token](https://jwt.io/) for guest users without a Cisco Webex account.

See the [iOS SDK area](https://developer.webex.com/docs/sdks/ios) of the Webex for Developers site for more information about this SDK.

### Example

Here are some examples of how to use the iOS SDK in your app.


1. Create the Webex instance using Webex ID authentication ([OAuth](https://oauth.net/)-based):

    ```swift
    let clientId = "$YOUR_CLIENT_ID"
    let clientSecret = "$YOUR_CLIENT_SECRET"
    let scope = "spark:all"
    let redirectUri = "https://webexdemoapp.com"

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
    webex.spaces.create(title: "Hello World") { response in
        switch response.result {
        case .success(let space):
            // ...
        case .failure(let error):
            // ...
        }
    }

    // ...

    webex.memberships.create(spaceId: spaceId, personEmail: email) { response in
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

7. Make an space call:

    ```swift
    webex.phone.dial(spaceId, option: MediaOption.audioVideo(local: ..., remote: ...)) { ret in
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

    ```swift
    let plain = "foo"
    let markdown = "**foo**"
    let html = "<strong>foo</strong>"
    ```
    ```swift
    let text = Message.Text.html(html: html)
    webex.messages.post(text, toPersonEmail: emailAddress, completionHandler: { response in
        switch response.result {
        case .success(let message):
            // ...
        case .failure(let error):
            // ...
        }
    }
    ```
    ```swift
    let text = Message.Text.markdown(markdown: markdown, html: html, plain: text)
    webex.messages.post(text, toPersonEmail: emailAddress, completionHandler: { response in
        switch response.result {
        case .success(let message):
            // ...
        case .failure(let error):
            // ...
        }
    }
    ```

10. Receive a message event:

    ```swift
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

11. send read receipt of a message

    ```swift
    webex.messages.markAsRead(spaceId: spaceId, messageId: messageId, completionHandler: { response in
         switch response.result {
         case .success(_):
             // ...
         case .failure(let error):
             // ...
         }
    })
    ```

12. Screen share (sending):

    12.1 In your containing app:

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

    12.2 In your broadcast upload extension sample handler:

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

    12.3 Get more technical details about the [Containing App & Broadcast upload extension](https://github.com/webex/webex-ios-sdk/wiki/Implementation-Broadcast-upload-extension) and [Set up an App Group](https://github.com/webex/webex-ios-sdk/wiki/Set-up-an-App-Group)

13. Receive more video streams in a meeting:

    ```swift
    class VideoCallViewController: MultiStreamObserver {
        ...
        var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)? = {
            ...
            switch event {
            case .auxStreamOpenedEvent(let view, let result):
                switch result {
                    case .success(let auxStream):
                        ...
                    case .failure(let error):
                        ...
                }
            case .auxStreamPersonChangedEvent(let auxStream,_,_):
                    ...
            case .auxStreamSendingVideoEvent(let auxStream):
                ...
            case .auxStreamSizeChangedEvent(let auxStream):
                ...
            case .auxStreamClosedEvent(let view, let error):
                ...
            }
        }

        var onAuxStreamAvailable: (() -> MediaRenderView?)? = {
            ...
            return self.mediaRenderViews.filter({!$0.inUse}).first?
        }

        var onAuxStreamUnavailable: (() -> MediaRenderView?)? = {
            ...
            return self.mediaRenderViews.filter({$0.inUse}).last?
        }

        override func viewWillAppear(_ animated: Bool) {
            ...
            // set the observer of this call to get multi stream event.
            self.call.multiStreamObserver = self
            ...
        }
    }
    ```

14. receive a membership event

    ```swift
    webex.memberships.onEvent = { membershipEvent in
          switch membershipEvent {
          case .created(let membership):
              // ...
          case .deleted(let membership):
              // ...
          case .update(let membership):
              // ...
          case .seen(let membership, let lastSeenId):
              // ...
          }
    }
    ```

15. get read statuses of all memberships in a space

    ```swift
    webex.memberships.listWithReadStatus(spaceId: spaceId, completionHandler: { response in
          switch response.result {
          case .success(let readStatuses):
              // ...
          case .failure(let error):
              // ...
          }
    })
    ```

16. receive a space event

    ```swift
    webex.spaces.onEvent = { spaceEvent in
          switch spaceEvent {
          case .create(let space):
              // ...
          case .update(let space):
              // ...
          case .spaceCallStarted(let spaceId):
              // ...
          case .spaceCallEnded(let spaceId):
              // ...
          }
    }
    ```

17. get read status of a space for login user

    ```swift
    webex.spaces.getWithReadStatus(spaceId: spaceId, completionHandler: { response in
          switch response.result {
          case .success(let spaceInfo):
              if let lastActivityDate = spaceInfo.lastActivityDate,
                  let lastSeenDate = spaceInfo.lastSeenActivityDate,
                  lastActivityDate > lastSeenDate {

                  // space is unreadable

              }else {

                  // space is readable
              }
          case .failure(let error):
              // ...
          }
    })
    ```

18. get meeting detail of a space

    ```swift
    webex.spaces.getMeetingInfo(spaceId: spaceId, completionHandler: { response in
          switch response.result {
          case .success(let meetingInfo):
              // ...
          case .failure(let error):
              // ...
          }
    })
    ```

19. get a list of spaces that have ongoing call

    ```swift
    webex.spaces.listWithActiveCalls(completionHandler: { (result) in
        switch result {
        case .success(let spaceIds):
            // ...
        case .failure(_ ):
            // ...
        }
    })
    ```

20. Change the layout for the active speaker and other attendee composed video

    ```swift
    let option: MediaOption = MediaOption.audioVideo(local: ..., remote: ...)
    option.layout = .grid

    webex.phone.dial(spaceId, option: option) { ret in
        // ...
    }
    ```

21. Background Noise Removal(BNR)
    
    21.1 Enable BNR
    ```swift
    webex.phone.audioBNREnabled = true
    ```

    21.2 Set BNR mode, the default is `.HP`. It only affects if setting `audioBNREnabled` to true.
    ```swift
    webex.phone.audioBNRMode = .HP
    ```


## Migration from Cisco SparkSDK

The purpose of this guide is to help you to migrate from Cisco SparkSDK to Cisco WebexSDK.

Assuming you already have an project integrated with SparkSDK.

1. In your pod file:

    remove previous SparkSDK: ~~pod 'SparkSDK'~~

    add WebexSDK: pod 'WebexSDK'

2. Go to project directory, and run:
    ```c
    pod install
    ```
3. Replace sdk import info for your code:

    Replace in project scope:

    "import SparkSDK" => "import WebexSDK"

4. If you using story board for UI:

    Change meida render view's module in "Indentity inspector":

    "SparkSDK" => "WebexSDK"

### Usage

API changes list from SparkSDK to WebexSDK.

| Description | SparkSDK Use | WebexSDK Use |
| :----:| :----: | :----:
| Create a new instance | let spark = Spark(authenticator: authenticator) | let webex = Webex(authenticator: authenticator)
| "Room" Client renamed to "Space" Client | spark.rooms.list(roomId:{rooomId}) | webex.spaces.list(spaceId:{roomId})
| "SparkError" renamed to "WebexError" | let error = SparkError.Auth | let error = WebexError.Auth |


Recomand to replace variables containing "spark" with "webex" in project code.  


## License

&copy; 2016-2021 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
