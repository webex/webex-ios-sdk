# Cisco Webex iOS SDK

The Cisco Webex iOS SDK makes it easy to integrate secure and convenient Cisco Webex messaging and calling features in your iOS apps.

This SDK is written in [Swift 5](https://developer.apple.com/swift) and requires **iOS 13** or later.

## Table of Contents
- [Why](#why)
- [Notes](#notes)
- [Install](#install)
- [Usage](#usage)
- [Useful Resources](#useful-resources)
- [License](#license)

## Why

* Unified feature set: Meeting, Messaging and CUCM calling.
* Greater feature velocity and in parity with the Webex mobile app.
* Easier for developers community: SQLite is bundled for automatic data caching.
* Greater quality as it is built on a more robust infrastructure.

## Notes

* Integrations created in the past will not work with v3 because they are not entitled to the scopes required by v3. You can either raise a support request to enable these scopes for your appId or  you could create a new Integration that's meant to be used for v3. This does not affect Guest Issuer JWT token based sign in.
* We do not support external authCode login anymore.
* Starting a screenshare is not yet supported for CUCM calls.
* In cucm calls, Participant.isReceivingAudio does not correctly reflect the current status. This will be fixed in future releases.
* Currently all resource ids that are exposed from the sdk are barebones GUIDs. You cannot directly use these ids to make calls to [webexapis.com](webexapis.com). You'll need to call `Webex.base64Encode(:ResourceType:resource:completionHandler)` to get a base64 encoded resource. However, you're free to interchange between base64 encoded resource ids and barebones GUID while providing them as input to the sdk APIs.

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
      platform :ios, '13'
      pod 'WebexSDK'
    end

    target 'MyWebexAppBroadcastExtension' do
        platform :ios, '13'
        pod 'WebexBroadcastExtensionKit'
    end
    ```

4. Install the Webex iOS SDK from your _MyWebexApp_ project directory:

    ```bash
    pod install
    ```

5. To your app’s `Info.plist`, please add an entry `GroupIdentifier` with the value as your app's GroupIdentifier. This is required so that we can get a path to store the local data warehouse.

6. If you'll be using [WebexBroadcastExtensionKit](https://cocoapods.org/pods/WebexBroadcastExtensionKit), You also need to add an entry `GroupIdentifier` with the value as your app's GroupIdentifier to your Broadcast Extension target. This is required so that we that we can communicate with the main app for screen sharing.

7. Modify the `Signing & Capabilities` section in your xcode project as follows 
<img src="https://github.com/webex/webex-ios-sdk-example/blob/master/images/signing_and_capabilities.png" width="80%" height="80%">

A sample app that implements this SDK with source code can be found at [https://github.com/webex/webex-ios-sdk-example](https://github.com/webex/webex-ios-sdk-example) . This is to showcase how to consume the APIs and not meant to be a production grade app.

## Usage

To use the SDK, you will need Cisco Webex integration credentials. If you do not already have a Cisco Webex account, visit [Webex for Developers](https://developer.webex.com/) to create your account and [register your integration](https://developer.webex.com/docs/integrations#registering-your-integration). Make sure you select `Yes` for `Will this integration use a mobile SDK?`. Your app will need to authenticate users via an [OAuth](https://oauth.net/) grant flow for existing Cisco Webex users or a [JSON Web Token](https://jwt.io/) for guest users without a Cisco Webex account.

See the [iOS SDK area](https://developer.webex.com/docs/sdks/ios) of the Webex for Developers site for more information about this SDK.

### Example

Here are some examples of how to use the iOS SDK in your app.

1. Create the Webex instance using Webex ID authentication ([OAuth](https://oauth.net/)-based):

    ```swift
    let clientId = "$YOUR_CLIENT_ID"
    let clientSecret = "$YOUR_CLIENT_SECRET"
    let redirectUri = "https://webexdemoapp.com/redirect"

    let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri, emailId: "user@example.com")
    let webex = Webex(authenticator: authenticator)
    webex.enableConsoleLogger = true 
    webex.logLevel = .verbose // Highly recommended to make this end-user configurable incase you need to get detailed logs.

    webex.initialize { result in
            if isLoggedIn {
                print("User is authorized")
            } else {
                authenticator.authorize(parentViewController: self) { result in
                if result == .success {
                    print("Login successful")
                } else {
                    print("Login failed")
                }
            }
            }
        }
    ```

2. Create the Webex instance with Guest ID authentication ([JWT](https://jwt.io/)-based):

    ```swift
    let authenticator = JWTAuthenticator()
    let webex = Webex(authenticator: authenticator)

    webex.initialize { [weak self] isLoggedIn in
            guard let self = self else { return }
            if isLoggedIn {
                print("User is authorized")
            } else {
                authenticator.authorizedWith(jwt: myJwt) { success in
                    if success {
                        print("Login successful")
                    } else {
                        print("Login failed")
                        return
                    }
                })
            }
        }
    ```

3. Use Webex service:

    ```swift

    webex.spaces.create(title: "Hello World") { result in
        switch result {
        case .success(let space):
            // ...
        case .failure(let error):
            // ...
        }
    }

    // ...

    webex.memberships.create(spaceId: spaceId, personEmail: email) { result in    
        switch result {
            case .success(let membership):
                // ...
            case .failure(let error):
                // ...
            }
        }
    }

    ```

4. Make an outgoing call:

    ```swift
    webex.phone.dial("coworker@example.com", option: MediaOption.audioVideo(local: ..., remote: ...)) { result in
        switch result {
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

5. Make an outgoing CUCM call:

    ```swift
    webex.phone.dial("+1180012345", option: MediaOption.audioVideo(local: ..., remote: ...)) { result in
        switch result {
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
            // failure
        }
        else {
            // success
        }
    }
    ```

7. Make an space call:

    ```swift
    webex.phone.dial(spaceId, option: MediaOption.audioVideo(local: ..., remote: ...)) { result in
        switch result {
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
    var selfVideoView = MediaRenderView()
    var remoteVideoView = MediaRenderView()
    var screenShareView = MediaRenderView()
    webex.phone.dial("coworker@example.com", option: MediaOption.audioVideoScreenShare(video: (local: selfVideoView, remote: remoteVideoView), screenShare: screenShareView)) { ret in
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
NOTE: Screen sharing will only work using v3 SDK with the latest `WebexBroadcastExtensionKit`.

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
    webex.messages.post(text, toPersonEmail: emailAddress) { result in
        switch result {
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
        case .messageDeleted(let messageId):
            // ...
        }
    }
    ```

11. send read receipt of a message

    ```swift
    webex.messages.markAsRead(spaceId: spaceId, messageId: messageId, completionHandler: { result in
         switch result {
         case .success(_):
             // ...
         case .failure(let error):
             // ...
         }
    })
    ```

12. receive a membership event

    ```swift
    webex.memberships.onEvent = { membershipEvent in
          switch membershipEvent {
          case .created(let membership):
              // ...
          case .deleted(let membership):
              // ...
          case .update(let membership):
              // ...
          case .messageSeen(let membership, let lastSeenId):
              // ...
          }
    }
    ```

13. get read statuses of all memberships in a space

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

14. receive a space event

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

15. get read status of a space for login user

    ```swift
    webex.spaces.getWithReadStatus(spaceId: spaceId, completionHandler: { response in
          switch response.result {
          case .success(let spaceInfo):
              if let lastActivityDate = spaceInfo.lastActivityDate,
                  let lastSeenDate = spaceInfo.lastSeenActivityDate,
                  lastActivityDate > lastSeenDate {

                  // space is unreadable

              } else {

                  // space is readable
              }
          case .failure(let error):
              // ...
          }
    })
    ```

16. get meeting detail of a space

    ```swift
    webex.spaces.getMeetingInfo(spaceId: spaceId, completionHandler: { result in
          switch result {
          case .success(let meetingInfo):
              // ...
          case .failure(let error):
              // ...
          }
    })
    ```

17. get a list of spaces that have ongoing call

    ```swift
    webex.spaces.listWithActiveCalls(completionHandler: { result in
        switch result {
        case .success(let spaceIds):
            // ...
        case .failure(_ ):
            // ...
        }
    })
    ```

18. Change the layout for the active speaker and other attendee composed video

    ```swift
    let option: MediaOption = MediaOption.audioVideo(local: ..., remote: ...)
    option.compositedVideoLayout = .grid

    webex.phone.dial(spaceId, option: option) { ret in
        // ...
    }
    ```

19. Background Noise Removal(BNR)
    
    19.1 Enable BNR
    ```swift
    webex.phone.audioBNREnabled = true
    ```

    19.2 Set BNR mode, the default is `.HP`. It only affects if setting `audioBNREnabled` to true.
    ```swift
    webex.phone.audioBNRMode = .HP
    ```

## Useful Resources
 * [Webex iOS SDK API docs](https://webex.github.io/webex-ios-sdk/).
 * [Guide for migration from v2.x to v3.x](https://github.com/webex/webex-ios-sdk/wiki/Migrating-from-v2-to-v3)
 * [Guide for creating v3 compatible integrations & CUCM Push notifications](https://github.com/webex/webex-ios-sdk/wiki/App-Registration-for-Mobile-SDK-v3)
 * [Guide for CUCM calling](https://github.com/webex/webex-ios-sdk/wiki/CUCM-Usage-Guide-v3)
 * [Guide for using Multistream](https://github.com/webex/webex-ios-sdk/wiki/Multistream-Guide)
 * [WebexSDK Wikis](https://github.com/webex/webex-ios-sdk/wiki)

## License

&copy; 2016-2021 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
