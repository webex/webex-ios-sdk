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
@testable import WebexSDK

class FakeWME: MediaSession  {
    static func stubMediaChangeNotification(eventType:Call.MediaChangedEvent,call:Call) {
        DispatchQueue.main.async {
            switch eventType {
            case .sendingVideo(let isSending):
                if isSending {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidUnMuteVideo, object: call.mediaSession.getMediaSession())
                }
                else {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidMuteVideo, object: call.mediaSession.getMediaSession())
                }
                break
            case .remoteAuxVideosCount(let count):
                NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidAvailableMediaChange, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoCount:count])
                break
            default:
                break
            }
        }
        
    }
    
    static func stubActiveSpeakerChangeNotification(csi:[UInt],call:Call) {
        DispatchQueue.main.async {
            var csiNumber:[NSNumber] = Array<NSNumber>()
            for onecsi in csi {
                csiNumber.append(NSNumber.init(value: onecsi))
            }
            
            NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidActiveSpeakerChange, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoCSI:csiNumber])
        }
    }
    
    static func stubRemoteAuxVideoEvent(eventType:Call.RemoteAuxVideoChangeEvent,call:Call,csi:[UInt]? = nil) {
        DispatchQueue.main.async {
            var csiNumber:[NSNumber] = Array<NSNumber>()
            if let csiArray = csi {
                for onecsi in csiArray {
                    csiNumber.append(NSNumber.init(value: onecsi))
                }
            }
            switch eventType {
            case .remoteAuxVideoPersonChangedEvent(let remoteAuxVideo):
                NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidCSIChange, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoCSI:csiNumber,MediaEngineVideoID:remoteAuxVideo.vid])
                break
            case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                if remoteAuxVideo.isSendingVideo {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidDetectAuxVideoMediaAvailable, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoID:remoteAuxVideo.vid])
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidDetectAuxVideoMediaUnavailable, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoID:remoteAuxVideo.vid])
                }
                
                break
            case .receivingAuxVideoEvent(let remoteAuxVideo):
                if remoteAuxVideo.isReceivingVideo {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidMuteAuxVideo, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoID:remoteAuxVideo.vid])
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidUnMuteAuxVideo, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoID:remoteAuxVideo.vid])
                }
            case .remoteAuxVideoSizeChangedEvent(let remoteAuxVideo):
                NotificationCenter.default.post(name: NSNotification.Name.MediaEngineDidAuxVideoSizeChange, object: call.mediaSession.getMediaSession(), userInfo: [MediaEngineVideoID:remoteAuxVideo.vid])
                break
            default:
                break
            }
            
        }
    }
    
    
    var stubSubscribeFailed :Bool = false
    var stubRemoteAuxMuted :Bool?
    var stubLocalAuxMuted :Bool?
    var stubAuxSize :CGSize?
    
    override func createMediaConnection() {
        super.createMediaConnection()
    }
    
    override func connectToCloud() {
        
    }
    
    override func disconnectFromCloud() {
        
    }
    
    override func subscribeVideoTrack(_ renderView: UIView!) -> Int32 {
        if stubSubscribeFailed {
            return Int32(RemoteAuxVideo.INVAILD_VID)
        }
        else {
            return super.subscribeVideoTrack(renderView)
        }
    }

    override func getMediaMuted(fromRemote type: MediaSessionType, andVid vid: Int32) -> Bool {
        switch type {
        case .auxVideo:
            if stubRemoteAuxMuted != nil {
                return stubRemoteAuxMuted!
            }
            return super.getMediaMuted(fromRemote: type, andVid: vid)
        default:
            return super.getMediaMuted(fromRemote: type, andVid: vid)
        }
    }
    
    override func getMediaMuted(fromLocal type: MediaSessionType, andVid vid: Int32) -> Bool {
        switch type {
        case .auxVideo:
            if stubLocalAuxMuted != nil {
                return stubLocalAuxMuted!
            }
            return super.getMediaMuted(fromLocal: type, andVid: vid)
        default:
            return super.getMediaMuted(fromLocal: type, andVid: vid)
        }
    }
    
    override func getRenderViewSize(with type: MediaSessionType, andVid vid: Int32) -> CGSize {
        switch type {
        case .auxVideo:
            if stubAuxSize != nil {
                return stubAuxSize!
            } else {
                return super.getRenderViewSize(with: type, andVid: vid)
            }
        default:
            return super.getRenderViewSize(with: type, andVid: vid)
        }
    }
}
