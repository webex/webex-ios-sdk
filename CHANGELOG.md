# Change Log
All notable changes to this project will be documented in this file.
#### 3.2.0 Releases

- `3.2.0` Releases - [3.2.0](#320)

#### 3.1.0 Releases

- `3.1.0` Releases - [3.1.0](#310)

#### 3.0.0 Releases

- `3.0.0` Releases - [3.0.0](#300)

#### 2.8.0 Releases

- `2.8.0` Releases - [2.8.0](#280)

#### 2.7.0 Releases

- `2.7.0` Releases - [2.7.0](#270)

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
## [3.2.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.2.0)
Released on 2021-10-18
#### Added
- Added new `TokenAuthenticator` for authenticating with external guest access token
- Added VirtualBackground support
- Added new API `Phone.isVirtualBackgroundSupported` to check whether your device supports virtual background feature
- Added new API `Phone.virtualBackgroundLimit` to get/set the limit of custom virtual background
- Added new API `Phone.fetchVirtualBackgrounds(:completionHandler)` API to get all virtual backgrounds
- Added new API `Phone.addVirtualBackground(:image:completionHandler)` API to add new virtual background image
- Added new API `Phone.removeVirtualBackground(:background:completionHandler)` API to delete selected virtual background item
- Added new API `Phone.applyVirtualBackground(:background:mode:completionHandler)` API to apply virtual background for 'Preview' or 'Call'
- Added new API `Call.onCpuHitThreshold()` to notify when CPU reaches threshold
- Added new struct `Phone.VirtualBackground` to denote the virtual background item
- Added new struct `Phone.VirtualBackgroundThumbnail` to denote the thumbnail of  virtual background item
- Added new enum `Phone.VirtualBackgroundType`to denote the type of virtual background item among None, Blur and Custom
- Added new enum `Phone.VirtualBackgroundMode` to denote the mode for applying virtual background for Preview or Call
- Added new enum `FetchVirtualBackgroundError`
- Added new enum `AddVirtualBackgroundError` 
- Added new enum `RemoveVirtualBackgroundError`
- Added new enum `ApplyVirtualBackgroundError`
- Added new API `CalendarMeetings.list(:startDate:endDate:callback)` to list all calendar meetings in a date range
- Added new API `CalendarMeetings.get(:meetingId:callback)` to fetch a single calendar meeting by meetingId
- Added new struct `Meeting` to represent a Calendar Meeting item
- Added new struct `MeetingInvitee` to represent a person invited to a calendar meeting
- Added new enum `InviteeResponse` to represent the response of a meeting invitee
- Added new API `CalendarMeetings.onEvent` to register a callback to be fired when a calendar meeting event occurs
- Added new enum `CalendarMeetingEvent` to represent a scheduled calendar meeting event

#### Updated
- Updated WME to 11.9.0.9
- Added new field `meetingId` to `Call` struct
- Added public constructor for `RemoteFile` struct
- Added public constructor for `RemoteFile.Thumbnail` struct
- `Call.isSpeaker` was get only and can be set as well now

## bug fixes
- Dial callback not received
- Meeting Signal after restart inconsistency
- Calling Screen Infinite loading - wrong meeting Id dial.
- Re-login crash without restart of application
- Meeting subject incorrect
- Remote Video rendering issue when re-join meeting
- Video surfaces crash on leaving meeting

## [3.1.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.1.0)
Released on 2021-08-16
#### Added
- Added FedRAMP support
- Added new API `OAuthAuthenticator.getAuthorizationUrl(:completionHandler)` to get a valid authorization URL to initate OAuth
- Added new API `OAuthAuthenticator.authorize(:oauthCode:completionHandler)` to authorize with auth code from OAuth first leg
- Added new API `Phone.getServiceUrl(:ServiceUrlType)` API
- Added back scope argument to `OAuthAuthenticator`. This serves to add additional scopes that the developer might want the access token to have. Now developers have to provide `spark:all` scope always to this argument
- Added new API `Call.isSpaceMeeting` to denote the call is space backed meeting type
- Added new API `Call.isSelfCreator` to denote if self is the initiator of the call
- Added new API `Call.hasAnyoneJoined`to denote if anyone joined the meeting, excluding self
- Added new API `Call.isPmr` to denote the call is a personal meeting room
- Added new API `Call.isMeeting` to differentiate between meetings and calls
- Added new API `Call.isScheduledMeeting` to differentiate between scheduled meetings and ad-hoc meetings
- Added new enum `Base64EncodeError`
- Added new enum `TokenLoginError`
- Added new `case .personNotFound` to `DeletePersonError` enum
- Added new `case .badRequest` to following enums: `ListMembershipsError`, `ListTeamMembershipResult`, `DeleteSpaceResult`, `ListWebhooksResult`, `GetWebhookByIdResult`, `CreateWebhookResult`, `UpdateWebhookByIdResult` and `DeleteWebhookByIdResult`

#### Updated
- `base64Encode(resourceType: ResourceType, resource: String, completionHandler: @escaping (String, SpaceApiErrorInfo, Bool) -> Void)`  to `base64Encode(resourceType: ResourceType, resource: String, completionHandler: @escaping (Result<String>) -> Void)`
- The completion handlers for the following methods have been updated to accept a Result object instead of bare token string: `Authenticator.accessToken(:completionHandler)`, `JWTAuthenticator.authorizedWith(:jwt:completionHandler)`, `JWTAuthenticator.accessToken(:completionHandler)`, `JWTAuthenticator.refreshToken(:completionHandler)`, `OAuthAuthenticator.accessToken(:completionHandler)`

#### Removed
- Removed `Phone.connected` API
- Removed `SpaceApiErrorInfo` struct

## [3.0.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.0.0)
Released on 2021-05-24
#### Added
- Major rewrite of the SDK.
- Ability to make calls via CUCM.
- Receive push notification for incoming CUCM calls. 
- Added new API `Webex.setUCDomainServerUrl(ucDomain: String, serverUrl: String )` for CUCM
- Added new API `Webex.setCUCMCredential(username: String, password: String )` for CUCM
- Added new API `Webex.getUCSSOLoginView()` for CUCM SSO login
- Added new API `Webex.ucCancelSSOLogin()` to cancel CUCM SSO login
- Added new API `Webex.isUCLoggedIn()` for CUCM
- Added new API `Webex.getUCServerConnectionStatus()` for CUCM
- Added new `Webex.initialize` that sets up the SDK and automatically logs in a previously logged in user
- Added new API `Webex.base64Encode(resourceType: ResourceType, resource: String, completionHandler: handler)` to encode UUID as Base64
- Added new API `Webex.base64Decode(encodedResource: String)` to decode Base64 to Resource
- Added new API `SpaceClient.filter` to fetch person and bots based on the given query
- Added new API `Phone.getCallHistory` to get collection of Space which contains call history of One to One Spaces as well as Group type Spaces
- Added new API `Webex.getLogFileUrl` to get file URI of where all the logs are stored
- Added new struct `Message.MentionPos` to describe the position of a Mention
- Added new property `Call.schedules` to get the the schedules of a call if the call has one or more schedules.
- Added `Call.startAssociatedCall()` for CUCM calls
- Added `CallAssociationType` enum to indicate whether call is of type Transfer or merge
- Added `Call.transferCall()` for CUCM calls
- Added `Call.mergeCall()` for CUCM calls 
- Added `Call.holdCall()` for CUCM calls
- Added `Call.isOnHold()` for CUCM calls
- Added new API `Call.onFailed` to notify that a call has failed
- Added new API `Call.onInfoChanged()` to notify when call object changes
- Added new API `Call.setParticipantAudioMuteState()` to mute particular participant
- Added new API `Call.setAllParticipantAudioMuteState()` to control mute state of all participants
- Added new property `CallSchedule.organzier` to get organizer of a scheduled call
- Added new property `CallSchedule.meetingId` to get meetingId of a scheduled call
- Added new property `CallSchedule.link` to get link of a scheduled call
- Added new property `CallSchedule.subject` to get subject of a scheduled call
- Added new struct `Resource` to represent a Resource
- Added new enum `ResourceType` to represents the type of a Resource
- Added new delegate `WebexUCLoginDelegate` to support UC login state changes
- Added `refreshToken()` to JWTAuthenticator
- Introduced new Enum `OAuthResult`
- Introduced new Enum `NotificationCallType` to distinguish between incoming webex calls and CUCM calls
- Added `isGroupCall` API
- Added callEnded in DisconnectReason in onDisconnected event
- Added `Phone.getCallIdFromNotificationId`
- Moved getCallHistory from Webex class to Phone class
- Added `Webex.enableConsoleLogger()` to enable/disable console logging
- Added `Webex.logLevel` API to set the log levels
- Added `CallEnded` to `Call.DisconnectReason`

#### Updated
- Transitioned from using results wrapped in a `ServiceResponse` to just `Result`
- `Phone.dial` has been modified to support dialing CUCM numbers
- `OAuthAuthenticator.authorize(parentViewController: UIViewController, completionHandler: @escaping ((_ success: Bool) -> Void))` changed to `OAuthAuthenticator.authorize(parentViewController: UIViewController, completionHandler: ((_ result: OAuthResult) -> Void)?)`
- `JWTAuthenticator.authorizedWith(:jwt)` changed to `JWTAuthenticator.authorizedWith(:jwt:completionHandler)`
- `OAuthAuthenticator.authorize(oauthCode: String, completionHandler: ((_ success: Bool) -> Void)? = nil)` changed to
`OAuthAuthenticator.authorize(oauthCode: String, completionHandler: ((_ result: OAuthResult) -> Void)? = nil)`
- `Mention.Person` and `Mention.all` now accept `MentionPos` instance
#### Removed
- SSO Authenticator
- Removed `Phone.register()`, `Phone.registered` & `Phone.deregister()`
-  `iOSBroadcastingEvent`
- Removed all third party pod dependencies
- Removed `refreshToken()` from Authenticator protocol
- Removed `OAuthAuthenticatorDelegate`
- Removed deprecated field `MediaOption.layout`
- Removed deprecated API `MessageClient.post(personEmail:text:files:queue:completionHandler:)`
- Removed deprecated API `MessageClient.post(personId:text:files:queue:completionHandler:)`
- Removed deprecated API `MessageClient.post(spaceId:text:mentions:files:queue:completionHandler:)`
- Removed `Logger`. You no longer have to implement this as it's already implemented internally
- Removed `Webex.logger` in favor of `Webex.getLogFileURL`
- Removed `applicationGroupIdentifier` param from `MediaOption.audioVideoScreenShare()`. Instead this needs to be a present in your app's `Info.plist` with key as `GroupIdentifier` and value as your app's GroupIdentifier
- Removed `Message.update()` as you no longer have to update the Message instance manually.

## [2.8.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.8.0)
Released on 2021-04-30.
#### Added
- Support Multi-stream.
- Support message edit.
- Support meeting with 11 digits meeting number.
- Add Phone.enableBackgroundConnection( ) function.

#### Updated
- Removed email from CallMembership, added displayName for CallMembership.
- Fix video automatically unmute issue after swithing from background. 
- Fix message encryption failures.
- Fix certain events are not getting triggered after Switching network.
- Fix sending video issue in 1:1 calls.

## [2.7.0](https://github.com/webex/webex-ios-sdk/releases/tag/2.7.0)
Released on 2020-12-14.
#### Added
- Support to notify a space call status through SpaceObserver.
- Support to notify muted by host during a space call.
- Support to enable Background Noise Removal(BNR), and switch between HP(High Performance) and LP(Low Power) mode.
- Not sending sensitive headers for unknown site.

#### Updated
- Update Wme.framework.
- Update Alamofire dependency to 5.2.0
- Update ObjectMapper dependency to 4.2.0
- Remove AlamofireObjectMapper dependency.
- Fix SpaceClient.listWithActiveCalls() cannot show spaces cross-cluster.
- Fix App hangs when trying to record a video via UIImagePickerController.

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
