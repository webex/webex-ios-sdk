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
import ObjectMapper

struct LocusMediaResponseModel: Mappable {

    private(set) var locus: LocusModel?
    private(set) var mediaConnections: [MediaConnectionModel]?

    init?(map: Map) {
    }

    mutating func mapping(map: Map) {
        locus <- map["locus"]
        mediaConnections <- map["mediaConnections"]
    }
}

struct LociResponseModel: Mappable {

    private(set) var loci: [LocusModel]?
    private(set) var remoteLocusClusterUrls: [String]?

    init?(map: Map) {
    }

    mutating func mapping(map: Map) {
        loci <- map["loci"]
        remoteLocusClusterUrls <- map["remoteLocusClusterUrls"]
    }
}

struct LocusModel: Mappable {

    var locusUrl: String? // Mandatory
    var conversationUrl: String?
    var participants: [ParticipantModel]?
    var myself: ParticipantModel?
    var host: LocusParticipantInfoModel?
    var fullState: FullStateModel?
    var sequence: SequenceModel? // Mandatory
    var baseSequence: SequenceModel? = nil
    var syncUrl: String? = nil
    var replaces: [ReplaceModel]?
    var mediaShares: [MediaShareModel]?
    var mediaConnections: [MediaConnectionModel]?
    var meetings: [MeetingModel]?
    var info: LocusInfoModel?

    init?(map: Map) { }

    mutating func mapping(map: Map) {
        locusUrl <- map["url"]
        conversationUrl <- map["conversationUrl"]
        participants <- map["participants"]
        myself <- map["self"]
        host <- map["host"]
        fullState <- map["fullState"]
        sequence <- map["sequence"]
        baseSequence <- map["baseSequence"]
        syncUrl <- map["syncUrl"]
        replaces <- map["replaces"]
        mediaShares <- map["mediaShares"]
        meetings <- map["meetings"]
        info <- map["info"]
    }
    
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
    
    var spaceUrl: String? {
        return self.conversationUrl ?? self.info?.conversationUrl
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
        return fullState?.type != "MEETING" || self.isOneOnOneMeeting
    }
    
    var isOneOnOneMeeting: Bool {
        return fullState?.type == "MEETING" && (self.info?.tags?.contains("ONE_ON_ONE_MEETING") ?? false)
    }

    var isIncomingCall: Bool {
        return (fullState?.state == "ACTIVE" && myself?.alertType?.action == "FULL") || ((fullState?.state == "INITIALIZING" || fullState?.state == "ACTIVE") && (self.meetings?.count ?? 0) > 0)
    }

    var isInactive: Bool {
        return fullState?.state == "INACTIVE"
    }
    
    var isActive: Bool {
        return fullState?.state == "ACTIVE"
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

    func applyDelta(base: LocusModel) -> LocusModel {
        var ret = base
        if let sequence = self.sequence {
            ret.sequence = sequence
        }
        if let syncUrl = self.syncUrl {
            ret.syncUrl = syncUrl
        }
        if let locusUrl = self.locusUrl {
            ret.locusUrl = locusUrl
        }
        if let myself = self.myself {
            ret.myself = myself
        }
        if let host = self.host {
            ret.host = host
        }
        if let fullState = self.fullState {
            ret.fullState = fullState
        }
        if let replaces = self.replaces {
            ret.replaces = replaces
        }
        if let mediaShares = self.mediaShares {
            ret.mediaShares = mediaShares
        }
        if let mediaConnections = self.mediaConnections {
            ret.mediaConnections = mediaConnections
        }
        if let newParticipants = self.participants {
            if var oldParticipants = ret.participants {
                for participant in newParticipants {
                    if let index = oldParticipants.firstIndex(where:{$0.id == participant.id}) {
                        if participant.isRemoved {
                            oldParticipants.remove(at: index)
                        }
                        else {
                            oldParticipants[index] = participant
                        }
                    }
                    else {
                        if !participant.isRemoved {
                            oldParticipants.append(participant)
                        }
                    }
                }
                ret.participants = oldParticipants
            }
            else {
                ret.participants = newParticipants
            }
        }
        return ret
    }
}


