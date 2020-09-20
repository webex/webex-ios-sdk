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
import ObjectMapper

struct CallEventModel {
    fileprivate(set) var id: String?
    fileprivate(set) var callUrl: String?
    fileprivate(set) var callModel: LocusModel?
    fileprivate(set) var type: String?
}

struct FullStateModel {
    fileprivate(set) var active: Bool?
    fileprivate(set) var count: Int?
    fileprivate(set) var locked: Bool?
    fileprivate(set) var lastActive: String?
    fileprivate(set) var state: String?
    fileprivate(set) var type: String?
}

struct ReplaceModel  {
    fileprivate(set) var locusUrl: String?
}

struct LocusMediaResponseModel {
    fileprivate(set) var locus: LocusModel?
    fileprivate(set) var mediaConnections: [MediaConnectionModel]?
}

struct LocusModel {
    fileprivate(set) var locusUrl: String? // Mandatory
    fileprivate(set) var participants: [ParticipantModel]?
    fileprivate(set) var myself: ParticipantModel?
    fileprivate(set) var host: LocusParticipantInfoModel?
    fileprivate(set) var fullState: FullStateModel?
    fileprivate(set) var sequence: SequenceModel? // Mandatory
    fileprivate(set) var baseSequence: SequenceModel? = nil
    fileprivate(set) var syncUrl: String? = nil
    fileprivate(set) var replaces: [ReplaceModel]?
    fileprivate(set) var mediaShares: [MediaShareModel]?
    fileprivate(set) var mediaConnections: [MediaConnectionModel]?
    
    subscript(participant id: String) -> ParticipantModel? {
        return self.participants?.filter({$0.id == id}).first
    }
    
    var isValid: Bool {
        if let _ = self.callUrl, let _ = self.myself, let _ = self.host {
            return true
        } else if !self.isFullDTO, let _ = self.callUrl {
            return true
        }
        return false
    }
    
    var callUrl: String? {
        return self.replaces?.first?.locusUrl ?? self.locusUrl
    }
    
    var locusId: String? {
        if let url = self.callUrl {
            return URL(string: url)?.lastPathComponent
        }
        return nil
    }
    
    var myselfId: String? {
        return self.myself?.id
    }
    
    var isOneOnOne: Bool {
        return fullState?.type != "MEETING"
    }
    
    var isIncomingCall: Bool {
        return fullState?.state == "ACTIVE" && myself?.alertType?.action == "FULL"
    }

    var isInActive: Bool {
        return fullState?.state == "INACTIVE"
    }
    
    var isRemoteVideoMuted: Bool {
        for participant in self.participants ?? [] where participant.id != myself?.id && participant.isJoined && participant.isCIUser {
            if participant.status?.videoStatus != "RECVONLY" && participant.status?.videoStatus != "INACTIVE" {
                return false
            }
        }
        return true
    }
    
    var isRemoteAudioMuted: Bool {
        for participant in self.participants ?? [] where participant.id != myself?.id && participant.isJoined && participant.isCIUser {
            if participant.status?.audioStatus != "RECVONLY" && participant.status?.audioStatus != "INACTIVE" {
                return false
            }
        }
        return true
    }
    
    var isLocalSupportDTMF: Bool {
        return self.myself?.enableDTMF ?? false
    }
    
    var isGrantedScreenShare: Bool {
        return self.screenMediaShare != nil && self.screenMediaShare?.shareFloor?.disposition == MediaShareModel.ShareFloorDisposition.granted
    }
    
    var screenMediaShare: MediaShareModel? {
        guard self.mediaShares != nil else {
            return nil
        }
        for mediaShare in self.mediaShares ?? [] where mediaShare.shareType == MediaShareModel.MediaShareType.screen && mediaShare.shareFloor?.granted != nil {
            return mediaShare
        }
        return nil
    }
    
    var screenShareMediaFloor : MediaShareModel.MediaShareFloor? {
        return self.screenMediaShare?.shareFloor
    }
    
    var mediaShareUrl : String? {
        guard self.mediaShares != nil else {
            return nil
        }
        
        for mediaShare in self.mediaShares ?? [] where mediaShare.shareType == MediaShareModel.MediaShareType.screen {
            return mediaShare.url
        }
        return nil
    }
    
    var isFullDTO : Bool {
        return self.baseSequence == nil
    }
}

extension CallEventModel: Mappable {
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        callUrl <- map["locusUrl"]
        callModel <- map["locus"]
        type <- map["eventType"]
    }
}

extension LocusModel: Mappable {
	init?(map: Map) { }
	
	mutating func mapping(map: Map) {
		locusUrl <- map["url"]
		participants <- map["participants"]
		myself <- map["self"]
		host <- map["host"]
		fullState <- map["fullState"]
		sequence <- map["sequence"]
        baseSequence <- map["baseSequence"]
        syncUrl <- map["syncUrl"]
        replaces <- map["replaces"]
        mediaShares <- map["mediaShares"]
	}
}

extension FullStateModel: Mappable {
    init?(map: Map){ }
    
    mutating func mapping(map: Map) {
        active <- map["active"]
        count <- map["count"]
        locked <- map["locked"]
        lastActive <- map["lastActive"]
        state <- map["state"]
        type <- map["type"]
    }
}

extension ReplaceModel: Mappable {
    init?(map: Map){}
    
    mutating func mapping(map: Map) {
        locusUrl <- map["locusUrl"]
    }
}

extension LocusMediaResponseModel: Mappable {
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        locus <- map["locus"]
        mediaConnections <- map["mediaConnections"]
    }
}

extension LocusModel {
    mutating func setLocusUrl(newLocusUrl:String?) {
        self.locusUrl = newLocusUrl
    }
    
    mutating func setParticipants(newParticipants:[ParticipantModel]?) {
        self.participants = newParticipants
    }
    
    mutating func setMyself(newParticipant:ParticipantModel?) {
        self.myself = newParticipant
    }
    
    mutating func setHost(newPerson:LocusParticipantInfoModel?) {
        self.host = newPerson
    }
    
    mutating func setFullState(newFullState:FullStateModel?) {
        self.fullState = newFullState
    }
    
    mutating func setSequence(newSequence:SequenceModel?) {
        self.sequence = newSequence
    }
    
    mutating func setReplace(newReplaces:[ReplaceModel]?) {
        self.replaces = newReplaces
    }
    
    mutating func setMediaShares(newMediaShares:[MediaShareModel]?) {
        self.mediaShares = newMediaShares
    }
    
    mutating func setMediaConnections(newMediaConnections:[MediaConnectionModel]?) {
        self.mediaConnections = newMediaConnections
    }
    
    mutating func applyDelta(from: LocusModel) {
        self.sequence = from.sequence ?? self.sequence
        self.syncUrl = from.syncUrl ?? self.syncUrl
        self.locusUrl = from.locusUrl ?? self.locusUrl
        self.myself = from.myself ?? self.myself
        self.host = from.host ?? self.host
        self.fullState = from.fullState ?? self.fullState
        self.replaces = from.replaces ?? self.replaces
        self.mediaShares = from.mediaShares ?? self.mediaShares
        self.mediaConnections = from.mediaConnections ?? self.mediaConnections
        processParticipants(from: from.participants)
    }
    
    private mutating func processParticipants(from:[ParticipantModel]?) {
        if let newParticipants = from {
            guard var oldParticipants = self.participants else {
                self.participants = from
                return
            }
            
            for participant in newParticipants {
                if let index = oldParticipants.firstIndex(where:{$0.id == participant.id}) {
                    //replace
                    if (participant.removed ?? false) == false {
                        oldParticipants[index] = participant
                    } else { //remove
                        oldParticipants.remove(at: index)
                    }
                    
                } else if participant.removed ?? false == false {
                    // add
                    oldParticipants.append(participant)
                }
            }
            self.participants = oldParticipants
        }
    }
}

extension FullStateModel {
    mutating func setActive(newActive:Bool?) {
        self.active = newActive
    }
    
    mutating func setCount(newCount:Int?) {
        self.count = newCount
    }
    
    mutating func setLocked(newLocked:Bool?) {
        self.locked = newLocked
    }
    
    mutating func setLastActive(newLastActive:String?) {
        self.lastActive = newLastActive
    }
    
    mutating func setState(newState:String?) {
        self.state = newState
    }
    
    mutating func setType(newType:String?) {
        self.type = newType
    }
}
