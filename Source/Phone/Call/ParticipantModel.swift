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

struct ParticipantModel {
    
    struct DeviceModel {
                
        struct IntentModel {
            
            enum IntentType: String {
                case none
                case join
                case leave
                case wait
                case dialog
                case unknown
            }
            
            var id: String?
            var type: IntentType?
            var associatedWith: String?
        }
        
        var url: String?
        var deviceType: String?
        var featureToggles: String?
        var mediaConnections: [MediaConnectionModel]?
        var state: String?
        var callLegId: String?
        var intent: IntentModel?
        var serverComposed: Bool?
    }
    
    struct StatusModel {
        var audioStatus: String?
        var videoStatus: String?
        var csis: [UInt]?
    }
    
    struct ControlsModel {
        
        struct AudioModel {
            var muted: Bool?
            var modifiedBy: String?
        }
        
        var audio: AudioModel?
    }
    
    enum State: String {
        case idle
        case notified
        case joined
        case left
        case declined
    }
    
    var isCreator: Bool?
    var id: String?
    var url: String?
    var state: ParticipantModel.State?
    var type: String?
    var person: LocusParticipantInfoModel?
    var status: ParticipantModel.StatusModel?
    var deviceUrl: String?
    var mediaBaseUrl: String?
    var guest: Bool?
    var alertHint: AlertHintModel?
    var alertType: AlertTypeModel?
    var enableDTMF: Bool?
    var devices: [ParticipantModel.DeviceModel]?
    var removed: Bool?
    var controls: ControlsModel?
    
    var isJoined: Bool {
        return self.state == .joined
    }
    
    var isDeclined: Bool {
        return self.state == .declined
    }
    
    var isLeft: Bool {
        return self.state == .left
    }
    
    var isIdle:Bool {
        return self.state == .idle
    }

    func isLefted(device url: URL) -> Bool{
        return isLeft || self.devices?.filter{ $0.url == url.absoluteString }.count == 0
    }
    
    func isJoined(by: URL) -> Bool {
        return isJoined && self[device: by]?.state == "JOINED"
    }
    
    func isDeclined(by: URL) -> Bool {
        return isDeclined && self.deviceUrl == by.absoluteString
    }
    
    var isCIUser: Bool {
        if let typeString = self.type, typeString == "USER" || typeString == "RESOURCE_ROOM" {
            return true
        }
        return false
    }
    
    var isInLobby: Bool {
        guard self.isIdle, let devices = self.devices else {
            return false
        }
        for device in devices {
            if device.intent?.type == ParticipantModel.DeviceModel.IntentModel.IntentType.wait {
                return true
            }
        }
        return false
    }

    var isRemoved: Bool {
        return self.removed ?? false
    }
    
    var isAudioMuted: Bool {
        return self.controls?.audio?.muted == true
    }
    
    var modifiedByUUID: String? {
        return self.controls?.audio?.modifiedBy
    }

    var device: ParticipantModel.DeviceModel? {
        if let deviceUrl = self.deviceUrl {
            return self.devices?.filter{ $0.url == deviceUrl }.first
        }
        return nil
    }
    
    subscript(device url: URL) -> ParticipantModel.DeviceModel? {
        return self.devices?.filter{ $0.url == url.absoluteString }.first
    }

}

struct LocusParticipantInfoModel {
    var id: String?
    var email: String?
    var name: String?
    var sipUrl: String?
    var phoneNumber: String?
    var orgId: String?
}

struct AlertHintModel {
    var action: String?
    var expiration: String?
}

struct AlertTypeModel {
    var action: String?
}


extension ParticipantModel: Mappable {
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        isCreator <- map["isCreator"]
        id <- map["id"]
        url <- map["url"]
        state <- (map["state"], ParticipantStateTransform())
        type <- map["type"]
        person <- map["person"]
        devices <- map["devices"]
        status <- map["status"]
        deviceUrl <- map["deviceUrl"]
        mediaBaseUrl <- map["mediaBaseUrl"]
        guest <- map["guest"]
        alertHint <- map["alertHint"]
        alertType <- map["alertType"]
        enableDTMF <- map["enableDTMF"]
        removed <- map["removed"]
        controls <- map["controls"]
    }
    
    class ParticipantStateTransform: TransformType {
        
        func transformFromJSON(_ value: Any?) -> ParticipantModel.State? {
            guard let state = value as? String else {
                return nil
            }
            return ParticipantModel.State(rawValue: state.lowercased())
        }
        
        func transformToJSON(_ value: ParticipantModel.State?) -> String? {
            guard let state = value else {
                return nil
            }
            return state.rawValue
        }
    }
    
}

extension ParticipantModel.DeviceModel: Mappable {
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        url <- map["url"]
        deviceType <- map["deviceType"]
        featureToggles <- map["featureToggles"]
        mediaConnections <- map["mediaConnections"]
        state <- map["state"]
        callLegId <- map["callLegId"]
        intent <- map["intent"]
        serverComposed <- map["serverComposed"]
    }
}

extension ParticipantModel.StatusModel: Mappable {
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        audioStatus <- map["audioStatus"]
        videoStatus <- map["videoStatus"]
        csis <- map["csis"]
    }
}

extension ParticipantModel.ControlsModel: Mappable {
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        audio <- map["audio"]
    }
}

extension ParticipantModel.DeviceModel.IntentModel: Mappable {
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        type <- (map["type"], DeviceIntentTransform())
        associatedWith <- map["associatedWith"]
    }
    
    class DeviceIntentTransform: TransformType {
        
        func transformFromJSON(_ value: Any?) -> ParticipantModel.DeviceModel.IntentModel.IntentType? {
            guard let type = value as? String else {
                return nil
            }
            return ParticipantModel.DeviceModel.IntentModel.IntentType(rawValue: type.lowercased()) ?? ParticipantModel.DeviceModel.IntentModel.IntentType.unknown
        }
        
        func transformToJSON(_ value: ParticipantModel.DeviceModel.IntentModel.IntentType?) -> String? {
            guard let type = value else {
                return nil
            }
            return type.rawValue
        }
    }
}

extension ParticipantModel.ControlsModel.AudioModel: Mappable {
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        muted <- map["muted"]
        modifiedBy <- map["meta.modifiedBy"]
    }
}

extension LocusParticipantInfoModel: Mappable {
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        email <- map["email"]
        name <- map["name"]
        sipUrl <- map["sipUrl"]
        phoneNumber <- map["phoneNumber"]
        orgId <- map["orgId"]
    }
}

extension AlertHintModel: Mappable {
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        action <- map["action"]
        expiration <- map["expiration"]
    }
}

extension AlertTypeModel: Mappable {
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        action <- map["action"]
    }
}
