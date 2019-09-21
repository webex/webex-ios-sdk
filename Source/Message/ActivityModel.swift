// Copyright 2016-2019 Cisco Systems Inc
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

struct ActivityModel {
    
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
        
        static func isSupported(_ verb: String) -> Bool {
            if verb == post.rawValue || verb == share.rawValue || verb == delete.rawValue
                || verb == add.rawValue || verb == leave.rawValue || verb == acknowledge.rawValue
                || verb == create.rawValue || verb == update.rawValue
                || verb == assignModerator.rawValue || verb == unassignModerator.rawValue {
                return true
            } else {
                return false
            }
        }
    }
    
    private(set) var id: String?
    private(set) var clientTempId: String?
    private(set) var verb: ActivityModel.Verb?
    private(set) var created: Date?
    private(set) var encryptionKeyUrl: String?
    var toPersonId: String?
    private(set) var toPersonEmail: String?
    
    private(set) var targetId: String?
    private(set) var targetTag: SpaceType?
    private(set) var targetLocked: Bool?
    
    private(set) var actorId: String?
    private(set) var actorEmail: String?
    private(set) var actorDisplayName: String?
    private(set) var actorOrgId: String?
    
    private(set) var objectId: String?
    private(set) var objectTag: SpaceType?
    private(set) var objectLocked: Bool?
    private(set) var objectEmail: String?
    private(set) var objectOrgId: String?
    private(set) var objectDisplayName: String?
    private(set) var objectConetnt: String?
    private(set) var objectMarkdown: String?
    private(set) var mentionedPeople: [String]?
    private(set) var mentionedGroup: [String]?
    private(set) var files : [RemoteFile]?
    
    private(set) var dataId:String?
    private(set) var isModerator:Bool?
}

extension ActivityModel : ImmutableMappable {
    
    /// ActivityModel constructor.
    ///
    /// - note: for internal use only.
    public init(map: Map) throws {
        self.id = try? map.value("id", using: IdentityTransform(for: IdentityType.message))
        self.created = try? map.value("published", using: CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        self.encryptionKeyUrl = try? map.value("encryptionKeyUrl")
        self.verb = try? map.value("verb", using: VerbTransform())
        self.actorId = try? map.value("actor.entryUUID", using: IdentityTransform(for: IdentityType.people))
        self.actorEmail = try? map.value("actor.emailAddress")
        self.actorDisplayName = try? map.value("actor.displayName")
        self.actorOrgId = try? map.value("actor.orgId", using: IdentityTransform(for: IdentityType.organization))
        self.targetId = try? map.value("target.id", using: IdentityTransform(for: IdentityType.room))
        self.targetTag = try? map.value("target.tags", using: SpaceTypeTransform())
        self.targetLocked = try? map.value("target.tags", using: LockedTransform())
        self.clientTempId = try? map.value("clientTempId")
        self.objectDisplayName = try? map.value("object.displayName")
        self.objectConetnt = try? map.value("object.content")
        self.objectMarkdown = try? map.value("object.markdown")
        if let groupItems: [[String: Any]] = try? map.value("object.groupMentions.items"), groupItems.count > 0 {
            self.mentionedGroup = groupItems.compactMap { value in
                return value["groupType"] as? String
            }
        }
        if let peopleItems: [[String: Any]] = try? map.value("object.mentions.items"), peopleItems.count > 0 {
            self.mentionedPeople = peopleItems.compactMap { value in
                return (value["id"] as? String)?.hydraFormat(for: .people)
            }
        }
        if let fileItems: [[String: Any]] = try? map.value("object.files.items"), fileItems.count > 0 {
            self.files = fileItems.compactMap { value in
                return Mapper<RemoteFile>().map(JSON: value)
            }
        }
        
        self.objectId = try? map.value("object.id", using: IdentityTransform(for: IdentityType.message))
        self.objectEmail = try? map.value("object.emailAddress")
        self.objectOrgId = try? map.value("object.orgId", using: IdentityTransform(for: IdentityType.organization))
        self.objectTag = try? map.value("object.tags", using: SpaceTypeTransform())
        self.objectLocked = try? map.value("object.tags", using: LockedTransform())
        
        let tid:String? = try? map.value("target.id")
        if self.verb == Verb.acknowledge {
            let aid:String? = try? map.value("actor.entryUUID")
            self.dataId = "\(aid ?? ""):\(tid ?? "")".hydraFormat(for: IdentityType.membership)
        } else if self.verb == Verb.add || self.verb == Verb.leave || self.verb == Verb.assignModerator || self.verb == Verb.unassignModerator {
            let oid:String? = try? map.value("object.entryUUID")
            self.dataId = "\(oid ?? ""):\(tid ?? "")".hydraFormat(for: IdentityType.membership)
            self.objectId = try? map.value("object.entryUUID", using: IdentityTransform(for: IdentityType.people))
        }
        self.isModerator = try? map.value("object.roomProperties.isModerator", using: StringAndBoolTransform())
    }
    
    /// Mapping activity model to json format.
    ///
    /// - note: for internal use only.
    public func mapping(map: Map) {
        self.id >>> map["id"]
        self.targetId >>> map["roomId"]
        self.targetId >>> map["spaceId"]
        self.verb >>> (map["verb"], VerbTransform())
        self.targetTag >>> (map["roomType"], SpaceTypeTransform())
        self.targetTag >>> (map["spaceType"], SpaceTypeTransform())
        self.targetLocked >>> (map["isLocked"], LockedTransform())
        self.toPersonId >>> map["toPersonId"]
        self.toPersonEmail >>> map["toPersonEmail"]
        self.objectDisplayName >>> map["text"]
        self.objectConetnt >>> map["html"]
        self.objectMarkdown >>> map["markdown"]
        self.actorId >>> map["actorId"]
        self.actorEmail >>> map["actorEmail"]
        self.created?.longString >>> map["created"]
        self.mentionedPeople >>> map["mentionedPeople"]
        self.mentionedGroup >>> map["mentionedGroup"]
        self.files >>> map["files"]
        self.objectId >>> map["objectId"]
        self.objectTag >>> (map["spaceType"], SpaceTypeTransform())
        self.objectLocked >>> (map["isLocked"], LockedTransform())
        self.objectEmail >>> map["objectEmail"]
        self.objectOrgId >>> map["objectOrgId"]
        self.dataId >>> map["dataId"]
        self.isModerator >>> map["isModerator"]
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

enum IdentityType : String {
    // TODO: For change Id Need change to space later
    // case space
    case room
    case people
    case message
    case membership
    case organization
    case content
    case team
}

extension String {
    
    var locusFormat: String {
        if let decode = self.base64Decoded(), let id = decode.components(separatedBy: "/").last {
            if let first = id.components(separatedBy: ":").first {
                return first
            } else {
                return id
            }
        }
        return self
    }
    
    func hydraFormat(for type: IdentityType) -> String {
        return "ciscospark://us/\(type.rawValue.uppercased())/\(self)".base64Encoded() ?? self
    }
        
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
        return (value as? String)?.hydraFormat(for: self.identityType)
    }
    
    func transformToJSON(_ value: String?) -> String? {
        return value?.locusFormat
    }
}

private class VerbTransform: TransformType {
    
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
