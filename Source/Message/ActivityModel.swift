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

struct ActivityModel : Mappable {
    
    enum Verb: String {
        case post
        case share
        case delete
        case tombstone
        case acknowledge
        case updateKey
        case create
        case add
        case leave
        case update
        case hide
        case assignModerator
        case unassignModerator
        case schedule
        
        static func isSupported(_ verb: String) -> Bool {
            if verb == post.rawValue || verb == share.rawValue || verb == delete.rawValue
                || verb == add.rawValue || verb == leave.rawValue || verb == acknowledge.rawValue
                || verb == create.rawValue || verb == update.rawValue
                || verb == assignModerator.rawValue || verb == unassignModerator.rawValue
                || verb == schedule.rawValue {
                return true
            } else {
                return false
            }
        }
    }
    
    private(set) var uuid: String?
    private(set) var clientTempId: String?
    private(set) var verb: ActivityModel.Verb?
    private(set) var objectType: ObjectType?
    private(set) var created: Date?
    private(set) var encryptionKeyUrl: String?
    var toPersonId: String?
    private(set) var toPersonEmail: String?
    
    private(set) var targetUUID: String?
    private(set) var targetTag: SpaceType = SpaceType.group
    private(set) var targetLocked: Bool?
    
    private(set) var actorUUID: String?
    private(set) var actorEmail: String?
    private(set) var actorDisplayName: String?
    private(set) var actorOrgUUID: String?
    
    private var objectId: String?
    private var objectUUID: String?
    private(set) var objectTag: SpaceType = SpaceType.group
    private(set) var objectLocked: Bool?
    private(set) var objectEmail: String?
    private(set) var objectOrgUUID: String?
    private(set) var objectDisplayName: String?
    private(set) var objectConetnt: String?
    private(set) var objectMarkdown: String?
    private(set) var objectObjectType: ObjectType?
    private(set) var objectContentCategory: String?
    
    private(set) var isModerator:Bool?
    
    private(set) var parentUUID: String?
    private(set) var parentActorUUID: String?
    private(set) var parentType: String?
    private(set) var parentPublished: Date?
    
    private var groupMentionsItems: [[String: Any]]? {
        didSet {
            self.mentionedGroup = self.groupMentionsItems?.compactMap { value in
                return value["groupType"] as? String
            }
        }
    }
    private var peopleMentionsItems: [[String: Any]]? {
        didSet {
            self.mentionedPeople = self.peopleMentionsItems?.compactMap { value in
                return value["id"] as? String
            }
        }
    }
    
    private var fileItems: [[String: Any]]? {
        didSet {
            self.files = self.fileItems?.compactMap { value in
                return Mapper<RemoteFile>().map(JSON: value)
            }
        }
    }
    
    private(set) var files: [RemoteFile]?
    private(set) var mentionedGroup: [String]?
    private(set) var mentionedPeople: [String]?
    
    var object: String? {
        return self.objectUUID ?? self.objectId
    }
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        self.uuid <- map["id"]
        self.created <- (map["published"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        self.encryptionKeyUrl <- map["encryptionKeyUrl"]
        self.verb <- (map["verb"], VerbTransform())
        self.objectType <- (map["objectType"], ObjectTypeTransform())
        self.actorUUID <- map["actor.entryUUID"]
        self.actorEmail <- map["actor.emailAddress"]
        self.actorDisplayName <- map["actor.displayName"]
        self.actorOrgUUID <- map["actor.orgId"]
        self.targetUUID <- map["target.id"]
        self.targetTag <- (map["target.tags"], SpaceTypeTransform())
        self.targetLocked <- (map["target.tags"], LockedTransform())
        self.clientTempId <- map["clientTempId"]
        self.objectDisplayName <- map["object.displayName"]
        self.objectConetnt <- map["object.content"]
        self.objectMarkdown <- map["object.markdown"]
        self.groupMentionsItems <- map["object.groupMentions.items"]
        self.peopleMentionsItems <- map["object.mentions.items"]
        self.fileItems <- map["object.files.items"]
        self.objectUUID <- map["object.entryUUID"]
        self.objectId <- map["object.id"]
        self.objectEmail <- map["object.emailAddress"]
        self.objectOrgUUID <- map["object.orgId"]
        self.objectTag <- (map["object.tags"], SpaceTypeTransform())
        self.objectLocked <- (map["object.tags"], LockedTransform())
        self.isModerator <- (map["object.roomProperties.isModerator"], StringAndBoolTransform())
        self.objectObjectType <- (map["object.objectType"], ObjectTypeTransform())
        self.objectContentCategory <- map["object.contentCategory"]
        
        self.parentUUID <- map["parent.id"]
        self.parentActorUUID <- map["parent.actorId"]
        self.parentType <- map["parent.type"]
        self.parentPublished <- (map["parent.published"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
    }
}

extension ActivityModel {
    func decrypt(key: String?) -> ActivityModel {
        var activity = self
        activity.objectDisplayName = activity.objectDisplayName?.decrypt(key: key)
        activity.objectConetnt = activity.objectConetnt?.decrypt(key: key)
        activity.objectMarkdown = activity.objectMarkdown?.decrypt(key: key)
        activity.files = activity.files?.map { f in
            var file = f
            file.decrypt(key: key)
            return file
        }
        return activity;
    }
}


extension String {
            
    func encrypt(key: String?) -> String {
        if let key = key, let text = try? CjoseWrapper.ciphertext(fromContent: self.data(using: .utf8), key: key) {
            return text
        }
        return self
    }
    
    func decrypt(key: String?) -> String {
        if let key = key, let data = try? CjoseWrapper.content(fromCiphertext: self, key: key), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return self
    }
}

class IdentityTransform : TransformType {
    
    private var identityType: IdentityType
    
    init(for type: IdentityType) {
        self.identityType = type
    }
    
    func transformFromJSON(_ value: Any?) -> String? {
        return WebexId(type: self.identityType, uuid: (value as? String))?.base64Id
    }
    
    func transformToJSON(_ value: String?) -> String? {
        if let value = value {
            return WebexId.uuid(value)
        }
        return value
    }
}

class VerbTransform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> ActivityModel.Verb? {
        if let verb = value as? String {
            return ActivityModel.Verb(rawValue: verb)
        }
        return nil
    }

    func transformToJSON(_ value: ActivityModel.Verb?) -> String? {
        return value?.rawValue
    }
}

private class ObjectTypeTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> ObjectType? {
        if let type = value as? String {
            return ObjectType(rawValue: type)
        }
        return nil
    }

    func transformToJSON(_ value: ObjectType?) -> String? {
        return value?.rawValue
    }
}

class SpaceTypeTransform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> SpaceType? {
        if let tags = value as? [String], tags.contains("ONE_ON_ONE") {
            return SpaceType.direct
        }
        return SpaceType.group
    }
    
    func transformToJSON(_ value: SpaceType?) -> String? {
        if let value = value, value == SpaceType.direct {
            return "ONE_ON_ONE"
        }
        return nil
    }
}

class LockedTransform : TransformType {
    
    func transformFromJSON(_ value: Any?) -> Bool? {
        if let tags = value as? [String], tags.contains("LOCKED") {
            return true
        }
        return false
    }
    
    func transformToJSON(_ value: Bool?) -> String? {
        if let value = value, value == true {
            return "LOCKED"
        }
        return "UNLOCKED"
    }
}
