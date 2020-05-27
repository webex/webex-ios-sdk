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

enum ClientEventName: String {
     case callInitiated = "client.call.initiated"
     case mediaEngineLocalSdpGenerated = "client.media-engine.local-sdp-generated"
     case locusJoinRequest = "client.locus.join.request"
     case locusJoinResponse = "client.locus.join.response"
     case locusMediaRequest =  "client.locus.media.request"
     case locusMediaResponse = "client.locus.media.response"
     case mediaEngineReady =  "client.media-engine.ready"
     case mediaEngineRemoteSdpReceived = "client.media-engine.remote-sdp-received"
     case notificationReceived = "client.notification.received"
     case callDisplayed = "client.call.displayed"
     case alertDisplayed = "client.alert.displayed"
     case alertRemoved = "client.alert.removed"
     case iceStart = "client.ice.start"
     case iceEnd = "client.ice.end"
     case mediaReceiveStart = "client.media.rx.start"
     case mediaReceiveStop = "client.media.rx.stop"
     case mediaTransmitStart = "client.media.tx.start"
     case mediaTransmitStop = "client.media.tx.stop"
     case mediaRenderStart = "client.media.render.start"
     case mediaRenderStop = "client.media.render.stop"
     case mediaCapabilities = "client.media.capabilities"
     case networkChanged = "client.network.changed"
     case pinPrompt = "client.pin.prompt"
     case pinCollected = "client.pin.collected"
     case lobbyEntered = "client.lobby.entered"
     case lobbyExited = "client.lobby.exited"
     case muted = "client.muted"
     case unmuted = "client.unmuted"
     case callLeave = "client.call.leave"
     case callRemoteEnded = "client.call.remote-ended"
     case callRemoteStarted = "client.call.remote-started"
     case shareFloorGrantedLocal = "client.share.floor-granted.local"
     case shareInitiated = "client.share.initiated"
     case shareStopped = "client.share.stopped"
     case mediaShareCsiChanged = "client.media.share.csi.changed"
     case callAborted = "client.call.aborted"
     case mediaReconnecting = "client.media.reconnecting"
     case mediaRecovered = "client.media.recovered"
     case callJoinWithNoLocusRequest = "client.call.skip-locus-join"
     case enteringBackground = "client.entering-background"
     case enteringForeground = "client.entering-foreground"
     case pstnAudioAttemptStart = "client.pstnaudio.attempt.start"
     case pstnAudioAttemptSkip = "client.pstnaudio.attempt.skip"
     case pstnAudioAttemptFinish = "client.pstnaudio.attempt.finish"
     case mediaQuality = "client.mediaquality.event"
     case mercuryConnectionLost = "client.mercury.connection.lost"
     case mercuryConnectionRestored = "client.mercury.connection.restored"
     case startedFromCrash = "client.started-from-crash"
 }
