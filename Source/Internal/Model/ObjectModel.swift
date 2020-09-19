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

enum ObjectType : String {
    case activity
    case comment
    case content
    case conversation
    case person
    case file
    case locus
    case event
    case locusSessionSummary
    case team
    case microappInstance
    case spaceProperty
    case groupMention
    case giphy
    case link
}

class ObjectModel : Mappable, CustomStringConvertible {

    private(set) var objectType: ObjectType?
    var id: String?
    var url: String?
    var published: Date?
    var content: String?
    var displayName: String?
    var clientTempId: String?

    required init?(map: Map) { }

    func mapping(map: Map) {
        self.id <- map["id"]
        self.url <- map["url"]
        self.objectType <- (map["objectType"], ObjectTypeTransform())
        self.clientTempId <- map["clientTempId"]
        self.published <- (map["published"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        self.displayName <- map["displayName"]
        self.content <- map["content"]
    }

    func encrypt(key: String?) {
        self.displayName = self.displayName?.encrypt(key: key)
        self.content = self.content?.encrypt(key: key)
    }

    func decrypt(key: String?) {
        self.displayName = self.displayName?.decrypt(key: key)
        self.content = self.content?.decrypt(key: key)
    }
    
    public var description: String { return self.toJSONString(prettyPrint: false) ?? String(describing: type(of: self)) }
}

class ObjectModelTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> ObjectModel? {
        guard let json = value as? [String: Any] else {
            return nil
        }
        if let string = json["objectType"] as? String, let type = ObjectType(rawValue: string) {
            switch type {
            case .person:
                return PersonModel(JSON: json)
            case .team:
                return TeamModel(JSON: json)
            case .conversation:
                return ConversationModel(JSON: json)
            case .comment:
                return CommentModel(JSON: json)
            case .file:
                return FileModel(JSON: json)
            case .content:
                return ContentModel(JSON: json)
            case .groupMention:
                return GroupMentionModel(JSON: json)
            default:
                break
            }
        }
        return ObjectModel(JSON: json)
    }

    func transformToJSON(_ value: ObjectModel?) -> [String: Any]? {
        return value?.toJSON()
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

