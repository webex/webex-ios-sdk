# Cisco Webex iOS SDK

The Cisco Webex iOS SDK makes it easy to integrate secure and convenient Cisco Webex messaging and calling features in your iOS apps.

This SDK is written in [Swift 5](https://developer.apple.com/swift) and requires **iOS 13** or later.

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
      platform :ios, '13.0'
      pod 'WebexSDKv3-Beta'
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
    let redirectUri = "Webexdemoapp://response"

    let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
    let webex = Webex(authenticator: authenticator)

    if !authenticator.authorized {
        authenticator.authorize(parentViewController: self) { success in
            if !success {
                print("User not authorized")
            }
        }
    }
    
    webex.initialize { [weak self] isLoggedIn in
            guard let self = self else { return }
            if isLoggedIn {
                //already logged in
            } else {
                //not logged in
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

3. Use Webex service:

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

4. Make an outgoing call:

    ```swift
    webex.phone().dial("coworker@acm.com", option: MediaOption.audioVideo(local: ..., remote: ...)) { ret , call in
        if ret {
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
        } else {
            //call failure
        }
    }
    ```

5. Receive a call:

    ```swift
    webex.phone().onIncoming = { call in
        call.answer(option: MediaOption.audioVideo(local: ..., remote: ...)) { ret in
        if ret {
            // success
        }
        else {
            // failure
        }
    }
    ```

6. Make an space call:

    ```swift
    webex.phone().dial(spaceId, option: MediaOption.audioVideo(local: ..., remote: ...)) { ret , call in
        if ret {
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
        } else {
            //call failure
        }
    }
    ```
    
7. Screen share (view only):

    ```swift
    webex.phone.dial("abc@example.com", option: MediaOption.audioVideoScreenShare(video: (local: ..., remote: ...))) { ret , call in
        if ret {
            call.onConnected = {
                // ...
            }
            call.onDisconnected = { reason in
                // ...
            }
            call.onSharingVideoStreamInUseChanged = {
               if call.isRemoteSharing {
                   webex.phone().addScreenSharing(callId: ..., videoView: ...)
               } else {
                   webex.phone().removeScreenSharing(callId: ..., videoView: ...)
               }   
            }
        } else {
            //call failure
        }
    }
    ```
    
8. Post a message:

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

9. send read receipt of a message

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

10. get read statuses of all memberships in a space

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

11. get read status of a space for login user

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

12. get meeting detail of a space

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

## License

&copy; 2016-2020 Cisco Systems, Inc. and/or its affiliates. All Rights Reserved.

See [LICENSE](https://github.com/webex/webex-ios-sdk/blob/master/LICENSE) for details.
