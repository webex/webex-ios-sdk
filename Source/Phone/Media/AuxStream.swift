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

public let MAX_AUX_STREAM_NUMBER = 4

public class AuxStream {
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
    /// - since: 2.0
    public private(set) var renderView:MediaRenderView?
    
    public internal(set) var person: CallMembership?
    
    public var isSendingVideo: Bool {
        get {
            if let sendingMuted = renderViewOperationHandler?(RenderViewOperationType.getRemoteMuted(vid)) as? Bool {
                return !sendingMuted
            }
            return true;
        }
    }
    
    public var auxStreamSize: CMVideoDimensions {
        get {
            if let size = renderViewOperationHandler?(RenderViewOperationType.getSize(vid)) as? CGSize {
                return CMVideoDimensions(width: Int32(size.width), height: Int32(size.height))
            }
            return CMVideoDimensions(width: 0, height: 0)
        }
    }
    
    var vid: Int
    var renderViewOperationHandler:((RenderViewOperationType) -> Any?)?
    var isReceivingVideo:Bool {
        get {
            if let receivingMuted = renderViewOperationHandler?(RenderViewOperationType.getMuted(vid)) as? Bool {
                return !receivingMuted
            }
            return true;
        }
        set {
            if vid != AuxStream.INVAILD_VID, let handler = self.renderViewOperationHandler {
                _ = handler(RenderViewOperationType.mute(vid,!newValue))
            }
        }
    }
    
    private weak var call:Call?
    
    init(vid: Int, renderView:MediaRenderView, renderViewOperation: @escaping ((RenderViewOperationType) -> Any?), call:Call) {
        self.vid = vid
        self.renderView = renderView
        self.renderViewOperationHandler = renderViewOperation
        self.call = call
    }
    
    public func close() {
        if let retainCall = self.call, let view = self.renderView {
            retainCall.closeAuxStream(view: view)
        }
    }
    
    func invalidate() {
        self.vid = AuxStream.INVAILD_VID
        self.renderViewOperationHandler = nil
        self.person = nil
        self.renderView = nil
        self.call = nil
    }
}
