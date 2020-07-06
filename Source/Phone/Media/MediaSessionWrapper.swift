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

import Foundation
import Wme

class MediaSessionWrapper {
    
    enum Status {
        case initial, preview, prepare, running
    }
    
    enum MediaType {
        case video((local:MediaRenderView, remote:MediaRenderView)?)
        case screenShare(MediaRenderView?)
    }

    var status: Status = .initial
    var isSharingScreen :Bool = false
    var onBroadcastError: ((ScreenShareError) -> Void)?
    var onBroadcasting: ((Bool) -> Void)?
    
    fileprivate var mediaSession = MediaSession()
    private var mediaSessionObserver: MediaSessionObserver?
    private var broadcastServer: BroadcastConnectionServer?
    private var _remoteVideoRenderMode: Call.VideoRenderMode = .cropFill
    
    // MARK: - SDP
    func getLocalSdp() -> String? {
        mediaSession.createLocalSdpOffer()
        return mediaSession.localSdpOffer
    }
    
    func setRemoteSdp(_ sdp: String) {
        mediaSession.receiveRemoteSdpAnswer(sdp)
    }
    
    var hasAudio: Bool {
        return mediaSession.mediaConstraint.hasAudio
    }
    
    var hasVideo: Bool {
        return mediaSession.mediaConstraint.hasVideo
    }
    
    var hasScreenShare: Bool {
        return mediaSession.mediaConstraint.hasScreenShare
    }
    
    // MARK: - Local View & Remote View

    var localVideoViewSize: CGSize {
        return mediaSession.getRenderViewSize(with: .localVideo)
    }

    var remoteVideoViewSize: CGSize {
        return mediaSession.getRenderViewSize(with: .remoteVideo)
    }
    
    var remoteScreenShareViewSize: CGSize {
        return mediaSession.getRenderViewSize(with: .remoteScreenShare)
    }
    
    var localScreenShareViewSize: CGSize {
        return mediaSession.getRenderViewSize(with: .localScreenShare)
    }
    
    var remoteVideoRenderMode: Call.VideoRenderMode {
        get {
            return self._remoteVideoRenderMode
        }
        set {
            self._remoteVideoRenderMode = newValue
            adjustRemoteRenderViewSize()
            mediaSession.setRemoteVideoRenderMode(newValue.wmeMode)
        }
    }
    
    var videoViews: (local:MediaRenderView,remote:MediaRenderView)? {
        if let localView = mediaSession.getRenderView(with: .localVideo) as? MediaRenderView, let remoteView = mediaSession.getRenderView(with: .remoteVideo) as? MediaRenderView {
            return (local:localView, remote:remoteView)
        }
        return nil
    }
    
    var screenShareView: MediaRenderView? {
        return mediaSession.getRenderView(with: .remoteScreenShare) as? MediaRenderView
    }
    
    // MARK: - Audio & Video
    var audioMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .localAudio)
        }
        set {
            newValue ? mediaSession.muteMedia(.localAudio) : mediaSession.unmuteMedia(.localAudio)
        }
    }
    
    var audioOutputMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .remoteAudio)
        }
        set {
            newValue ? mediaSession.muteMedia(.remoteAudio) : mediaSession.unmuteMedia(.remoteAudio)
        }
    }
    
    var videoMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .localVideo)
        }
        set {
            newValue ? mediaSession.muteMedia(.localVideo) : mediaSession.unmuteMedia(.localVideo)
        }
    }
    
    var videoOutputMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .remoteVideo)
        }
        set {
            newValue ? mediaSession.muteMedia(.remoteVideo) : mediaSession.unmuteMedia(.remoteVideo)
        }
    }
    
    var remoteVideoMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromRemote: .remoteVideo)
        }
    }
    
    var screenShareMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .localScreenShare)
        }
        set {
            newValue ? mediaSession.muteMedia(.localScreenShare) : mediaSession.unmuteMedia(.localScreenShare)
        }
    }
    
    var screenShareOutputMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromLocal: .remoteScreenShare)
        }
        set {
            newValue ? mediaSession.muteMedia(.remoteScreenShare) : mediaSession.unmuteMedia(.remoteScreenShare)
        }
    }
    
    var remotescreenShareMuted: Bool {
        get {
            return mediaSession.getMediaMuted(fromRemote: .remoteScreenShare)
        }
    }
    
    var isPrepared: Bool {
        get {
            if self.status == .prepare || self.status == .running {
                return true
            }
            return false
        }
    }
    
    // MARK: - Camera
    func setFacingMode(mode: Phone.FacingMode) {
        mediaSession.setCamrea(mode == .user)
    }
    
    func isFrontCameraSelected() -> Bool {
        return mediaSession.isFrontCameraSelected()
    }
    
    // MARK: - Loud Speaker
    func setLoudSpeaker(speaker: Bool) {
        mediaSession.setSpeaker(speaker)
    }
        
    func isSpeakerSelected() -> Bool {
        return mediaSession.isSpeakerSelected()
    }
    
    func startPreview(view: MediaRenderView, phone: Phone) -> Bool {
        if self.status == .initial {
            self.status = .preview
            mediaSession.mediaConstraint = MediaConstraint(constraint: MediaConstraintFlag.audio.rawValue | MediaConstraintFlag.video.rawValue)
            mediaSession.addRenderView(view, type: .preview)
            mediaSession.createMediaConnection()
            mediaSession.setDefaultCamera(phone.defaultFacingMode == Phone.FacingMode.user)
            mediaSession.setCamrea(phone.defaultFacingMode == Phone.FacingMode.user)
            mediaSession.setDefaultAudioOutput(phone.defaultLoudSpeaker)
            mediaSession.startVideoRenderView(with: .preview)
            return true
        }
        return false;
    }
    
    func stopPreview() {
        if self.status == .preview {
            mediaSession.stopVideoRenderView(with: .preview, removeRender: true)
            mediaSession.removeAllRenderView(.preview)
            mediaSession.disconnectFromCloud()
            self.status = .initial
        }
    }
    
    // MARK: - lifecycle
    func prepare(option: MediaOption, phone: Phone) {
        if self.status == .preview {
            self.stopPreview()
        }
        if self.status == .initial {
            self.status = .prepare
            
            let mediaConfig :MediaCapabilityConfig = MediaCapabilityConfig()
            // mediaConfig.mqeCallback = false
            mediaConfig.audioMaxRxBandwidth = phone.audioMaxRxBandwidth
            
            var constraint = MediaConstraintFlag.audio.rawValue
            if option.hasVideo {
                mediaConfig.videoMaxRxBandwidth = phone.videoMaxRxBandwidth
                mediaConfig.videoMaxTxBandwidth = phone.videoMaxTxBandwidth
                constraint = constraint | MediaConstraintFlag.video.rawValue
            }
            if option.hasScreenShare {
                mediaConfig.sharingMaxRxBandwidth = phone.sharingMaxRxBandwidth
                constraint = constraint | MediaConstraintFlag.screenShare.rawValue
            }
            mediaSession.mediaConstraint = MediaConstraint(constraint: constraint, withCapability:mediaConfig)
            if option.hasVideo {
                mediaSession.addRenderView(option.localVideoView, type: .localVideo)
                mediaSession.addRenderView(option.remoteVideoView, type: .remoteVideo)
            }
            if option.hasScreenShare {
                mediaSession.addRenderView(option.screenShareView, type: .remoteScreenShare)
            }

            mediaSession.createMediaConnection()
            mediaSession.setDefaultCamera(phone.defaultFacingMode == Phone.FacingMode.user)
            mediaSession.setDefaultAudioOutput(phone.defaultLoudSpeaker)
            
            if let appGroupID = option.applicationGroupIdentifier, let _ = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
                self.broadcastServer = BroadcastConnectionServer(applicationGroupIdentifier: appGroupID, delegate: self)
            } else {
                SDKLogger.shared.error("Fail to create broadcast server: Illegal Application Group Identifier.")
            }
        }
    }
    
    func startMedia(call: Call) {
        if self.status == .prepare {
            self.status = .running
            mediaSessionObserver = MediaSessionObserver(call: call)
            mediaSessionObserver?.startObserving(mediaSession)
            mediaSession.connectToCloud()
            
            if call.model.myself?.device?.serverComposed ?? false {
                SDKLogger.shared.error("Set the remote video render mode to CropFill for composed video.")
                mediaSession.setRemoteVideoRenderMode(self._remoteVideoRenderMode.wmeMode)
            }
            
            self.broadcastServer?.start() {
                error in
                if error != nil {
                    SDKLogger.shared.error("Failure start broadcast server: \(error?.localizedDescription ?? "").")
                }
            }
        }
    }
    
    func stopMedia() {
        mediaSessionObserver?.stopObserving()
        mediaSession.disconnectFromCloud()
        self.status = .initial
        self.stopBroadcasting()
        self.broadcastServer?.invalidate()
    }
    
    func updateMedia(mediaType:MediaType) {
        guard self.status != .preview || self.status != .initial else {
            return
        }
        switch mediaType {
        case .video(let renderViews):
            mediaSession.updateSdpDirection(withLocalView: renderViews?.local, remoteView: renderViews?.remote)
            break
        case .screenShare(let renderView):
            mediaSession.updateSdpDirection(withScreenShare: renderView)
            break
        }
    }
    
    func restartAudio() {
        mediaSession.stopAudio()
        mediaSession.startAudio()
    }
    
    func joinScreenShare(_ shareId: String, isSending: Bool) {
        if mediaSession.mediaConstraint.hasScreenShare {
            mediaSession.joinScreenShare(shareId, isSending: isSending)
        }
    }
    
    func leaveScreenShare(_ shareId: String, isSending: Bool) {
        if mediaSession.mediaConstraint.hasScreenShare {
            mediaSession.leaveScreenShare(shareId, isSending: isSending)
        }
    }
    
    func startLocalScreenShare() {
        if mediaSession.mediaConstraint.hasScreenShare {
            self.isSharingScreen = true
            mediaSession.startLocalScreenShare()
        }
    }
    
    func stopLocalScreenShare() {
        if mediaSession.mediaConstraint.hasScreenShare {
            stopBroadcasting()
            mediaSession.stopLocalScreenShare()
        }
    }
    
    func onReceiveScreenBroadcastMessage(frameInfo:FrameInfo, frameData :Data) {
        if mediaSession.mediaConstraint.hasScreenShare {
            mediaSession.onReceiveScreenBroadcastData(frameInfo, frameData: frameData)
        }
    }
    
    func stopBroadcasting() {
        guard let connectionServer = self.broadcastServer else {
            return
        }
        
        var feedbackMessage = FeedbackMessage(error: .stop)
        let data = Data(bytes: &feedbackMessage, count: MemoryLayout<FeedbackMessage>.size)
        connectionServer.broadcastMessage(data) { error in
            SDKLogger.shared.info("Notify broadcast extension to stop live broadcasting. Error: \(String(describing: error))")
        }
        self.isSharingScreen = false
        self.onBroadcasting?(false)
    }
}

extension MediaSessionWrapper : BroadcastConnectionServerDelegate {
    public func shouldAcceptNewConnection() -> Bool {
        SDKLogger.shared.info("Accept new broadcast client connection?: \(isSharingScreen)")
        if isSharingScreen || self.status == .running {
            self.onBroadcasting?(true)
            return true
        }
        return false
    }

    public func didReceivedFrame(_ frame: FrameInfo, frameData: Data!) {
        if self.isSharingScreen {
            self.onReceiveScreenBroadcastMessage(frameInfo: frame, frameData: frameData)
        }
    }

    public func didReceivedError(_ error: ScreenShareError) {
        SDKLogger.shared.info("Received broadcast client error message: \(error)")
        self.onBroadcastError?(error)
    }
}

extension MediaSessionWrapper {
    func getMediaSession() -> MediaSession {
        return self.mediaSession
    }
    
    func setMediaSession(mediaSession:MediaSession) {
        self.mediaSession = mediaSession
    }
}

extension MediaSessionWrapper {
    func subscribeAuxStream(view: MediaRenderView) -> Int {
        return Int(self.mediaSession.subscribeVideoTrack(view))
    }
    
    func unsubscribeAuxStream(vid:Int) {
        self.mediaSession.unsubscribeVideoTrack(Int32(vid))
    }
    
    func addAuxStreamRenderView(view:MediaRenderView, vid:Int) {
        self.mediaSession.addRenderView(view, type: .auxVideo, andVid: Int32(vid))
    }
    
    func removeAuxStreamRenderView(view:MediaRenderView, vid:Int) {
        self.mediaSession.removeRenderView(view, type: .auxVideo, andVid: Int32(vid))
    }
    
    func updateAuxStreamRenderView(view:MediaRenderView, vid:Int) {
        self.mediaSession.updateRenderView(view, type: .auxVideo, andVid: Int32(vid))
    }
    
    func getAuxStreamRenderViewSize(vid:Int) -> CGSize {
        return self.mediaSession.getRenderViewSize(with: .auxVideo, andVid: Int32(vid))
    }
    
    func getAuxStreamInputMuted(vid:Int) -> Bool {
        return self.mediaSession.getMediaMuted(fromLocal: .auxVideo, andVid: Int32(vid))
    }
    
    func getAuxStreamOutputMuted(vid:Int) -> Bool {
        return self.mediaSession.getMediaMuted(fromRemote: .auxVideo, andVid: Int32(vid))
    }
    
    func muteAuxStream(vid:Int) {
        self.mediaSession.muteMedia(.auxVideo, andVid: Int32(vid))
    }
    
    func unmuteAuxStream(vid:Int) {
        self.mediaSession.unmuteMedia(.auxVideo, andVid: Int32(vid))
    }
    
    func auxStreamCount() -> Int {
        return self.mediaSession.auxStreamCount
    }
    
    var MQEReport: String? {
        return self.mediaSession.getEventReport()
    }
}

extension MediaSessionWrapper {

    private func adjustRemoteRenderViewSize() {
        guard let remoteView = mediaSession.getRenderView(with: .remoteVideo) else {
            return
        }

        if let constraint = remoteView.getSizeConstraint() {
            constraint.constant += 0.5
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                constraint.constant -= 0.5
            }
            SDKLogger.shared.debug("adjust constraint = \(constraint.firstAttribute.rawValue)")
        }
        else {
            let frame = remoteView.frame
            let width = frame.width
            var height = frame.height
            height += 0.5
            remoteView.frame = CGRect(origin: frame.origin, size: CGSize(width: width, height: height))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                height -= 0.5
                remoteView.frame = CGRect(origin: frame.origin, size: CGSize(width: width, height: height))
            }
            SDKLogger.shared.debug("adjust frame = \(remoteView.frame)")
        }
    }

}

extension Call.VideoRenderMode {
    
    var wmeMode: VideoScalingModeType {
        get {
            switch self {
            case .fit:
                return VideoScalingModeType.fit
            case .cropFill:
                return VideoScalingModeType.cropFill
            case .stretchFill:
                return VideoScalingModeType.stretchFill
            }
        }
    }
    
}

extension UIView {
    func getSizeConstraint() -> NSLayoutConstraint? {
        for constraint in self.constraints {
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                return constraint
            }
        }

        let includeSizeChangedAttribute: (NSLayoutConstraint.Attribute) -> Bool = { attribute in
            switch attribute {
            case .width, .height, .leading, .left, .top, .bottom, .right, .trailing, .leftMargin, .rightMargin, .topMargin, .bottomMargin, .leadingMargin, .trailingMargin:
                return true
            default:
                return false
            }
        }

        var _superview = self.superview
        while let superview = _superview {
            for constraint in superview.constraints {

                if let first = constraint.firstItem as? UIView, first == self, includeSizeChangedAttribute(constraint.firstAttribute) {
                    return constraint
                }

                if let second = constraint.secondItem as? UIView, second == self, includeSizeChangedAttribute(constraint.secondAttribute) {
                    return constraint
                }
            }
            _superview = superview.superview
        }

        return nil
    }

}
