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

/// The enumeration of multi stream change events.
///
/// - since: 2.0.0
public enum AuxStreamChangeEvent {
    /// This might be triggered when an auxiliary stream is opened successfully or unsuccessfully.
    case auxStreamOpenedEvent(MediaRenderView,Result<AuxStream>)
    /// This might be triggered when this auxiliary stream's speaker has changed.
    case auxStreamPersonChangedEvent(AuxStream,From:CallMembership?,To:CallMembership?)
    /// Auxiliary stream's rendering view size has changed.
    case auxStreamSizeChangedEvent(AuxStream)
    /// True if the auxiliary stream now is sending video. Otherwise false.
    /// This might be triggered when the auxiliary stream muted or unmuted the video.
    case auxStreamSendingVideoEvent(AuxStream)
    /// This might be triggered when an auxiliary stream is closed successfully or unsuccessfully.
    case auxStreamClosedEvent(MediaRenderView,Error?)
}

/// The protocol of multi stream. If a client wants to use multi stream feature,it must implement this protocol.
/// - see: see Call.multiStreamObserver to set the multi stream's events observer in this call.
/// - since: 2.0.0
public protocol MultiStreamObserver : class {
    
    /// Callback when current call have a new auxiliary stream.
    /// Return a MediaRenderView let the SDK open it automatically. Return nil if client doesn't want to use it or call the API:call.openAuxStream(view: MediaRenderView) open this stream later.
    /// The auxStreamOpenedEvent would be triggered indicating whether the stream is successfully opened.
    /// - since: 2.0.0
    var onAuxStreamAvailable: (()-> MediaRenderView?)? { get set }
    
    /// Callback of auxiliary stream related change events.
    /// - see: see AuxStreamChangeEvent
    /// - since: 2.0.0
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)? { get set }
    
    /// Callback when an existing auxiliary stream is unavailable.
    /// The Client should give SDK a MediaRenderView which will be closed, if return nil SDK will automatically close the last opened stream.
    /// The auxStreamClosedEvent would be triggered indicating whether the stream is successfully closed.
    /// - since: 2.0.0
    var onAuxStreamUnavailable: (() -> MediaRenderView?)? { get set }
}
