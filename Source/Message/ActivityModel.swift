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

class ActivityModel : ObjectModel {
    
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
                || verb == assignModerator.rawValue || verb == unassignModerator.rawValue {
                return true
            } else {
                return false
            }
        }
    }

    private(set) var verb: ActivityModel.Verb?
    private(set) var encryptionKeyUrl: String?
    private(set) var target: ObjectModel?
    private(set) var object: ObjectModel?
    private(set) var actor: PersonModel?
    private(set) var parent: ParentModel?

    var conversationId: String? {
        if let target = self.target, target.objectType == .conversation {
            return target.id
        }
        else if let target = self.target as? TeamModel {
            return target.generalConversationUuid
        }
        else if let object = self.object, object.objectType == .conversation {
            return object.id
        }
        else if let object = self.object as? TeamModel {
            return object.generalConversationUuid
        }
        return nil
    }

    var conversationUrl: String? {
        if let target = self.target, target.objectType == .conversation {
            return target.id
        }
        else if let object = self.object, object.objectType == .conversation {
            return object.id
        }
        else if let base = self.url?[0, "/activities/"], let convId = self.conversationId {
            return "\(base)/conversations/\(convId)"
        }
        return nil
    }

    func isFromSelf(user: String) -> Bool {
        return self.actor?.id == user
    }

    func isSelfMention(user: String, lastJoinedDate: Date = Date(timeIntervalSince1970: 0)) -> Bool {
        return isPersonallyMentioned(user: user) || isIncludedInGroupMention(user: user, lastJoinedDate: lastJoinedDate)
    }

    func isAllMentioned(lastJoinedDate: Date = Date(timeIntervalSince1970: 0)) -> Bool {
        guard let comment = self.object as? CommentModel else {
            return false
        }
        guard let mentions = comment.groupMentions?.items, !mentions.isEmpty else {
            return false
        }
        for mention in mentions {
            if mention.groupType == .all && self.published! > lastJoinedDate {
                return true
            }
        }
        return false
    }

    private func isPersonallyMentioned(user: String) -> Bool {
        guard let comment = self.object as? CommentModel else {
            return false
        }
        guard let mentions = comment.mentions?.items, !mentions.isEmpty else {
            return false
        }
        for mention in mentions where mention.id == user {
            return true
        }
        return false
    }

    private func isIncludedInGroupMention(user: String, lastJoinedDate: Date = Date(timeIntervalSince1970: 0)) -> Bool {
        guard let comment = self.object as? CommentModel else {
            return false
        }
        guard let mentions = comment.groupMentions?.items, !mentions.isEmpty else {
            return false
        }
        return (!isFromSelf(user: user) && (self.published == nil ? true : self.published! > lastJoinedDate)) ? true : false
    }

    required init?(map: Map){
        super.init(map: map)
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        self.encryptionKeyUrl <- map["encryptionKeyUrl"]
        self.verb <- (map["verb"], TransformOf<Verb, String>(fromJSON: { Verb(rawValue: $0!) }, toJSON: { $0?.rawValue } ))
        self.target <- (map["target"], ObjectModelTransform())
        self.object <- (map["object"], ObjectModelTransform())
        self.actor <- map["actor"]
        self.parent <- map["parent"]
    }

    override func encrypt(key: String?) {
        super.encrypt(key: key)
        self.object?.encrypt(key: key)
    }

    override func decrypt(key: String?) {
        super.decrypt(key: key)
        self.object?.decrypt(key: key)
    }
}
