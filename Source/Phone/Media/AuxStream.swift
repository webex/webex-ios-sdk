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

let maxAuxStreamNumber = 4

public class AuxStream {
    enum RenderViewOperationType {
        case add(Int,MediaRenderView)
        case remove(Int,MediaRenderView)
        case update(Int,MediaRenderView)
        case getSize(Int)
        case getMuted(Int)
        case getRemoteMuted(Int)
        case mute(Int,Bool)
    }
    
    static let invalidVid = -1
    
    /// `AuxStream` render view.
    ///
    /// - since: 2.0.0
    public private(set) var renderView:MediaRenderView?
    
    /// Person presented in auxiliary stream.
    ///
    /// - since: 2.0.0
    public internal(set) var person: CallMembership?
    
    /// True if auxiliary stream is sending video. Otherwise, false.
    ///
    /// - since: 2.0.0
    public var isSendingVideo: Bool {
        get {
            if let sendingMuted = renderViewOperationHandler?(RenderViewOperationType.getRemoteMuted(vid)) as? Bool {
                return !sendingMuted
            }
            return true;
        }
    }
    
    /// The render view dimensions (points) of this `AuxStream`.
    ///
    /// - since: 2.0.0
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
    private weak var call:Call?
    
    /// Close auxiliary stream.
    /// Result will call back through auxStreamClosedEvent.
    /// - returns: Void
    /// - see: see AuxStreamChangeEvent.auxStreamClosedEvent
    /// - since: 2.0.0
    public func close() {
        if let retainCall = self.call, let view = self.renderView {
            retainCall.closeAuxStream(view: view)
        }
    }
    
    init(vid: Int, renderView:MediaRenderView, renderViewOperation: @escaping ((RenderViewOperationType) -> Any?), call:Call) {
        self.vid = vid
        self.renderView = renderView
        self.renderViewOperationHandler = renderViewOperation
        self.call = call
    }
    
    func invalidate() {
        self.vid = AuxStream.invalidVid
        self.renderViewOperationHandler = nil
        self.person = nil
        self.renderView = nil
        self.call = nil
    }
}
