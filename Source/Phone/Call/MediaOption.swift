// Copyright 2016-2021 Cisco Systems Inc
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

/// A data type represents the media options of a `Call`.
///
/// - since: 1.2.0
public struct MediaOption {
    
    /// The video layout for the active speaker and other attendees in the group video meeting.
    ///
    /// - since: 2.5.0
    public enum CompositedVideoLayout {
        case single
        case filmstrip
        case grid
        
        var type: String {
            switch self {
            case .single:
                return "Single"
            case .grid:
                return "Equal"
            default:
                return "ActivePresence"
            }
        }
    }
    
    /// Constructs an audio only media option.
    ///
    /// - since: 1.2.0
    public static func audioOnly() -> MediaOption {
        return MediaOption()
    }
    
    /// Constructs an audio and video media option with video render views.
    ///
    /// - since: 1.2.0
    public static func audioVideo(local: MediaRenderView, remote: MediaRenderView) -> MediaOption {
        return MediaOption(local: local, remote: remote, hasVideo: true)
    }
    
    /// Constructs an audio and video media option with optional render views.
    /// The render views can be set after call is connected.
    ///
    /// - since: 1.3.0
    public static func audioVideo(renderViews: (local:MediaRenderView,remote:MediaRenderView)? = nil) -> MediaOption {
        return MediaOption(local: renderViews?.local, remote: renderViews?.remote, hasVideo: true)
    }
    
    /// Constructs an audio, video, and screen share media option with optional render views.
    /// The render views can be set after call is connected.
    ///
    /// - since: 1.3.0
    public static func audioVideoScreenShare(video: (local:MediaRenderView,remote:MediaRenderView)? = nil, screenShare: MediaRenderView? = nil) -> MediaOption {
        return MediaOption(local: video?.local, remote: video?.remote, screenShare: screenShare, hasVideo: true, hasScreenShare: true)
    }
    
    /// Constructs an audio, video,receive and send screen share media option with optional render views.
    /// The render views can be set after call is connected.
    ///
    /// - since: 1.4.0
    @available(iOS 11.2, *)
    public static func audioVideoScreenShare(video: (local:MediaRenderView,remote:MediaRenderView)? = nil, screenShare: MediaRenderView? = nil, applicationGroupIdentifier: String) -> MediaOption {
        return MediaOption(local: video?.local, remote: video?.remote, screenShare: screenShare, hasVideo: true, hasScreenShare: true, applicationGroupIdentifier: applicationGroupIdentifier)
    }
    
    var localVideoView: MediaRenderView?
    var remoteVideoView: MediaRenderView?
    var screenShareView: MediaRenderView?
    fileprivate var _uuid: UUID?
    let hasVideo: Bool
    let hasScreenShare: Bool
    let applicationGroupIdentifier:String?
    
    /// The video layout for the active speaker and other attendees in the group video meeting.
    ///
    /// - note: `layout` is deprecated. Use `compositedVideoLayout` instead, they do the same thing, just changed the naming
    /// - since: 2.5.0
    @available(*, deprecated)
    public var layout: CompositedVideoLayout?
    
    /// The video layout for the active speaker and other attendees in the group video meeting.
    ///
    /// - note: the layout just affects under `composited` videoStreamMode.
    /// - since: 2.8.0
    public var compositedVideoLayout: CompositedVideoLayout?

    /// Join the meeting as a moderator.
    ///
    /// - since: 2.6.0
    public var moderator: Bool = false

    /// If join as moderator, PIN should be a host key, else PIN should be a meeting password.
    /// In general, The PIN is not required. unless the WebexError.requireHostPinOrMeetingPassword error be received when dial.
    ///
    /// - since: 2.6.0
    public var pin: String?
    
    init() {
        self.hasVideo = false
        self.hasScreenShare = false
        self.applicationGroupIdentifier = nil
    }
    
    init(local: MediaRenderView? = nil, remote: MediaRenderView? = nil ,screenShare: MediaRenderView? = nil, hasVideo: Bool = false, hasScreenShare: Bool = false, applicationGroupIdentifier:String? = nil) {
        self.hasVideo = hasVideo
        self.hasScreenShare = hasScreenShare
        self.localVideoView = local
        self.remoteVideoView = remote
        self.screenShareView = screenShare
        self.applicationGroupIdentifier = applicationGroupIdentifier
    }
}

// CallKit
public extension MediaOption {
    
    /// A local unique identifier of a media options.
    ///
    /// - since: 1.2.0
    var uuid: UUID? {
        get {
            return self._uuid
        }
        set {
            self._uuid = newValue
        }
    }
    
}

