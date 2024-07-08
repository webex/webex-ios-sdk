# Change Log
All notable changes to this project will be documented in this file.
#### 3.12.0 Releases
- `3.12.0` Releases - [3.12.0](#3120)

#### 3.11.3 Releases
- `3.11.3` Releases - [3.11.3](#3113)

#### 3.11.2 Releases
- `3.11.2` Releases - [3.11.2](#3112)

#### 3.11.1 Releases
- `3.11.1` Releases - [3.11.1](#3111)

#### 3.11.0 Releases

- `3.11.0` Releases - [3.11.0](#3110)

#### 3.10.1 Releases

- `3.10.1` Releases - [3.10.1](#3101)

#### 3.10.0 Releases

- `3.10.0` Releases - [3.10.0](#3100)

#### 3.9.2 Releases

- `3.9.2` Releases - [3.9.2](#392)

#### 3.9.1 Releases

- `3.9.1` Releases - [3.9.1](#391)

#### 3.9.0 Releases

- `3.9.0` Releases - [3.9.0](#390)

#### 3.8.3 Releases

- `3.8.3` Releases - [3.8.3](#383)

#### 3.8.2 Releases

- `3.8.2` Releases - [3.8.2](#382)

#### 3.8.1 Releases

- `3.8.1` Releases - [3.8.1](#381)

#### 3.8.0 Releases

- `3.8.0` Releases - [3.8.0](#380)

#### 3.7.0 Releases

- `3.7.0` Releases - [3.7.0](#370)

#### 3.6.0 Releases

- `3.6.0` Releases - [3.6.0](#360)

#### 3.5.0 Releases

- `3.5.0` Releases - [3.5.0](#350)

#### 3.4.0 Releases

- `3.4.0` Releases - [3.4.0](#340)

#### 3.3.0 Releases

- `3.3.0` Releases - [3.3.0](#330)

#### 3.2.1 Releases

- `3.2.1` Releases - [3.2.1](#321)

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

## [3.12.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.12.0)
Released on **08 Jul, 2024**.
### Added
- New Class `CameraDeviceManager` to manage the external camera related operations.
- New Struct `Camera` to represent camera devices either built-in or externally attached.
- New Enum `CompanionMode` to set the companion mode for Move Meeting.
- New Enum `UpdateSystemCameraResult` to represent error while updating system preferred camera.
- New Callback `Call.onMoveMeetingFailed: (() -> Void)?` when an attempt to move meeting fails for the call.
- New Callback `CameraDeviceManager.onExternalCameraDeviceConnected: ((_ camera: Camera) -> Void)` when external camera is connected.
- New Callback `CameraDeviceManager.onExternalCameraDeviceDisconnected: (() -> Void)?` when external camera is disconnected.
- New API added `Phone.updateSystemPreferredCamera(camera: Camera, completionHandler: @escaping (Result<Void>) -> Void)` to update the system preferred camera.
- New API added `Phone.getListOfCameras() -> [Camera]` to get the list of all available cameras.
- New API added `Phone.isMoveMeetingSupported(meetingId : String) -> Bool` to check if the move meeting feature is supported for the given meeting.
### Updated
- `isOngoingMeeting` and `eventId` fields are added to the `Meeting` struct.  
- `companionMode` field added to the `MediaOption` struct.

# [3.11.3](https://github.com/webex/webex-ios-sdk/releases/tag/3.11.3)
Released on **6 Jun, 2024**.
### Added
- The dial & dialPhoneNumber APIs will have the error description in case of failure.
- Access token invalidation or expiry will result in the SDK APIs returning Unauthorized error inside the completion handlers.

### Updated
- The `Phone.processPushNotification(msg : String, handler: CompletionHandler<PushNotificationResult>)` handler to return error in case of any failure. The error object will have the error code and error description.
- Completion handlers returning InternalError will have error descriptions. 

# [3.11.2](https://github.com/webex/webex-ios-sdk/releases/tag/3.11.2)
Released on **7 May, 2024**.
### Added
- New delegate `WebexAuthDelegate` to receive all authentication related event callbacks.
- New delegate function `onReLoginRequired()` in `WebexAuthDelegate` to notify when user auth token becomes stale or revoked and re login is required.

# [3.11.1](https://github.com/webex/webex-ios-sdk/releases/tag/3.11.1)
Released on **8 April, 2024**.
### Updated
- Added iOS Privacy Manifest file.
- H264 prompt is removed for video and screen share flows.
- Made `Webex` class singleton.
- Made `webex.initialize()` method thread safe and added check to avoid multiple initializations.
- Fixed: Call Failed issue during rejoin after host ends the meeting for all and starts again.

## [3.11.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.11.0)
Released on **13 Feb, 2024**.
### Added
- New Enum `InviteParticipantError` to represent error while adding a participant to the call.
- New Enum `MakeHostError` to represent error  while making a participant host in the call.
- New Enum `ReclaimHostError` to represent error while reclaiming the host role in the call.
- New API added `Call.inviteParticipant(participant: String, completionHandler: @escaping (Result<Void>) -> Void)` to invite a participant to the call.
- New API added `Call.reclaimHost(hostKey: String, completionHandler: @escaping (Result<Void>) -> Void)` to reclaim the host role using the host key.
- New API added `Call.makeHost(participantId: String, completionHandler: @escaping (Result<Void>) -> Void)` to assign the host role to a participant.
### Updated
- `isPresenter`,`isCohost` and `isHost` fields are added to the `CallMembership` struct.  
- New Enum case `CallError.cannotStartInstantMeeting` to represent error cannot start instant meeting.
- Messaging module removed in size optimized WxC SDK.
### Fixed
- Added `parent` field in postMessage APIs in MessageClient to reply to a message thread. 

## [3.10.1](https://github.com/webex/webex-ios-sdk/releases/tag/3.10.1)
Released on **12 Dec, 2023**.
### Added
- New Struct `ProductCapability` which represents the product capabilities for the logged in user.
- New API added `Person.getProductCapability() -> ProductCapability` to get the supported capability of the current user.
### Updated
- General improvements and bug fixes.

## [3.10.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.10.0)
Released on **16 Oct, 2023**.
### Added
- New Struct `Presence` which represents Presence info for a person.
- New Struct `PresenceHandle` which represents the contacts whose presence status are being watched.
- New Struct `VoicePushInfo` which represents the caller related information received from VoIP payload.
- New Struct `LanguageItem` represents LanguageItem of ClosedCaption of a call.
- New Struct `ClosedCaptionsInfo` represents ClosedCaptionsInfo of a call.
- New Struct `CaptionItem` represents CaptionItem of ClosedCaption of a call.
- New Enum `AudioOutputMode` options to switch audio output during a call.
- New Enum `PresenceStatus` indicating the Presence status of a person.
- New Enum `SpokenLanguageSelectionError` to represent error for setting current spoken language.
- New Enum `TranslationLanguageSelectionError` to represent error for setting current translation language.
- New API added `Person.startWatchingPresences(contactIds: [String], completionHandler: @escaping (Presence) -> Void) -> [PresenceHandle]` to start watching presence status update of the list of contact ids that are provided as input.
- New API added `Person.stopWatchingPresences(presenceHandles: [PresenceHandle])` to stop watching presence status of the list of presence handle that are provided as input.
- New API added `Call.callerNumber: String` caller number of the active WebexCalling or CUCM call.
- New API added `Call.getCurrentAudioOutput() -> AudioOutputMode` to get the current audio output device for the call.
- New API added `Call.setAudioOutput(mode: AudioOutputMode, completion: (Result<Bool>) -> ())` to set the current audio output device for the call.
- New API added `Call.isClosedCaptionAllowed: Bool` Returns if Closed Caption allowed or not for this `Call`.
- New API added `Call.isClosedCaptionEnabled: Bool` to let you know current state of the closed caption.
- New API added `Call.toggleClosedCaption(enable: Bool, completionHandler: @escaping (Bool) -> Void )` to toggle ClosedCaption on/off for this `Call`.
- New API added `Call.getClosedCaptionsInfo() -> ClosedCaptionsInfo` to get the `ClosedCaptionsInfo` of this `Call`.
- New API added `Phone.isH264LicenseActivated() -> Bool` to indicate the status of H264 license prompt acceptance.
- New API added `Webex.parseVoIPPayload(payload: PKPushPayload) -> VoicePushInfo?` to parses and returns the caller related information from the VoIP notification.
- New Callback added `Call.onClosedCaptionsInfoChanged: ((ClosedCaptionsInfo) -> Void)?` to notify when ClosedCaptionsInfo changes for this `Call`.
- Ability to support assisted transfer when the SDK client already has 2 active calls.
- Subscribing for certain call events via mercury is now supported.
- Optimised WxC Calling only sdk for runtime performance.

### Updated
- FIXED: Made `MediaRenderView` optional while setting MediaOption.
- FIXED: activeSpeakerChangedEvent event notified when the active speaker changes in the meeting

## [3.9.2](https://github.com/webex/webex-ios-sdk/releases/tag/3.9.2)
Released on **11 Aug, 2023**.
### Added
- New API added `Phone.dialPhoneNumber(_ address: String, option: MediaOption, completionHandler: @escaping (Result<Call>) -> Void)` to dial only phone numbers.
- New API `CallHistoryRecord.isPhoneNumber` to denote if the number dialled in call record was a phone number.

### Updated
- FIXED: Enabling preservation of AVRoutePickerView choices for audio/video output in pre-meeting/call screens.
- FIXED: Removed Camera permissions and H264 prompt for audio only flows.
- FIXED: Call failed or meeting failure issue due to mediaTimeout.

## [3.9.1](https://github.com/webex/webex-ios-sdk/releases/tag/3.9.1)
Released on **19 June, 2023**.
### Added
- New API added `Call.externalTrackingId` to get the external tracking id for corresponding call. Applicable only for WxC calls.
- Webhook URL can be set to get incoming WxC calls.

### Updated
- FIXED: Self video turning off in case of poor uplink event.

## [3.9.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.9.0)
Released on **5 June, 2023**.
#### Added
- New SDK variant `Webex/Wxc`, a light weight SDK for WebexCalling.
- New struct `ShareConfig` a data type to represent the share screen configuration.
- New Callback `Call.onStartRinger: ((RingerType) -> Void)` when a ringer has to be started.
- New Callback `Call.onStopRinger: ((RingerType) -> Void)` when a ringer has to be stopped.
- New Enum `Call.RingerType` for a ringerType to denote the type of tone to be played / stopped.
- New Enum `CallMembership.DeviceType` for device types.
- New Enum `ShareOptimizeType` to represent  the OptimiseType for share screen.
- New API `Person.encodedId` to get base64 encoded Id of the person.
- New API `CallMembership.deviceType` to get device type joined by this CallMembership.
- New API `CallMembership.pairedMemberships` to get all memberships joined using deviceType Room.
- New API `Call.isVideoEnabled` to Indicate whether video calling is enabled for the user in Control hub.
- New API `Call.getShareConfig()` to get the share screen optimisation type of the call.
- New Feature to support multiple active Webex calls.
- New Feature to support end-to-end encrypted meetings.
- Authorization code can be set using `call.send(dtmf: String, completionHandler: ((Error?) -> Void)?)` API for Wxc calls.
- New API `Call.receivingNoiseInfo` to get the info object which contains information on Receiving noise removal state.
- New API `Call.enableReceivingNoiseRemoval(shouldEnable: Bool)` to enable or disable receiving noise removal functionality for incoming PSTN calls.

#### Updated
- Updated `Message.Text.plain`, `Message.Text.html` and `Message.Text.markdown` from internal to public private(set) access.
- Screen sharing now have optimisation options as part of share config in `startSharing()`
- Now FedRamp can be enabled through authenticators.
- Now `DisconnectReason.RemoteCancel` event will be fired when host ends meeting for all or kicked by host.
- FIXED: Unable to connect with bluetooth devices for call issue.
- FIXED: Webex calling failures for certificate issues.
- FIXED : MessagesUpdate callback getting called for internal provisional messages.
- FIXED : MessagesUpdate callback not getting called with decrypted content in some cases, after list message API was called.

## [3.8.3](https://github.com/webex/webex-ios-sdk/releases/tag/3.8.3)
Released on **16 Mar, 2023**.
#### Updated
-  FIXED - Fixed an issue where the SDK logs not showing in Xcode console.

## [3.8.2](https://github.com/webex/webex-ios-sdk/releases/tag/3.8.2)
Released on **17 Feb, 2023**.
#### Updated
-  FIXED - Fixed an issue where the SDK wasn't working for Xcode simulators.

## [3.8.1](https://github.com/webex/webex-ios-sdk/releases/tag/3.8.1)
Released on **08 Feb, 2023**.
#### Updated
-  FIXED - Fixed an issue where the SDK wasn't compiling for Xcode versions below Xcode14.

## [3.8.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.8.0)
Released on **25 January, 2023**.
#### Added
- New SDK variant `WebexSDK/Meeting`, a light weighted meeting-only SDK(doesn’t include calling).
- New API `setCallServiceCredential(username: String, password: String)` to set username and password for authentication with calling service.
- New API `Message.isContentDecrypted: Bool` to denote if the content of the message is decrypted.
- New API `CallHistoryRecord.isMissedCall: Bool` to denote if a CallHistoryRecord is a missed call.
- New API `Phone.connectPhoneServices(completionHandler: @escaping (Result<Void>) -> Void)` to connect from the server for CallingType.WebexCalling and CallingType.WebexForBroadworks.
- New API `Phone.disconnectPhoneServices(completionHandler: @escaping (Result<Void>) -> Void)` to disconnect from the server for CallingType.WebexCalling and CallingType.WebexForBroadworks.
- New API `Phone.setPushTokens(bundleId: String, deviceId: String, deviceToken: String, voipToken: String)` to set the tokens for the notification.
- New API `Phone.processPushNotification(message: String, completionHandler: @escaping (Error?) -> Void)` to process the push notification to trigger incoming call callback.
- New API `Call.isWebexCallingOrWebexForBroadworks: Bool` to denote if this call is Webex or Broadworks call.
- New API `Call.isAudioOnly: Bool` to denite if this is an audio-only call.
- New API `Call.directTransferCall(toPhoneNumber: String, completionHandler: @escaping (Error?) -> Void)` to directly transfer a call.
- New API `Call.switchToVideoCall(completionHandler: @escaping (Result<Void>) -> Void)` to switch the current Webex Calling call to a Video call.
- New API `Call.switchToAudioCall(completionHandler: @escaping (Result<Void>) -> Void)` to switch the current Webex Calling call to an Audio-only call.
- New API `SpaceClient.isSpacesSyncCompleted: Bool` to denote if syncing latest conversations to local data warehouse is complete.
- New callback `SpaceClient.onSyncingSpacesStatusChanged: ((_ isSyncInProgress: Bool) -> Void)?` to notify when syncing status for spaces changes.
- New callback `Webex.onInitialSpacesSyncCompleted: (() -> Void)?` to denote if syncing latest conversations to local data warehouse is complete.
- Added new enum `UCLoginFailureReason` to denote the failure reason while logging in to CUCM.
- Added new enum `PhoneConnectionError` to denote the error while connecting to phone services. 
- Added new enum `CallingType` to represent calling feature type enabled for current logged in user.

#### Updated
-  In `WebexUCLoginDelegate.onUCLoginFailed` failureReason field is added.
-  FIXED - Crash while applying Virtual Background
-  FIXED - Intermittent crash during calling

#### Deprecated
 - Deprecated API `setCUCMCredential(username: String, password: String)` instead use `setCallServiceCredential(username: String, password: String)`

 ---
## [3.7.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.7.0)
Released on **30 September, 2022**.
#### Added
- New struct `Captcha` to represent the Captcha object.
- New struct `Breakout` A data type to represent the breakout.
- New struct `BreakoutSession` A data type to represent the breakout session.
- New case `forbidden` in enum `CreatePersonError`, `UpdatePersonError`
- Three new cases `invalidPassword(reason: String)`, `captchaRequired(captcha: Phone.Captcha)`, `invalidPasswordWithCaptcha(captcha: Phone.Captcha)` to enum `WebexError`
- New API `Phone.isRestrictedNetwork: Bool` to check whether the device is in a restricted network.
- New API `Call.joinBreakoutSession(session: BreakoutSession)` to join the Breakout Session manually by passing the `BreakoutSession` if host has enabled allow join session later.
- New API `Call.returnToMainSession()` to return to main session.
- New API `Phone.refreshMeetingCaptcha(completionHandler: @escaping (Result<Captcha>) -> Void)` to refresh the Captcha object to get a new Captcha code.
- New API `Call.correlationId: String?` to get the correlationId for that particular call.
- New API `MediaOption.captchaId: String?` to get & set unique id for the captcha.
- New API `MediaOption.captchaVerifyCode: String?` to get & set captcha verification code to be entered by user.
- New API `Space.isExternallyOwned: Bool?` It will be true If a space is owned/created by non-org/external user.
- New callback `onRestrictedNetworkStatusChanged: ((_ status: Bool) -> Void)?` to monitor restricted network status changes.
- New callback `Call.onBreakoutErrorHappened: ((BreakoutError) -> Void)?` to notify when any breakout api returns error.
- New callback `Call.onBreakoutUpdated: ((Breakout) -> Void)?` to notify when Breakout is updated.
- New callback `Call.onBroadcastMessageReceivedFromHost: ((String) -> Void)?` to notify when host broadcast the message to the session.
- New callback `Call.onHostAskingReturnToMainSession: (() -> Void)?` to notify when host is asking participants to return to main meeting.
- New callback `Call.onJoinableSessionListUpdated: (([BreakoutSession]) -> Void)?` to notify when list of join breakout session changes.
- New callback `Call.onJoinedSessionUpdated: ((BreakoutSession) -> Void)?` to notify when joined Breakout session is updated.
- New callback `Call.onReturnedToMainSession: (() -> Void)?` to notify when returned to main session.
- New callback `Call.onSessionClosing: (() -> Void)?` to notify when Breakout session is closing.
- New callback `Call.onSessionEnabled: (() -> Void)?` to notify when Breakout session is enabled.
- New callback `Call.onSessionJoined: ((BreakoutSession) -> Void)?` to notify when Breakout session is joined.
- New callback `Call.onSessionStarted: ((Breakout) -> Void)?` to notify when Breakout session is started.

#### Updated
- `roles`,`licenses` and `siteUrls` fields are added to the `Person` class.
-  In `Person.update` displayName field is not optional now

---
## [3.6.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.6.0)
Released on 2022-08-24
#### Added
- Added new API `call.setMediaStreamCategoryC(participantId: String, quality: MediaStreamQuality)` to pin the participant's tream with the specified params if it does not already exist. Otherwise, update the pinned participant's stream with the specified params
- Added new API `call.removeMediaStreamCategoryC(participantId: String)` to remove the pinning of a participant's stream
- Added new API `Webex.startUCServices()` to start login process of CUCM
- Added new API `Webex.retryUCSSOLogin()` in case UC sso login expires or requires a retry
- Added new API `Webex.forceRegisterPhoneServices()` to handle `RegisteredElsewhere` error
- Added new struct `CallHistoryRecord`
- Added new callback `onUCSSOLoginFailed(failureReason: UCSSOFailureReason)` to notify app when SSO login fails.

#### Updated
- Added Support for message with video and thumbnail
- Post message api was returning the message object with mentions as empty array
- List message api bug fixes to return correct data before a provided date or time and honouring max value
- Fixed a condition where the sdk crashes because of unguarded null pointer access on logout
- Fixed an issue with space ID encoding when a meeting is started
- Fixed CUCM login for SSO authentication
- Fixed CUCM call history
- Renamed callback `showUCSSOLoginView(to url: String)` to `loadUCSSOView(to url: String)`
- Refactored `Phone.getCallHistory()` to return `CallHistoryRecord`s instead of `Space`s
---
---
## [3.5.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.5.0)
Released on 2022-06-07
#### Added
- Added new enum `MediaStream` to denote the Media stream
- Added new enum `MediaStreamQuality` to denote the Media stream quality
- Added new enum `MediaStreamChangeEventType` to denote the MediaStreamChangeEvent type
- Added new enum `MediaStreamChangeEventInfo` to denote the changed event information
- Added new API 'call.mediaStreams' to get all opened auxiliary streams
- Added new API `call.onMediaStreamAvailabilityListener` to notify when media stream is available/unavailable
- Added new API `stream.setOnMediaStreamInfoChanged` to notify when media stream info is change
- Added new API `call.setMediaStreamCategoryA(duplicate: Bool, quality: MediaStreamQuality)` to add the Active Speaker stream with the specified params if it does not already exist. Otherwise, update the Active Speaker stream with the specified params.
- Added new API `call.setMediaStreamsCategoryB(numStreams: Int, quality: MediaStreamQuality)` to set all category B streams to the specified params
- Added new API `call.removeMediaStreamCategoryA()` to remove the Active Speaker stream
- Added new API `call.removeMediaStreamsCategoryB()` to remove all category B streams

#### Updated
Support for 1080p video resolution
-  `webex.phone.videoMaxTxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue` to capture Full HD resolution video
-  `webex.phone.videoMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue` To receive Full HD resolution video
-  FIXED - VBG issues
-  FIXED - postToPerson api issue fixed for JWT users
---
## [3.4.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.4.0)
Released on 2022-04-19
#### Added
- Added new enum `MediaQualityInfo` to denote the media quality
- Added new API `Call.onMediaQualityInfoChanged()` to notify when media quality is changed
- Added new API `Message.Text.html(html: String) -> Text`
- Added new API `Message.Text.markdown(markdown: String) -> Text`

#### Updated
- Fixed - Crash when remote user starts or stops sharing
- Fixed - Call pipeline improvement
- Fixed - List messages before messageId not returning messages
- Fixed - Text object type incorrect on received messages- 
- Fixed - Message sender details incorrect in integration use case

#### Deprecated 
- Sending multiple formats of text in the same message is not supported. Below Text constructors are deprecated
    - `Message.Text.html(html: String, plain: String? = nil) -> Text`
    - `Message.Text.markdown(markdown: String, html: String, plain: String? = nil) -> Text`

## [3.3.0](https://github.com/webex/webex-ios-sdk/releases/tag/3.3.0)
Released on 2022-02-15
#### Added
- Added new API `Call.wxa` for Webex assistant and real time transcription controls
- Added new API `Call.cameraTorchMode`
- Added new API `Call.cameraFlashMode`
- Added new API `Call.zoomFactor`
- Added new API `Call.exposureDuration`
- Added new API `Call.exposureISO`
- Added new API `Call.exposureTargetBias`
- Added new API `Call.setCameraFocusAtPoint(:pointX:pointY)`
- Added new API `Call.setCameraCustomExposure(:duration:iso)`
- Added new API `Call.setCameraAutoExposure(:targetBias)`
- Added new API `Call.takePhoto()`

#### Updated
- Enhanced documentation coverage
- Decoupled WebexBroadcastExtensionKit from WebexSDK
- Fixed thumbnail for high resolution images not loading
- Fixed decoding of special characters in urlencoded Guest issuer JWT token
- Made exp field as optional in Guest Issuer JWT
- Fixed callback not being fired for deleting self membership from space
- Fixed an issue with fetching inter-cluster team memberships

## [3.2.1](https://github.com/webex/webex-ios-sdk/releases/tag/3.2.1)
Released on 2021-11-30
#### Added
- Added new API `Call.forceSendingVideoLandscape(forceLandscape:completionHandler:)` to set local video view in landscape

#### Updated
- Added new field `locusUrl` to `Call` struct

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
