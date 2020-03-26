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

/// Multi stream change event enumeration.
///
/// - since: 2.0.0
public enum AuxStreamChangeEvent {
    /// Triggered when an auxiliary stream is opened.
    case auxStreamOpenedEvent(MediaRenderView,Result<AuxStream>)
    /// Triggered when this auxiliary stream's speaker has changed.
    case auxStreamPersonChangedEvent(AuxStream,From:CallMembership?,To:CallMembership?)
    /// Triggered Auxiliary stream's render view size changed.
    case auxStreamSizeChangedEvent(AuxStream)
    /// True if the auxiliary stream is sending video. Otherwise false.
    /// Might be triggered when the auxiliary stream video is muted or unmuted.
    case auxStreamSendingVideoEvent(AuxStream)
    /// Triggered when an auxiliary stream is closed.
    case auxStreamClosedEvent(MediaRenderView,Error?)
}

/// Multi stream protocol. Required to implement for using multi stream feature.
/// - see: see Call.multiStreamObserver to set the multi stream's events observer in this call.
/// - since: 2.0.0
public protocol MultiStreamObserver : class {
    
    /// Callback when current call have a new auxiliary stream.
    /// Return a MediaRenderView. SDK will open it automatically.
    /// Return nil if not need to open at once. Call API:call.openAuxStream(view: MediaRenderView) to open stream later.
    /// The auxStreamOpenedEvent would be triggered for indicating whether the stream is successfully opened.
    /// - since: 2.0.0
    var onAuxStreamAvailable: (()-> MediaRenderView?)? { get set }
    
    /// Callback of auxiliary stream related change events.
    /// - see: see AuxStreamChangeEvent
    /// - since: 2.0.0
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)? { get set }
    
    /// Callback when an existing auxiliary stream is unavailable.
    /// Should give SDK a MediaRenderView which need be closed, if give nil SDK will automatically close the last opened stream.
    /// The auxStreamClosedEvent would be triggered for indicating whether the stream is successfully closed.
    /// - since: 2.0.0
    var onAuxStreamUnavailable: (() -> MediaRenderView?)? { get set }
}
