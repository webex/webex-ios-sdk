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

/// A data type represents a relationship between `Call` and `Person` at Cisco Webex cloud.
///
/// - since: 1.2.0
public struct CallMembership {

    /// The enumeration of the status of the person in the membership.
    ///
    /// - since: 1.2.0
    public enum State : String {
        /// The person is idle w/o any call.
        case idle
        /// The person has been notified about the call.
        case notified
        /// The person has joined the call.
        case joined
        /// The person has left the call.
        case left
        /// The person has declined the call.
        case declined
        /// The person is waiting in the lobby about the call.
        /// - since: 2.4.0
        case waiting
        
        static func from(participant: ParticipantModel) -> CallMembership.State {
            guard let state = participant.state else {
                return .idle
            }
            if participant.isInLobby {
                return .waiting
            }
            return State(rawValue: state.rawValue) ?? .idle
        }
    }
        
    /// True if the person is the initiator of the call.
    ///
    /// - since: 1.2.0
    public private(set) var isInitiator: Bool
    
    /// The identifier of the person.
    ///
    /// - since: 1.2.0
    public private(set) var personId: String?
    
    /// The status of the person in this `CallMembership`.
    ///
    /// - since: 1.2.0
    public var state: State {
        return State.from(participant: self.model)
    }
    
    /// The email address of the person in this `CallMembership`.
    ///
    /// - since: 1.2.0
    public var email: String? {
        return self.model.person?.email
    }
    
    /// The SIP address of the person in this `CallMembership`.
    ///
    /// - since: 1.2.0
    public var sipUrl: String? {
        return self.model.person?.sipUrl
    }
    
    /// The phone number of the person in this `CallMembership`.
    ///
    /// - since: 1.2.0
    public var phoneNumber: String? {
        return self.model.person?.phoneNumber
    }
    
    /// True if the `CallMembership` is sending video. Otherwise, false.
    ///
    /// - since: 1.3.0
    public var sendingVideo: Bool {
        return self.model.status?.videoStatus == "SENDRECV"
    }
    
    /// True if the `CallMembership` is sending audio. Otherwise, false.
    ///
    /// - since: 1.3.0
    public var sendingAudio: Bool {
        return self.model.status?.audioStatus == "SENDRECV"
    }
    
    /// True if the `CallMembership` is sending screen share. Otherwise, false.
    ///
    /// - since: 1.3.0
    public var sendingScreenShare: Bool {
        return self.call.model.isGrantedScreenShare
            && self.call.model.screenShareMediaFloor?.beneficiary?.id == self.id
            && self.call.model.screenShareMediaFloor?.disposition == MediaShareModel.ShareFloorDisposition.granted
    }
    
    /// True if this `CallMembership` is speaking in this meeting and video is prsenting on remote media render view. Otherwise, false.
    ///
    /// - since: 2.0.0
    public var isActiveSpeaker: Bool {
        return (self.call.activeSpeaker?.id == self.id) 
    }
    
    let id: String
    
    public let isSelf: Bool
    
    var model: ParticipantModel {
        get {
            self.call.lock()
            defer { self.call.unlock() }
            return participantModel
        }
        set {
            self.call.lock()
            defer { self.call.unlock() }
            participantModel = newValue
        }
    }
    
    private let call: Call
    
    private var participantModel: ParticipantModel

    /// Constructs a new `CallMembership`.
    ///
    /// - since: 1.2.0
    init(participant: ParticipantModel, call: Call) {
        self.id = participant.id ?? ""
        self.call = call
        self.isSelf = participant.id == call.model.myselfId
        self.isInitiator = participant.isCreator ?? false
        if let personId = participant.person?.id {
            self.personId = "ciscospark://us/PEOPLE/\(personId)".base64Encoded()
        }
        self.participantModel = participant
    }
    
    func containCSI(csi:UInt) -> Bool {
        return model.status?.csis?.contains(csi) ?? false
    }
    
    func isMediaActive() -> Bool {
        return model.state == ParticipantModel.State.joined
    }
}
