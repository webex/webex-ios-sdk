# Change Log
All notable changes to this project will be documented in this file.
#### 2.6.0 Releases

- `2.6.0` Releases - [2.6.0](#260)

#### 2.5.0 Releases

- `2.5.0` Releases - [2.5.0](#250)

#### 2.4.0 Releases

- `2.4.0` Releases - [2.4.0](#240)

#### 2.3.0 Releases

- `2.3.0` Releases - [2.3.0](#230)

#### 2.1.0 Releases

- `2.1.0` Releases - [2.1.0](#210)

#### 2.0.0 Releases

- `2.0.0` Releases - [2.0.0](#200)

#### 1.4.1 Releases

- `1.4.1` Releases - [1.4.1](#141)

#### 1.4.0 Releases

- `1.4.0` Releases - [1.4.0](#140)

#### 1.3.1 Releases

- `1.3.1` Releases - [1.3.1](#131)

#### 1.3.0 Releases

- `1.3.0` Releases - [1.3.0](#130)

#### 1.2.0 Releases

- `1.2.0` Releases - [1.2.0](#120)

#### 1.1.0 Releases

- `1.1.0` Releases - [1.1.0](#110)

#### 1.0.0 Releases

- `1.0.0` Releases - [1.0.0](#100)

#### 0.9.149 Releases

- `0.9.149` Releases - [0.9.149](#09149)

#### 0.9.148 Releases

- `0.9.148` Releases - [0.9.148](#09148)

#### 0.9.147 Releases

- `0.9.147` Releases - [0.9.147](#09147)

#### 0.9.146 Releases

- `0.9.146` Releases - [0.9.146](#09146)

#### 0.9.137 Releases

- `0.9.137` Releases - [0.9.137](#09137)

---
## [2.6.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.6.0)
Released on 2020-9-28.
#### Added
- Support iOS 14 and XCode 12.
- Support for incoming call notifications for scheduled sapce call.
- Support for being notified of the end of a space call.
- Support to join password-protected meetings.
- Add a new API `Call.videoLayout` to change the video layout during a call.
- Add a new API `Call.remoteVideoRenderMode` to specify how the remote video adjusts its content to be render in a view.
- Add a new API `Phone.AdvancedSettings.videoMaxTxFPS` to change the max sending fps for video.
- Add a new API `Phone.cancel` to cancel the currently outgoing call that has not been connected.
- Add a new API `SpaceClient.listWithActiveCalls` to get a list of spaces that have ongoing call.
- Add a new API `Message.isAllMentioned` to check if the message mentioned everyone in space.
- Add a new API `Message.mentions` to get all people mentioned in the message.

#### Updated
- Improved video and audio quality
- API enhancements to improve bandwidth control.
- Update Wme.framework to 10.8.5.
- Update Starscream.framework to 4.0.4.
- Fixed unable to remove a Webex object once it has been created.
- Fixed switch Camera Error
- Fixed user in EMEAR org cannot message and call the user in US org.
- Fixed could not get thumbnail of the WORD, POWERPOINT, EXCEL and PDF file in the message.
- Fixed video received shows as zoomed and cropped when in iPhone/iPad is in portrait mode.
- Fixed Participant's video in video call is black.

## [2.5.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.5.0)
Released on 2020-3-30.
#### Added
- Support for threaded messaging.
- Support compose and render the active speaker video with other attendee video and all the names in one single view.
- Support single, filmstrip and grid layouts for the composed video view.

#### Updated
- Update Wme.framework.
- Update Starscream.framework.
- Remove deprecated Apple UIWebView API.

## [2.4.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.4.0)
Released on 2020-1-15.
#### Added
- Support to join the meeting where lobby is enabled.
- Support to let-in waiting people from looby to the meeting.

#### Updated
- Fixed screen share didn't work.
- Fixed loud speaker didn't work.


## [2.3.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.3.0)
Released on 2019-09-30.
#### Added
- Add API to receive membership created/deleted/updated/seen events.
- Add API to receive room created/updated events.
- Add API to get last activity status of a space.
- Add API to get a list of last activity status of all spaces.
- Add API to get a list of read status of all memberships in a space.
- Add API to get space meeting details.
- Add API to send read receipt for message.
- Add API to get the lastActivity of person.
- Add API to get the token expiration date for JWTAuthenticator.

#### Updated
- Support iOS 13.
- Support Swift5 and Xcode11.
- Update Wme.framework.
- Reduce latency when list messages.
- Fixed camera shows my video as green.

## [2.1.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.1.0)
Released on 2019-06-07.
#### Updated
- Improve API docs.
- Fixed Broadcast Extension Kit cannot find frameworks.

## [2.0.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.0.0)
Released on 2018-10-31.
#### Added
- SDK rebranding.
- Support multi streams in space call.

#### Updated
- Rename room to space.
- Upgrade media engine to fix crash issue on CallKit.
- Fixed crash issue on media cluster discovery.
- Fixed call event confusion in the large meeting.
- Refactor code to improve code quality.

## [1.4.1](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.4.1)
Released on 2018-09-29.
#### Added
- Support Swift4.2 and Xcode10.

#### Updated
- Fixed Activity roomtype always be 'group'.
- Remove Seu umbrella warning.
- Fixed Spark call crashing on iOS when using CallKit.
- Speed up reachability check.

## [1.4.0](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.4.0)
Released on 2018-05-15.

#### Added
- Support screen sharing for both sending and receiving.
- A new API to refresh token for authentication.
- Two properties in Membership: personDisplayName, personOrgId.
- Support real time message receiving.
- Support message end to end encription.
- A few new APIs to do message/file end to end encryption, Mention in message, upload and download encrypted files.
- Five properties in Person: nickName, firstName, lastName, orgId, type.
- Three functions to create/update/delete a person for organization's administrator.
- Support room list ordered by either room ID, lastactivity time or creation time.
- A new property in TeamMembership: personOrgId.
- Two new parameters to update webhook : status and secret.

#### Updated
- Fixed ocassional crash when switching between video call and audio call when CallKit is used.
- Fixed video freeze when iOS SDK makes a call to JavaScript SDK.
- Fixed crash issue when invoking Phone.requestMediaAccess function from background thread.
- Fixed wrong call type for room calling when there are only two people in the call.

## [1.3.1](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.3.1)
Released on 2018-1-12.

#### Feature:
          SSO Authenticator

## [1.3.0](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.3.0)
Released on 2017-10-13.

## [1.2.0](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.2.0)
Released on 2017-05-23.

## [1.1.0](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.1.0)
Released on 2016-11-29.

#### Updated
- Support swift 3.0

## [1.0.0](https://github.com/ciscospark/spark-ios-sdk/releases/tag/1.0.0)
Released on 2016-07-25.

#### Added
- Travis CI

#### Updated
- Media engine refactor
- Use NSDate for object mapper

## [0.9.149](https://github.com/ciscospark/spark-ios-sdk/releases/tag/0.9.149)
Released on 2016-07-11.

#### Added
- Add Teams and Team Memberships API.
- Support DTMF feature.

#### Updated
- Fix Message creation timestamp bug.
- Fix Room type bug.

## [0.9.148](https://github.com/ciscospark/spark-ios-sdk/releases/tag/0.9.148)
Released on 2016-06-23.

#### Added
- Suppport customized notification center (CallNotificationCenter/PhoneNotificationCenter) based on protocol (CallObserver/PhoneObserver), to avoid NSNotificationCenter flaws:
    - Pass parameters via a userInfo dicionary, so type info is lost.
    - Use constant string for notification name and parameter key name. It's hard to maintain and document.
    - Must deregister notifications, if not, it may cause crash.
- Add remote video/audio mute/unmute notifications. New API CallObserver.remoteMediaDidChange() is introduced.
- Support audio-only call. MediaOption parameter is introduced for it in API Phone.Dail()/Call.Answer().
- Support media cluster discovery.
- Support video license activation.
- Enable hardware acceleration, and support 720p video quality.
- Support toggling receiving audio and video. New API Call.toggleReceivingVideo()/Call.toggleReceivingAudio() is introduced for it.

#### Updated
- Refactor storage code logic. defaultFacingMode/defaultLoudSpeaker in Spark.Phone are not persistent, so after restart app, these setting doesn't exist.
- Fix logging performance issue.
- Fix missing incoming call issue when start APP from not running status, or switch APP to foreground from background.
- Update Wme.framework, to fix SIGPIPE signal during debug mode.

## [0.9.147](https://github.com/ciscospark/spark-ios-sdk/releases/tag/0.9.147)
Released on 2016-05-25.

#### Added
- Use CocoaLumberjack to print SDK log. Introduce new API Spark.toggleConsoleLogger(enable: Bool) to enable/disable SDK console log. SDK console log is enabled by default.
- Introduce Apache License for SDK.

#### Updated
- Refactor web socket code logic, to fix some potential issue.
- Update Wme.framework.

## [0.9.146](https://github.com/ciscospark/spark-ios-sdk/releases/tag/0.9.146)
Released on 2016-05-19.

#### Added
- Add CHANGELOG.
- Support refreshing token.

#### Updated
- Refine OAuth flow logic.

## [0.9.137](https://github.com/ciscospark/spark-ios-sdk/releases/tag/0.9.137)
Released on 2016-05-12.

#### Added
- Initial release of Cisco Spark SDK.
