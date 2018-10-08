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

public let MAX_REMOTE_AUX_VIDEO_NUMBER = 4

public class RemoteAuxVideo {
    static let INVAILD_VID = -1
    
    enum RenderViewOperationType {
        case add(Int,MediaRenderView)
        case remove(Int,MediaRenderView)
        case update(Int,MediaRenderView)
        case getSize(Int)
        case getMuted(Int)
        case getRemoteMuted(Int)
        case mute(Int,Bool)
    }
    
    /// The direction of this *call*.
    ///
    /// - since: 1.2.0
    var vid: Int
    
    public private(set) var renderViews:Array<MediaRenderView>
    
    public internal(set) var person: CallMembership?
    
    var renderViewOperationHandler:((RenderViewOperationType) -> Any?)?
    
    public var isSendingVideo: Bool {
        get {
            if let sendingMuted = renderViewOperationHandler?(RenderViewOperationType.getRemoteMuted(vid)) as? Bool {
                return !sendingMuted
            }
            return true;
        }
    }
    
    public var remoteAuxVideoSize: CMVideoDimensions {
        get {
            if let size = renderViewOperationHandler?(RenderViewOperationType.getSize(vid)) as? CGSize {
                return CMVideoDimensions(width: Int32(size.width), height: Int32(size.height))
            }
            return CMVideoDimensions(width: 0, height: 0)
        }
    }
    
    public var isReceivingVideo:Bool {
        get {
            if let receivingMuted = renderViewOperationHandler?(RenderViewOperationType.getMuted(vid)) as? Bool {
                return !receivingMuted
            }
            return true;
        }
        set {
            if vid != RemoteAuxVideo.INVAILD_VID, let handler = self.renderViewOperationHandler {
                _ = handler(RenderViewOperationType.mute(vid,!newValue))
            }
        }
    }
    
    init(vid: Int, renderViews: Array<MediaRenderView>, renderViewOperation: @escaping ((RenderViewOperationType) -> Any?)) {
        self.vid = vid
        self.renderViews = renderViews
        self.renderViewOperationHandler = renderViewOperation
    }
    
    public func addRenderView(view:MediaRenderView) {
        if vid != RemoteAuxVideo.INVAILD_VID, let handler = self.renderViewOperationHandler {
            _ = handler(RenderViewOperationType.add(vid,view))
        }
        self.renderViews.append(view)
    }
    
    public func removeRenderView(view:MediaRenderView) {
        if vid != RemoteAuxVideo.INVAILD_VID, let handler = self.renderViewOperationHandler {
            _ = handler(RenderViewOperationType.remove(vid,view))
        }
        
        if let index = renderViews.index(where: {$0 == view}) {
            renderViews.remove(at: index)
        }
    }
    
    public func updateRenderView(view:MediaRenderView) {
        if vid != RemoteAuxVideo.INVAILD_VID, let handler = self.renderViewOperationHandler {
            _ = handler(RenderViewOperationType.update(vid,view))
        }
    }
    
    public func containRenderView(view:MediaRenderView) -> Bool{
        return self.renderViews.contains(view)
    }
    
    func invalidate() {
        self.vid = RemoteAuxVideo.INVAILD_VID
        self.renderViewOperationHandler = nil
        self.person = nil
        self.renderViews.removeAll()
    }
}
