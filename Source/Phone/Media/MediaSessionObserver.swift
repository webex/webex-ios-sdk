// Copyright 2016-2018 Cisco Systems Inc
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
import AVFoundation
import Wme

class MediaSessionObserver: NotificationObserver {
    
    //change retain to weak,it cause retain cycle(Call - MediaSessionWrapper - MediaSessionObserver)
    private weak var call: Call?
    
    init(call: Call) {
        self.call = call
    }
    
    override func notificationMapping() -> [(Notification.Name, Selector)] {
        return [
            (.MediaEngineDidSwitchCameras,         #selector(onMediaEngineDidSwitchCameras(_:))),
            (.MediaEngineDidChangeLocalViewSize,   #selector(onMediaEngineDidChangeLocalViewSize(_:))),
            (.MediaEngineDidChangeRemoteViewSize,  #selector(onMediaEngineDidChangeRemoteViewSize(_:))),
            (.MediaEngineDidChangeScreenShareViewSize,  #selector(onMediaEngineDidChangeScreenShareViewSize(_:))),
            (.MediaEngineDidChangeLocalScreenShareViewSize,  #selector(onMediaEngineDidChangeLocalScreenShareViewSize(_:))),
            (.MediaEngineDidMuteVideo,             #selector(onMediaEngineDidMuteVideo(_:))),
            (.MediaEngineDidUnMuteVideo,           #selector(onMediaEngineDidUnMuteVideo(_:))),
            (.MediaEngineDidMuteVideoOutput,       #selector(onMediaEngineDidMuteVideoOutput(_:))),
            (.MediaEngineDidUnMuteVideoOutput,     #selector(onMediaEngineDidUnMuteVideoOutput(_:))),
            (.MediaEngineDidMuteScreenShareOutput,     #selector(onMediaEngineDidMuteScreenShareOutput(_:))),
            (.MediaEngineDidUnMuteScreenShareOutput,     #selector(onMediaEngineDidUnMuteScreenShareOutput(_:))),
            (.MediaEngineDidMuteScreenShare, #selector(onMediaEngineDidMuteScreenShare(_:))),
            (.MediaEngineDidUnMuteScreenShare, #selector(onMediaEngineDidUnMuteScreenShare(_:))),
            (.MediaEngineDidMuteAudio,             #selector(onMediaEngineDidMuteAudio(_:))),
            (.MediaEngineDidUnMuteAudio,           #selector(onMediaEngineDidUnMuteAudio(_:))),
            (.MediaEngineDidMuteAudioOutput,       #selector(onMediaEngineDidMuteAudioOutput(_:))),
            (.MediaEngineDidUnMuteAudioOutput,     #selector(onMediaEngineDidUnMuteAudioOutput(_:))),
            (.MediaEngineDidChangeAudioRoute,      #selector(onMediaEngineDidChangeAudioRoute(_:))),
            (.MediaEngineDidDetectVideoMediaAvailable,      #selector(onMediaEngineDidDetectVideoMediaAvailable(_:))),
            (.MediaEngineDidDetectVideoMediaUnavailable,      #selector(onMediaEngineDidDetectVideoMediaUnavailable(_:))),
            (.MediaEngineDidDetectScreenShareMediaAvailable,      #selector(onMediaEngineDidDetectScreenShareMediaAvailable(_:))),
            (.MediaEngineDidDetectScreenShareMediaUnavailable,      #selector(onMediaEngineDidDetectScreenShareMediaUnavailable(_:))),
            (.MediaEngineDidAvailableMediaChange,      #selector(onMediaEngineDidAvailableMediaChange(_:))),
            (.MediaEngineDidDetectAuxVideoMediaUnavailable,      #selector(onMediaEngineDidDetectAuxVideoMediaUnavailable(_:))),
            (.MediaEngineDidDetectAuxVideoMediaAvailable,      #selector(onMediaEngineDidDetectAuxVideoMediaAvailable(_:))),
            (.MediaEngineDidMuteAuxVideo,#selector(onMediaEngineDidMuteAuxVideo(_:))),
            (.MediaEngineDidUnMuteAuxVideo,#selector(onMediaEngineDidUnMuteAuxVideo(_:))),
            (.MediaEngineDidActiveSpeakerChange,      #selector(onMediaEngineDidActiveSpeakerChange(_:))),
            (.MediaEngineDidCSIChange,      #selector(onMediaEngineDidDidCSIChange(_:))),
            (.MediaEngineDidAuxVideoSizeChange,      #selector(onMediaEngineDidAuxVideoSizeChange(_:)))]
        
    }
    
    @objc private func onMediaEngineDidSwitchCameras(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.cameraSwitched)
            }
        }
    }
    
    @objc private func onMediaEngineDidChangeAudioRoute(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.spearkerSwitched)
            }
        }
    }
    
    @objc private func onMediaEngineDidChangeLocalViewSize(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.localVideoViewSize)
            }
        }
    }
    
    @objc private func onMediaEngineDidChangeRemoteViewSize(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.remoteVideoViewSize)
            }
        }
    }
    
    @objc private func onMediaEngineDidChangeScreenShareViewSize(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.remoteScreenShareViewSize)
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteVideo(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.updateMedia(sendingAudio: retainCall.sendingAudio, sendingVideo: false)
                retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingVideo(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteVideo(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.updateMedia(sendingAudio: retainCall.sendingAudio, sendingVideo: true)
                retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingVideo(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteVideoOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingVideo(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteVideoOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingVideo(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteScreenShareOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingScreenShare(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteScreenShareOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingScreenShare(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteAudio(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.updateMedia(sendingAudio: false, sendingVideo: retainCall.sendingVideo)
                retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingAudio(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteAudio(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.updateMedia(sendingAudio: true, sendingVideo: retainCall.sendingVideo)
                retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingAudio(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteAudioOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingAudio(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteAudioOutput(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.receivingAudio(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteScreenShare(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingScreenShare(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteScreenShare(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                if retainCall.isScreenSharedBySelfDevice() {
                   retainCall.onMediaChanged?(Call.MediaChangedEvent.sendingScreenShare(true))
                }
            }
        }
    }
    
    @objc private func onMediaEngineDidChangeLocalScreenShareViewSize(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.localScreenShareViewSize)
            }
        }
    }
    
    @objc private func onMediaEngineDidAvailableMediaChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call ,let count = notification.userInfo?[MediaEngineVideoCount] as? Int {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.remoteAuxVideosCount(count))
            }
        }
    }
    
    @objc private func onMediaEngineDidAuxVideoSizeChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call ,let vid = notification.userInfo?[MediaEngineVideoID] as? Int, let auxVideo = retainCall.remoteAuxVideos.filter({$0.vid == vid}).first {
                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxVideoSizeChangedEvent(auxVideo))
            }
        }
    }
    
    @objc private func onMediaEngineDidDetectVideoMediaUnavailable(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.remoteSendingVideo(false))
            }
        }
    }
    
    @objc private func onMediaEngineDidDetectAuxVideoMediaUnavailable(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let vid = notification.userInfo?[MediaEngineVideoID] as? Int, let auxVideo = retainCall.remoteAuxVideos.filter({$0.vid == vid}).first{
                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(auxVideo))
            }
        }
    }
    
    @objc private func onMediaEngineDidDetectVideoMediaAvailable(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call {
                retainCall.onMediaChanged?(Call.MediaChangedEvent.remoteSendingVideo(true))
            }
        }
    }
    
    @objc private func onMediaEngineDidDetectScreenShareMediaUnavailable(_ notification: Notification) {

    }
    
    @objc private func onMediaEngineDidDetectScreenShareMediaAvailable(_ notification: Notification) {
        
    }
    
    @objc private func onMediaEngineDidDetectAuxVideoMediaAvailable(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let vid = notification.userInfo?[MediaEngineVideoID] as? Int, let auxVideo = retainCall.remoteAuxVideos.filter({$0.vid == vid}).first{
                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(auxVideo))
            }
        }
    }
    
    @objc private func onMediaEngineDidMuteAuxVideo(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let vid = notification.userInfo?[MediaEngineVideoID] as? Int, let auxVideo = retainCall.remoteAuxVideos.filter({$0.vid == vid}).first{
                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.receivingAuxVideoEvent(auxVideo))
            }
        }
    }
    
    @objc private func onMediaEngineDidUnMuteAuxVideo(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let vid = notification.userInfo?[MediaEngineVideoID] as? Int, let auxVideo = retainCall.remoteAuxVideos.filter({$0.vid == vid}).first{
                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.receivingAuxVideoEvent(auxVideo))
            }
        }
    }
    
    @objc private func onMediaEngineDidActiveSpeakerChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let csiArray = notification.userInfo?[MediaEngineVideoCSI] as? Array<NSNumber> {
                for number in csiArray {
                    if let membership = retainCall.memberships.filter({$0.containCSI(csi: number.uintValue)}).first {
                        retainCall.activeSpeaker = membership
                        retainCall.onMediaChanged?(Call.MediaChangedEvent.activeSpeakerChangedEvent(membership))
                        break
                    }
                }
            }
        }
    }
    
    @objc private func onMediaEngineDidDidCSIChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let retainCall = self.call, let csiArray = notification.userInfo?[MediaEngineVideoCSI] as? Array<NSNumber>, let vid = notification.userInfo?[MediaEngineVideoID] as? Int {
                if let auxVideo = retainCall.remoteAuxVideos.filter({ $0.vid == vid}).first {
                    if csiArray.count < 1 {
                        auxVideo.person = nil
                        retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxVideoEndEvent(auxVideo))
                        return
                    }
                    for number in csiArray {
                        if let membership = retainCall.memberships.filter({$0.containCSI(csi: number.uintValue)}).first {
                            if auxVideo.person == nil {
                                auxVideo.person = membership
                                retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxVideoStartEvent(auxVideo))
                            } else {
                                auxVideo.person = membership
                            }
                            retainCall.onRemoteAuxVideoChanged?(Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(auxVideo))
                            break
                        }
                    }
                }
            }
        }
    }
    
}
