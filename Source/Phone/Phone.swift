// Copyright 2016-2020 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import AVFoundation

/// Phone represents a Cisco Webex calling device.
/// The application can obtain a *phone* object from `Webex` object
/// and use *phone* to call other Cisco Webex users or PSTN when enabled.
/// The *phone* must be registered before it can make or receive calls.
///
/// ```` swift
///     webex.phone.register() { error in
///       if let error = error {
///         ... // Device was not registered, and no calls can be sent or received
///       } else {
///         ... // Successfully registered device
///       }
///     }
/// ````
/// - since: 1.2.0
public class Phone {
    
    /// The enumeration of Camera facing modes.
    ///
    /// - since: 1.2.0
    public enum FacingMode {
        /// Front camera.
        case user
        /// Back camera.
        case environment
    }
    
    /// The enumeration of common bandwidth choices.
    ///
    /// - since: 1.3.0
    public enum DefaultBandwidth: UInt32 {
        /// 177Kbps for 160x90 resolution
        case maxBandwidth90p = 177000
        /// 384Kbps for 320x180 resolution
        case maxBandwidth180p = 384000
        /// 768Kbps for 640x360 resolution
        case maxBandwidth360p = 768000
        /// 2.5Mbps for 1280x720 resolution
        case maxBandwidth720p = 2500000
        /// 4Mbps for 1920x1080 resolution
        case maxBandwidth1080p = 4000000
        /// 8Mbps data session
        case maxBandwidthSession = 8000000
        /// 64kbps for voice
        case maxBandwidthAudio = 64000
    }
    
    /// The enumeration of advanced settings.
    /// These settings are for special use cases and usually do not need to be set.
    ///
    /// - since: 2.6.0
    public enum AdvancedSettings {
        
//        public enum MixingStream: UInt8 {
//            case client = 3, server = 1, `default` = 0
//        }
//        case audioForwardErrorCorrection(Bool)
//        case audioEchoCanccellation(Bool)
//        case audioMixingStream(MixingStream)
//        case activeSpeakerOverRTCP(Bool)
//        case audioAutomaticGainControl(Bool)
//        case audioNoiseSupression(Bool)
//        case audioVoiceActivityDetection(Bool)
//        case deviceUseRemoteSettings(Bool)
//        case videoReceiverBasedQosSupported(Bool)
        /// Enable or disable the video mosaic for error-concealment when data loss in network. The defaule is enable.
        case videoEnableDecoderMosaic(Bool)
        /// The max sending fps for video. If 0, default value of 30 is used.
        case videoMaxTxFPS(UInt)
    }

    /// The options for H.264 video codec license from Cisco Systems, Inc
    ///
    /// - since: 2.6.0
    public enum H264LicenseAction {
        /// Indicates that the end user has accepted the term.
        case accept
        /// Indicates that the end user declined the term.
        case decline
        /// Indicates that the end user wants to view the license.
        case viewLicense(url: URL)
    }
    
    /// MARK: - Deprecated
    /// The max receiving bandwidth for audio in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 64 * 1000 is used.
    ///
    /// - since: 1.3.0
    @available(*, deprecated)
    public var audioMaxBandwidth: UInt32 {
        get {
            return self.audioMaxRxBandwidth
        }
        set {
            self.audioMaxRxBandwidth = newValue
        }
    }
    
    /// MARK: - Deprecated
    /// The max receiving bandwidth for video in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 2000*1000 is used.
    ///
    /// - since: 1.3.0
    @available(*, deprecated)
    public var videoMaxBandwidth: UInt32 {
        get {
            return self.videoMaxRxBandwidth
        }
        set {
            self.videoMaxRxBandwidth = newValue
        }
    }
    
    /// MARK: - Deprecated
    /// The max receiving bandwidth for screen sharing in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 4000*1000 is used.
    ///
    /// - since: 1.3.0
    @available(*, deprecated)
    public var screenShareMaxBandwidth: UInt32 {
        get {
            return self.sharingMaxRxBandwidth
        }
        set {
            self.sharingMaxRxBandwidth = newValue
        }
    }
    
    /// The max receiving bandwidth for audio in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 64 * 1000 is used.
    ///
    /// - since: 2.6.0
    public var audioMaxRxBandwidth: UInt32 = DefaultBandwidth.maxBandwidthAudio.rawValue
    
    /// The max receiving bandwidth for video in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 2000*1000 is used.
    ///
    /// - since: 2.6.0
    public var videoMaxRxBandwidth: UInt32 = DefaultBandwidth.maxBandwidth720p.rawValue
    
    /// The max sending bandwidth for video in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 2000*1000 is used.
    ///
    /// - since: 2.6.0
    public var videoMaxTxBandwidth: UInt32 = DefaultBandwidth.maxBandwidth720p.rawValue
    
    /// The max receiving bandwidth for screen sharing in unit bps for the call.
    /// Only effective if set before the start of call.
    /// if 0, default value of 4000*1000 is used.
    ///
    /// - since: 2.6.0
    public var sharingMaxRxBandwidth: UInt32 = DefaultBandwidth.maxBandwidthSession.rawValue

    /// The advanced setings for call. Only effective if set before the start of call.
    ///
    /// - since: 2.6.0
    public var advancedSettings: [AdvancedSettings] = []

    /// The default values of the advanced setings for call.
    ///
    /// - since: 2.6.0
    public let defaultAdvancedSettings: [AdvancedSettings] = [.videoEnableDecoderMosaic(true),
                                                              .videoMaxTxFPS(0),
//                                                           .deviceUseRemoteSettings(false),
//                                                           .activeSpeakerOverRTCP(true),
//                                                           .audioAutomaticGainControl(true),
//                                                           .audioEchoCanccellation(false),
//                                                           .audioForwardErrorCorrection(true),
//                                                           .audioNoiseSupression(false),
//                                                           .audioVoiceActivityDetection(false),
//                                                           .audioMixingStream(AdvancedSettings.MixingStream.default),
//                                                           .videoReceiverBasedQosSupported(true)
    ]
    
    /// Default camera facing mode of this phone, used as the default when dialing or answering a call.
    /// The default mode is the front camera.
    ///
    /// - note: The setting is not persistent
    /// - since: 1.2.0
    public var defaultFacingMode = FacingMode.user
    
    /// Default loud speaker mode of this phone, used as the default when dialing or answering a call.
    /// True as using loud speaker, False as not. The default is using loud speaker.
    ///
    /// - note: The setting is not persistent.
    /// - since: 1.2.0
    public var defaultLoudSpeaker: Bool = true
    
    /// Callback when call is incoming.
    ///
    /// - since: 1.2.0
    public var onIncoming: ((Call) -> Void)?

    /// Indicates whether or not the SDK is connected with the Cisco Webex cloud.
    ///
    /// - since: 1.4.0
    public private(set) var connected: Bool = false
    
    /// Indicates whether or not the SDK is registered with the Cisco Webex cloud.
    ///
    /// - since: 1.4.0
    public var registered: Bool {
        return self.devices.device != nil
    }
    
    weak var webex: Webex?
    let authenticator: Authenticator
    let reachability: ReachabilityService
    let devices: DeviceService
    let client: CallClient
    let prompter: H264LicensePrompter
    let queue = SerialQueue()
    let metrics: MetricsEngine
    private(set) var me:Person?
    
    private let webSocket: WebSocketService
    private var calls = [String: Call]()
    private var mediaContext: MediaSessionWrapper?

    private var _canceled: Bool = false
    private var canceled: Bool {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if self._canceled {
                self._canceled = false
                return true
            }
            return false
        }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            self._canceled = newValue
        }
    }

    let phoneId: String = UUID().uuidString
    private let nilJsonStr = "Nil JSON"
    var debug = true;

    enum LocusResult {
        case call(UUID, Device, MediaOption, MediaSessionWrapper, ServiceResponse<LocusModel>, (Result<Call>) -> Void)
        case join(Call, ServiceResponse<LocusModel>, (Error?) -> Void)
        case leave(Call, ServiceResponse<LocusModel>, (Error?) -> Void)
        case reject(Call, ServiceResponse<Any>, (Error?) -> Void)
        case alert(Call, ServiceResponse<Any>, (Error?) -> Void)
        case update(Call, ServiceResponse<LocusModel>, ((Error?) -> Void)?)
        case updateMediaShare(Call, ServiceResponse<Any>, (Error?) -> Void)
    }

    convenience init(webex: Webex) {
        let device = DeviceService(authenticator: webex.authenticator)
        let tempMetrics = MetricsEngine(authenticator: webex.authenticator, service: device)
        self.init(webex: webex,
                devices: device,
                reachability: ReachabilityService(authenticator: webex.authenticator, deviceService: device),
                client: CallClient(authenticator: webex.authenticator),
                metrics: tempMetrics, prompter: H264LicensePrompter(metrics: tempMetrics), webSocket: WebSocketService(authenticator: webex.authenticator))
    }
    
    init(webex: Webex, devices:DeviceService, reachability:ReachabilityService, client:CallClient, metrics:MetricsEngine, prompter:H264LicensePrompter, webSocket:WebSocketService) {
        let _ = MediaEngineWrapper.sharedInstance.wmeVersion
        self.webex = webex
        self.authenticator = webex.authenticator
        self.devices = devices
        self.reachability = reachability
        self.client = client
        self.metrics = metrics
        self.prompter = prompter
        self.webSocket = webSocket
        self.webSocket.onEvent = { [weak self] event in
            if let strong = self {
                strong.queue.underlying.async {
                    switch event {
                    case .recvCall(let model):
                        strong.doLocusEvent(model);
                    case .recvActivity(let model):
                        strong.doActivityEvent(model);
                    case .recvKms(let model):
                        strong.doKmsEvent(model);
                    case .connected:
                        strong.connected = true
                    case .disconnected(let error):
                        strong.connected = false
                        if error != nil {
                            strong.register {_ in
                            }
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        self.metrics.release()
    }
    
    /// Registers this phone to Cisco Webex cloud on behalf of the authenticated user.
    /// It also creates the websocket and connects to Cisco Webex cloud.
    /// Subsequent invocations of this method refresh the registration.
    ///
    /// - parameter completionHandler: A closure to be executed when completed, with error if the invocation is illegal or failed, otherwise nil.
    /// - returns: Void
    /// - since: 1.2.0
    public func register(_ completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            self.devices.registerDevice(phone: self, queue: self.queue.underlying) { result in
                switch result {
                case .success(let device):
                    PersonClient(authenticator: self.authenticator).getMe { responseOfGetMe in
                        switch responseOfGetMe.result {
                        case .success(let person):
                            self.me = person
                            self.webSocket.connect(device.webSocketUrl) { [weak self] error in
                                if let error = error {
                                    PhoneError.registerFailure.report(cause: error)
                                }
                                if let strong = self {
                                    strong.queue.underlying.async {
                                        strong.fetchActiveCalls()
                                        DispatchQueue.main.async {
                                            strong.reachability.fetch()
                                            strong.startObserving()
                                            completionHandler(error)
                                        }
                                        strong.queue.yield()
                                    }
                                }
                            }
                        case .failure(let error):
                            SDKLogger.shared.error("GetMe failed", error: error)
                            DispatchQueue.main.async {
                                completionHandler(error)
                            }
                            self.queue.yield()
                        }
                    }
                case .failure(let error):
                    PhoneError.registerFailure.report(cause: error, errorCallback: completionHandler)
                    self.queue.yield()
                }
            }
        }
    }
    
    /// Removes this *phone* from Cisco Webex cloud on behalf of the authenticated user.
    /// It also disconnects the websocket from Cisco Webex cloud.
    /// Subsequent invocations of this method behave as a no-op.
    ///
    /// - parameter completionHandler: A closure to be executed when completed, with error if the invocation is illegal or failed, otherwise nil.
    /// - returns: Void
    /// - since: 1.2.0
    public func deregister(_ completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            self.devices.deregisterDevice(queue: self.queue.underlying) { error in
                self.disconnectFromWebSocket()
                DispatchQueue.main.async {
                    self.reachability.clear()
                    self.stopObserving()
                    completionHandler(error)
                }
                self.queue.yield()
            }
        }
    }

    /// Makes a call to an intended recipient on behalf of the authenticated user.
    /// It supports the following address formats for the receipient:
    ///
    /// >
    ///  * Webex URI: e.g. webex:shenning@cisco.com
    ///  * SIP / SIPS URI: e.g. sip:1234@care.acme.com
    ///  * Tropo URI: e.g. tropo:999123456
    ///  * Email address: e.g. shenning@cisco.com
    /// >
    ///
    /// - parameter address: Intended recipient address in one of the supported formats.
    /// - parameter option: Intended media options - audio only or audio and video - for the call.
    /// - parameter completionHandler: A closure to be executed when completed.
    /// - returns: a Call object
    /// - throw:
    /// - since: 1.2.0
    /// - attention: Currently the SDK only supports one active call at a time. Invoking this function while there is an active call will generate an exception.
    public func dial(_ address: String, option: MediaOption, completionHandler: @escaping (Result<Call>) -> Void) {
        self.canceled = false
        prepare(option: option) { error in
            if let error = error {
                completionHandler(Result.failure(error))
            }
            else {
                if self.calls.filter({$0.value.status == CallStatus.connected}).count > 0 {
                    PhoneError.otherActiveCall.report(resultCallback: completionHandler)
                    return
                }
                self.requestMediaAccess(option: option) {
                    let session = self.mediaContext ?? MediaSessionWrapper()
                    session.prepare(option: option, phone: self)
                    let localSDP = session.getLocalSdp()
                    let reachabilities = self.reachability.feedback?.reachabilities

                    CallClient.DialTarget.lookup(address, by: Webex(authenticator: self.authenticator)) { target in
                        self.queue.sync {
                            if let device = self.devices.device {
                                if self.canceled {
                                    PhoneError.callCanceled.report(resultCallback: completionHandler)
                                    self.queue.yield()
                                    return
                                }
                                let media = MediaModel(sdp: localSDP, audioMuted: false, videoMuted: false, reachabilities: reachabilities)
                                let correlationId = UUID()
                                switch target {
                                case .callable(let callee):
                                    self.client.call(callee, correlationId: correlationId, by: device, option: option, localMedia: media, queue: self.queue.underlying) { res in
                                        self.doLocusResponse(LocusResult.call(correlationId, device, option, session, res, completionHandler))
                                        self.queue.yield()
                                    }
                                case .joinable(let joinee):
                                    self.client.getOrCreatePermanentLocus(conversation: joinee, by: device, queue: self.queue.underlying) { res in
                                        if self.canceled {
                                            PhoneError.callCanceled.report(resultCallback: completionHandler)
                                            self.queue.yield()
                                        }
                                        else if let url = res.data {
                                            self.client.join(url, correlationId: correlationId, by: device, option: option, localMedia: media, queue: self.queue.underlying) { joinRes in
                                                self.doLocusResponse(LocusResult.call(correlationId, device, option, session, joinRes, completionHandler))
                                                self.queue.yield()
                                            }
                                        }
                                        else {
                                            PhoneError.failureCall.report(cause: res.error, resultCallback: completionHandler)
                                            self.queue.yield()
                                        }
                                    }
                                }
                            }
                            else {
                                WebexError.unregistered.report(resultCallback: completionHandler)
                                self.queue.yield()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Cancel the currently outgoing call that has not been connected.
    /// - since: 2.6.0
    public func cancel() {
        self.canceled = true
    }

    /// Pops up an Alert for the end user to approve the use of H.264 codec license from Cisco Systems, Inc.
    ///
    /// - parameter completionHandler: A closure to be executed when completed.
    /// - note: Invoking this function is optional since the alert will appear automatically during the first video call.
    /// - since: 1.2.0
    public func requestVideoCodecActivation(completionHandler: ((H264LicenseAction) -> Void)? = nil) {
        self.prompter.check() { action in
            if let completionHandler = completionHandler {
                completionHandler(action)
            }
            else {
                switch action {
                case .viewLicense(let url):
                    UIApplication.shared.open(url, options:[:], completionHandler: nil)
                default:
                    break
                }
            }
            
        }
    }
    
    /// Prevents Cisco Webex iOS SDK from poping up an Alert for the end user
    /// to approve the use of H.264 video codec license from Cisco Systems, Inc.
    ///
    /// - returns: Void
    /// - attention: The function is expected to be called only by Cisco internal applications. 3rd-party applications should NOT call this function.
    /// - since: 1.2.0
    public func disableVideoCodecActivation() {
        self.prompter.disable = true
    }
    
    /// Render a preview of the local party before the call is answered.
    ///
    /// - parameter view: an UI view for rendering video.
    /// - returns: Void
    public func startPreview(view: MediaRenderView) {
        DispatchQueue.main.async {
            if self.mediaContext == nil {
                self.mediaContext = MediaSessionWrapper()
            }
            _ = self.mediaContext?.startPreview(view: view, phone: self)
        }
    }
    
    /// Stop rendering the preview of the local party.
    ///
    /// - returns: Void
    public func stopPreview() {
        DispatchQueue.main.async {
            if let media = self.mediaContext {
                media.stopPreview()
            }
        }
    }
    
    private func add(call: Call) {
        calls[call.url] = call;
        SDKLogger.shared.info("Add call for call url:\(call.url)")
    }
    
    func remove(call: Call) {
        calls[call.url] = nil
        SDKLogger.shared.info("Remove call for call url:\(call.url)")
    }

    func acknowledge(call: Call, completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            if self.calls.filter({ $0.key != call.url }).count > 0 {
                PhoneError.otherActiveCall.report(errorCallback: completionHandler)
                self.queue.yield()
                return
            }
            if call.direction == Call.Direction.outgoing {
                PhoneError.unSupportFunction.report(errorCallback: completionHandler)
                self.queue.yield()
                return
            }
            if call.direction == Call.Direction.incoming && call.status != CallStatus.initiated {
                WebexError.illegalStatus(reason: "Not initialted call").report(errorCallback: completionHandler)
                self.queue.yield()
                return
            }
            if let url = call.model.locusUrl {
                self.client.alert(url, by: call.device, queue: self.queue.underlying) { res in
                    self.doLocusResponse(LocusResult.alert(call, res, completionHandler))
                    self.queue.yield()
                }
            }
            else {
                WebexError.serviceFailed(reason: "Missing call URL").report(errorCallback: completionHandler)
                self.queue.yield()
            }
        }
    }
    
    func answer(call: Call, option: MediaOption, completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            if self.calls.filter({ $0.key != call.url && $0.value.status == CallStatus.connected}).count > 0 {
                PhoneError.otherActiveCall.report(errorCallback: completionHandler)
                return
            }
            if call.direction == Call.Direction.outgoing {
                PhoneError.unSupportFunction.report(errorCallback: completionHandler)
                return
            }
            if call.direction == Call.Direction.incoming {
                if call.status == CallStatus.connected {
                    PhoneError.alreadyConnected.report(errorCallback: completionHandler)
                    return
                }
                else if call.status == CallStatus.disconnected {
                    PhoneError.alreadyDisconnected.report(errorCallback: completionHandler)
                    return
                }
            }
            if let uuid = option.uuid {
                call.uuid = uuid
            }
            self.requestMediaAccess(option: option) {
                let session = call.mediaSession
                session.prepare(option: option, phone: self)
                let media = MediaModel(sdp: session.getLocalSdp(), audioMuted: false, videoMuted: false, reachabilities: self.reachability.feedback?.reachabilities)
                self.queue.sync {
                    self.client.join(call.url, correlationId: call.correlationId, by: call.device, option: option, localMedia: media, queue: self.queue.underlying) { res in
                        self.doLocusResponse(LocusResult.join(call, res, completionHandler))
                        self.queue.yield()
                    }
                }
            }
        }
    }
    
    func reject(call: Call, completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            if call.direction == Call.Direction.outgoing {
                PhoneError.unSupportFunction.report(errorCallback: completionHandler)
                self.queue.yield()
                return
            }
            if call.direction == Call.Direction.incoming {
                if call.status == CallStatus.connected {
                    PhoneError.alreadyConnected.report(errorCallback: completionHandler)
                    self.queue.yield()
                    return
                }
                else if call.status == CallStatus.disconnected {
                    PhoneError.alreadyDisconnected.report(errorCallback: completionHandler)
                    self.queue.yield()
                    return
                }
            }
            if let url = call.model.locusUrl {
                if call.isActive {
                    self.client.decline(url, by: call.device, queue: self.queue.underlying) { res in
                        self.doLocusResponse(LocusResult.reject(call, res, completionHandler))
                        self.queue.yield()
                    }
                }else {
                    WebexError.serviceFailed(reason: "Cannot decline a non-active schedule call").report(errorCallback: completionHandler)
                    self.queue.yield()
                }
            }
            else {
                WebexError.serviceFailed(reason: "Missing call URL").report(errorCallback: completionHandler)
                self.queue.yield()
            }
        }
    }
    
    func hangup(call: Call, completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            if call.status == CallStatus.disconnected {
                PhoneError.alreadyDisconnected.report(errorCallback: completionHandler)
                self.queue.yield()
                return
            }
            if let url = call.model.myself?.url {
                if #available(iOS 11.2, *), call.sendingScreenShare {
                    self.stopSharing(call: call) { _ in
                        SDKLogger.shared.warn("Unshare screen by call end!")
                    }
                    call.mediaSession.stopLocalScreenShare()
                }
                
                self.client.leave(url, by: call.device, queue: self.queue.underlying) { res in
                    self.doLocusResponse(LocusResult.leave(call, res, completionHandler))
                    self.queue.yield()
                }
            }
            else {
                WebexError.serviceFailed(reason: "Missing self participant URL").report(errorCallback: completionHandler)
                self.queue.yield()
            }
        }
    }
    
    func layout(call: Call, layout: MediaOption.VideoLayout) {
        self.queue.sync {
            if let url = call.model.myself?.url {
                self.client.layout(url, by: call.device.deviceUrl.absoluteString, layout: layout, queue: self.queue.underlying) { res in
                    self.queue.yield()
                }
            }
            else {
                WebexError.serviceFailed(reason: "Missing self participant URL").report()
                self.queue.yield()
            }
        }
    }
    
    func update(call: Call, sendingAudio: Bool, sendingVideo: Bool, localSDP:String? = nil, completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            let reachabilities = self.reachability.feedback?.reachabilities
            self.queue.sync {
                guard let url = call.model.myself?.mediaBaseUrl,
                    let sdp = call.model.mediaConnections?.first?.localSdp?.sdp ?? localSDP,
                    let mediaID = call.model.myself?[device: call.device.deviceUrl]?.mediaConnections?.first?.mediaId ?? call.model.mediaConnections?.first?.mediaId else {
                    WebexError.serviceFailed(reason: "Missing media data").report(errorCallback: completionHandler)
                    self.queue.yield()
                    return
                }
                let media = MediaModel(sdp: localSDP == nil ? sdp:localSDP!, audioMuted: !sendingAudio, videoMuted: !sendingVideo, reachabilities: reachabilities)
                self.client.update(url, mediaID: mediaID, localMedia: media, by: call.device, queue: self.queue.underlying) { res in
                    self.doLocusResponse(LocusResult.update(call, res, completionHandler))
                    self.queue.yield()
                }
            }
        }
    }
    
    func fetch(call: Call) {
        self.queue.sync {
            var syncUrl = call.url
            if call.model.sequence?.empty ?? true {
                syncUrl = call.model.syncUrl ?? call.url
                SDKLogger.shared.debug("Requesting sync Delta for locus: \(syncUrl)")
            } else {
                //full sync
                syncUrl = call.url
                SDKLogger.shared.debug("Requesting full sync Delta for locus: \(syncUrl)")
            }
            self.client.fetch(syncUrl, queue: self.queue.underlying) { res in
                self.doLocusResponse(LocusResult.update(call, res, nil))
                self.queue.yield()
            }
        }
    }

    func fetchActiveCalls(queue: DispatchQueue? = nil, completionHandler: @escaping (Result<[LocusModel]>) -> Void) {
        if let device = self.devices.device {
            self.client.fetch(by: device, queue: queue ?? self.queue.underlying) { res in
                completionHandler(res.result)
            }
        }
    }

    func letIn(call:Call, memberships:[CallMembership], completionHandler: @escaping (Error?) -> Void) {
        self.queue.sync {
            if let url = call.model.locusUrl {
                self.client.admit(url, memberships: memberships, queue: self.queue.underlying) { res in
                    self.doLocusResponse(LocusResult.update(call, res, completionHandler))
                    self.queue.yield()
                }
            }
            else {
                WebexError.serviceFailed(reason: "Missing call URL").report(errorCallback: completionHandler)
                self.queue.yield()
            }
        }
    }
    
    func keepAlive(call:Call) {
        self.queue.sync {
            if let keepAliveUrl = call.keepAliveUrl {
                self.client.keepAlive(keepAliveUrl, queue: self.queue.underlying) { res in
                    self.queue.yield()
                }
            }else {
                SDKLogger.shared.error("Failure: Missing keepAliveUrl")
                self.queue.yield()
            }
        }
    }
    
    @available(iOS 11.2,*)
    func startSharing(call:Call, completionHandler: @escaping (Error?) -> Void) {
        if !call.mediaSession.hasScreenShare {
            WebexError.illegalOperation(reason: "Call media option unsupport content share.").report(errorCallback: completionHandler)
            return
        }
        if call.isScreenSharedBySelfDevice() {
            WebexError.illegalStatus(reason: "Already shared by self.").report(errorCallback: completionHandler)
            return
        }
        if call.status != .connected {
            WebexError.illegalStatus(reason: "No active call.").report(errorCallback: completionHandler)
            return
        }
        let floor : MediaShareModel.MediaShareFloor = MediaShareModel.MediaShareFloor(beneficiary: call.model.myself, disposition: MediaShareModel.ShareFloorDisposition.granted, granted: nil, released: nil, requested: nil, requester: call.model.myself)
        let mediaShare : MediaShareModel = MediaShareModel(shareType: MediaShareModel.MediaShareType.screen, url:call.model.mediaShareUrl, shareFloor: floor)
        self.updateMeidaShare(call: call, mediaShare: mediaShare, completionHandler: completionHandler)
    }
    
    @available(iOS 11.2,*)
    func stopSharing(call:Call, completionHandler: @escaping (Error?) -> Void) {
        if !call.mediaSession.hasScreenShare {
            WebexError.illegalOperation(reason: "Call media option unsupport content share.").report(errorCallback: completionHandler)
            return
        }
        if !call.isScreenSharedBySelfDevice() {
            WebexError.illegalStatus(reason: "Local share screen not start.").report(errorCallback: completionHandler)
            return
        }
        let floor : MediaShareModel.MediaShareFloor = MediaShareModel.MediaShareFloor(beneficiary: call.model.myself, disposition: MediaShareModel.ShareFloorDisposition.released, granted: nil, released: nil, requested: nil, requester: call.model.myself)
        let mediaShare : MediaShareModel = MediaShareModel(shareType: MediaShareModel.MediaShareType.screen, url:call.model.mediaShareUrl, shareFloor: floor)
        self.updateMeidaShare(call: call, mediaShare: mediaShare, completionHandler: completionHandler)
    }

    private func doLocusResponse(_ ret: LocusResult) {
        switch ret {
        case .call(let correlationId, let device, let option, let media, let res, let completionHandler):
            switch res.result {
            case .success(let model):
                SDKLogger.shared.debug("Receive call locus response: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
                if model.isValid {
                    let call = Call(model: model, device: device, media: media, direction: Call.Direction.outgoing, group: !model.isOneOnOne, option: option, correlationId: correlationId)
                    if let uuid = option.uuid {
                        call.uuid = uuid
                    }
                    if call.isInIllegalStatus {
                        let error = WebexError.illegalStatus(reason: "The previous session did not end")
                        PhoneError.failureCall.report(cause: error, resultCallback: completionHandler)
                        DispatchQueue.main.async {
                            call.end(reason: Call.DisconnectReason.error(error))
                        }
                        return
                    }
                    self.add(call: call)
                    if self.canceled {
                        PhoneError.callCanceled.report(resultCallback: completionHandler)
                        self.hangup(call: call) { _ in
                            SDKLogger.shared.debug("Call was hung up due to validate dial")
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        if call.model.myself?.isInLobby == true {
                            call.startKeepAlive()
                        }else {
                            call.startMedia()
                        }
                        completionHandler(Result.success(call))
                    }
                }
                else {
                    WebexError.serviceFailed(reason: "Failure: Missing required information when dial").report(resultCallback: completionHandler)
                }
            case .failure(let error):
                PhoneError.failureCall.report(cause: error, resultCallback: completionHandler)
            }
        case .join(let call, let res, let completionHandler):
            switch res.result {
            case .success(let model):
                SDKLogger.shared.debug("Receive join locus response: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
                call.update(model: model)
                DispatchQueue.main.async {
                    call.startMedia()
                    completionHandler(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure join ", error: error)
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
        case .leave(let call, let res, let completionHandler):
            switch res.result {
            case .success(let model):
                SDKLogger.shared.debug("Receive leave locus response: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
                call.update(model: model)
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure leave ", error: error)
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
        case .reject(let call, let res, let completionHandler):
            switch res.result {
            case .success(_):
                SDKLogger.shared.info("Success: reject call")
                call.end(reason: Call.DisconnectReason.localDecline)
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure reject ", error: error)
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
        case .alert(let call, let res, let completionHandler):
            switch res.result {
            case .success(_):
                SDKLogger.shared.info("Success: alert call")
                call.status = .ringing
                DispatchQueue.main.async {
                    call.onRinging?()
                    completionHandler(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure alert ", error: error)
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
        case .update(let call, let res, let completionHandler):
            switch res.result {
            case .success(let model):
                SDKLogger.shared.debug("Receive update media locus response: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
                call.update(model: model)
                DispatchQueue.main.async {
                    completionHandler?(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure update media ", error: error)
                DispatchQueue.main.async {
                    completionHandler?(error)
                }
            }
        case .updateMediaShare( _, let res, let completionHandler):
            switch res.result {
            case .success(let json):
                SDKLogger.shared.debug("Receive update media share locus response: \(json)")
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            case .failure(let error):
                SDKLogger.shared.error("Failure update media share", error: error)
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
        }
        
    }

    private func doLocusEvent(_ model: LocusModel) {
        SDKLogger.shared.debug("Receive locus event: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
        guard let url = model.callUrl else {
            SDKLogger.shared.error("CallModel is missing call url")
            return
        }
        if let call = self.calls[url] {
            call.update(model: model)
        }
        else if let device = self.devices.device, model.isIncomingCall { // || callInfo.hasJoinedOnOtherDevice(deviceUrl: deviceUrl)
            // XXX: Is this conditional intended to add this call even when there is no real device registration information?
            // At the time of writing the deviceService.deviceUrl will return a saved value from the UserDefaults. When the application
            // has been restarted and the reregistration process has not completed, other critical information such as locusServiceUrl
            // will not be available, but the deviceUrl WILL be. This may put the application in a bad state. This code MAY be dealing with
            // a race condition and this MAY be the solution to not dropping a call before reregistration has been completed.
            // If so it needs improvement, if not it may be able to be dropped.
            if model.isValid {
                let call = Call(model: model, device: device, media: self.mediaContext ?? MediaSessionWrapper(), direction: Call.Direction.incoming, group: !model.isOneOnOne, correlationId:UUID())
                self.add(call: call)
                SDKLogger.shared.info("Receive incoming call: \(call.model.callUrl ?? call.uuid.uuidString)")
                DispatchQueue.main.async {
                    self.onIncoming?(call)
                }
            }
            else {
                SDKLogger.shared.info("Receive incoming call with error: \(model)")
            }
            // TODO: need to support other device joined case
        }
        else {
            SDKLogger.shared.info("Cannot handle the CallModel.")
        }
    }

    private func doActivityEvent(_ activity: ActivityModel){
        SDKLogger.shared.debug("Receive acitivity: \(activity.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
        if let clientTempId = activity.clientTempId, clientTempId.starts(with: self.phoneId) {
            SDKLogger.shared.error("The activity is sent by self");
            return
        }
        
        func fire(_ event: Any?) {
            DispatchQueue.main.async {
                if let event = event as? MembershipEvent {
                    self.webex?.memberships.onEvent?(event)
                    self.webex?.memberships.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.me))
                }
                else if let event = event as? SpaceEvent {
                    self.webex?.spaces.onEvent?(event)
                    self.webex?.spaces.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.me))
                }
                else if let event = event as? MessageEvent {
                    self.webex?.messages.onEvent?(event)
                    self.webex?.messages.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.me))
                }
            }
        }
        
        if let verb = activity.verb {
            let target = activity.target?.objectType
            let object = activity.object?.objectType
            let clusterId = self.devices.device?.getClusterId(url: activity.url)
            
            if verb == .add && target == ObjectType.conversation && object == ObjectType.person {
                fire(MembershipEvent.created(Membership(activity: activity, clusterId: clusterId)))
            }
            else if verb == .leave && target == ObjectType.conversation && object == ObjectType.person {
                fire(MembershipEvent.deleted(Membership(activity: activity, clusterId: clusterId)))
            }
            else if (verb == .assignModerator || verb == .unassignModerator) && target == ObjectType.conversation && object == ObjectType.person  {
                fire(MembershipEvent.update(Membership(activity: activity, clusterId: clusterId)))
            }
            else if verb == .acknowledge && target == ObjectType.conversation && object == ObjectType.activity {
                fire(MembershipEvent.messageSeen(Membership(activity: activity, clusterId: clusterId), lastSeenMessage: WebexId(type: .message, cluster: clusterId, uuid: activity.object?.id ?? "").base64Id))
            }
            else if verb == .create && object == ObjectType.conversation, let conv = activity.object as? ConversationModel, let convId = conv.id {
                let base64Id = WebexId(type: .room, cluster: clusterId, uuid: convId).base64Id
                self.webex?.spaces.get(spaceId: base64Id) { res in
                    fire(res.result.data == nil ? nil : SpaceEvent.create(res.result.data!))
                }
            }
            else if verb == .update && object == ObjectType.conversation && target == ObjectType.conversation, let conv = activity.target as? ConversationModel, let convId = conv.id {
                let base64Id = WebexId(type: .room, cluster: clusterId, uuid: convId).base64Id
                self.webex?.spaces.get(spaceId: base64Id) { res in
                    fire(res.result.data == nil ? nil : SpaceEvent.update(res.result.data!))
                }
            }
            else if verb == .post || verb == .share, let convUrl = activity.conversationUrl {
                self.webex?.messages.decrypt(activity: activity, of: convUrl) { decrypted in
                    let message = Message(activity: decrypted, clusterId: clusterId, person: self.me)
                    fire(MessageEvent.messageReceived(self.webex?.messages.cacheMessageIfNeeded(message: message) ?? message))
                }
            }
            else if verb == .update, let convUrl = activity.conversationUrl, let content = activity.object as? ContentModel {
                self.webex?.messages.decrypt(activity: activity, of: convUrl) { decrypted in
                    self.webex?.messages.doMessageUpdated(content: content) { event in
                        fire(event)
                    }
                }
            }
            else if verb == .delete && object == ObjectType.activity, let deleted = activity.object?.id {
                self.webex?.messages.doMessageDeleted(messageId: WebexId(type: .message, cluster: clusterId, uuid: deleted)) { event in
                    fire(event)
                }
            }
            else {
                SDKLogger.shared.error("Not a valid activity \(activity.id ?? (activity.toJSONString() ?? ""))")
            }
        }
    }
    
    private func doKmsEvent( _ model: KmsMessageModel){
        SDKLogger.shared.debug("Receive Kms Message: \(model.toJSONString(prettyPrint: self.debug) ?? nilJsonStr)")
        self.webex?.messages.handle(kms: model)
    }
    
    private func prepare(option: MediaOption, completionHandler: @escaping (Error?) -> Void) {
        if option.hasVideo {
            self.prompter.check() { action in
                switch action {
                case .accept:
                    completionHandler(nil)
                case .decline:
                    completionHandler(WebexError.requireH264)
                case .viewLicense(let url):
                    UIApplication.shared.open(url, options:[:], completionHandler: nil)
                    completionHandler(WebexError.interruptedByViewingH264License)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }

    private func fetchActiveCalls() {
        SDKLogger.shared.info("Fetch call infos")
        self.fetchActiveCalls(queue: self.queue.underlying) { result in
            switch result {
            case .success(let models):
                for model in models {
                    self.doLocusEvent(model)
                }
                SDKLogger.shared.info("Success: fetch call infos")
            case .failure(let error):
                SDKLogger.shared.error("Failure", error: error)
            }
        }
    }
    
    private func startObserving() {
        self.stopObserving();
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidBecomeActive) , name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidEnterBackground) , name: UIApplication.didEnterBackgroundNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidBecomeActive) , name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidEnterBackground) , name: .UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    private func stopObserving() {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    @objc func onApplicationDidBecomeActive() {
        SDKLogger.shared.info("Application did become active")
        self.connectToWebSocket()
    }
    
    @objc func onApplicationDidEnterBackground() {
        SDKLogger.shared.info("Application did enter background")
        self.disconnectFromWebSocket()
    }
    
    private func connectToWebSocket() {
        if let device = self.devices.device {
            self.webSocket.connect(device.webSocketUrl) { [weak self] error in
                if let error = error {
                    PhoneError.registerFailure.report(cause: error)
                }
                self?.queue.underlying.async {
                    self?.fetchActiveCalls()
                }
            }
        }
    }
    
    private func disconnectFromWebSocket() {
        self.webSocket.disconnect()
    }
    
    private func requestMediaAccess(option: MediaOption, completionHandler: @escaping () -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { audioGranted in
            if option.hasVideo {
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { videoGranted in
                    DispatchQueue.main.async {
                        completionHandler()
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
            
        }
    }
    
    func updateMeidaShare(call:Call, mediaShare: MediaShareModel,completionHandler: @escaping (Error?) -> Void) {
        if let url = mediaShare.url {
            self.client.updateMediaShare(mediaShare, shareUrl: url, by: call.device, queue: self.queue.underlying) { res in
                self.doLocusResponse(LocusResult.updateMediaShare(call, res,completionHandler))
                self.queue.yield()
            }
        } else {
            WebexError.serviceFailed(reason: "Unsupport media share.").report(errorCallback: completionHandler)
        }
    }
}

enum PhoneError: String {
    
    case registerFailure = "Failed to register device"
    case unSupportFunction = "Unsupport function for outgoing call"
    case alreadyDisconnected = "Already disconnected"
    case alreadyConnected = "Already connected"
    case failureCall = "Failure call"
    case otherActiveCall = "There are other active calls"
    case callCanceled = "The call be canceled by user"
    
    var failureDesc: String {
        return "Failure: " + self.rawValue
    }

    func report<T>(cause: Error? = nil, by queue: DispatchQueue? = nil, resultCallback: ((Result<T>) -> Void)? = nil) {
        (queue ?? DispatchQueue.main).async {
            SDKLogger.shared.error(self.rawValue, error: cause)
            resultCallback?(Result.failure(cause ?? WebexError.illegalOperation(reason: self.rawValue)))
        }
    }

    func report(cause: Error? = nil, by queue: DispatchQueue? = nil, errorCallback: ((Error?) -> Void)? = nil) {
        (queue ?? DispatchQueue.main).async {
            SDKLogger.shared.error(self.rawValue, error: cause)
            errorCallback?(cause ?? WebexError.illegalOperation(reason: self.rawValue))
        }
    }
}


