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

import UIKit
import ObjectMapper
import CoreServices

/// The struct of a message event
///
/// - since: 1.4.0
public enum MessageEvent {

    public enum UpdateType {
        case fileThumbnail([RemoteFile])
    }

    /// The callback when receive a new message
    case messageReceived(Message)
    /// The callback when a message was deleted
    case messageDeleted(String)
    /// The callback when a message was updated
    case messageUpdated(messageId: String, type: UpdateType)
}

/// This struct represents a Message on Cisco Webex.
///
/// - since: 1.2.0
public struct Message {
    
    /// The wrapper for the message text in different formats: plain text, markdown, and html.
    /// Please note this version of the SDK requires the application to convert markdown to html.
    /// Future version of the SDK will provide auto conversion from markdown to html.
    ///
    /// - since: 2.3.0
    public struct Text {
        
        /// Returns the plain text if exist
        var plain:String?
        
        /// Returns the html if exist.
        var html:String?
        
        ///Returns the markdown if exist.
        var markdown:String?
  
        /// Make a Text object for the plain text.
        ///
        /// - parameter plain: The plain text.
        public static func plain(plain: String) -> Text {
            return Text(plain: plain, html: nil, markdown: nil)
        }
        
        /// Make a Text object for the html.
        ///
        /// - parameter html: The text with the html markup.
        /// - parameter plain: The alternate plain text for cases that do not support html markup.
        public static func html(html: String, plain: String? = nil) -> Text {
            return Text(plain: plain, html: html, markdown: nil)
        }
        
        /// Make a Text object for the markdown.
        ///
        /// - parameter markdown: The text with the markdown markup.
        /// - parameter html: The html text for how to render the markdown. This will be optional in the future.
        /// - parameter plain: The alternate plain text for cases that do not support markdown and html markup.
        public static func markdown(markdown: String, html: String, plain: String? = nil) -> Text {
            return Text(plain: plain, html: html, markdown: markdown)
        }
        
        var simple: String? {
            return self.html ?? self.markdown ?? self.plain
        }
    }
    
    /// The identifier of this message.
    public private(set) var id: String?
    
    /// Returns the content of the message in as Message.Text object.
    ///
    /// - since: 2.3.0
    public private(set) var textAsObject: Message.Text?
    
    /// The identifier of the space where this message was posted.
    public var spaceId: String? {
        return WebexId(type: .room, uuid: self.activity.targetUUID)?.base64Id
    }
    
    ///  The type of the space, "group"/"direct", where the message is posted.
    public var spaceType: SpaceType {
        return self.activity.targetTag
    }
    
    /// The identifier of the person who sent this message.
    public var personId: String? {
        return WebexId(type: .people, uuid: self.activity.actorUUID)?.base64Id
    }
    
    /// The email address of the person who sent this message.
    public var personEmail: String? {
        return self.activity.actorEmail
    }
    
    /// The identifier of the recipient when sending a private 1:1 message.
    public var toPersonId: String? {
        return self.activity.toPersonId
    }
    
    /// The email address of the recipient when sending a private 1:1 message.
    public var toPersonEmail: EmailAddress? {
        // TODO
        return nil
    }
    
    /// The timestamp that the message being created.
    public var created: Date? {
        if let verb =  self.activity.verb, verb == .post || verb == .share {
            return self.activity.created
        }
        return nil
    }
    
    /// Returns true if the receipient of the message is included in message's mention list
    ///
    /// - since: 1.4.0
    public var isSelfMentioned: Bool {
        return self.mentions?.find { metion in
            switch metion {
            case .person(let id):
                return id == self.toPersonId
            case .all:
                return true
            }
        } != nil
    }
    
    /// The content of the message.
    public var text: String? {
        return self.textAsObject?.simple
    }
        
    /// An array of file attachments in the message.
    ///
    /// - since: 1.4.0
    public var files: [RemoteFile]? {
        return self.activity.files
    }
    
    /// Returns the parent message for the reply message.
    ///
    /// - since: 2.5.0
    public private(set) var parentId: String?
    
    /// Returns true for reply message.
    ///
    /// - since: 2.5.0
    public private(set) var isReply: Bool

    let activity: ActivityModel

    var isMissingThumbnail: Bool {
        if self.activity.verb != .share
                   || self.activity.objectObjectType != .content
                   || self.activity.objectContentCategory != "documents" {
            return false
        }
        if let files = self.files {
            for file in files {
                if file.thumbnail == nil && file.shouldTranscode {
                    return true
                }
            }
        }
        return false
    }
    
    init(activity: ActivityModel) {
        self.activity = activity
        self.parentId = WebexId(type: .message, uuid: activity.parentUUID)?.base64Id
        self.isReply = activity.parentType == "reply"
        self.id = WebexId(type: .message, uuid: activity.uuid)?.base64Id
        if self.activity.verb == ActivityModel.Verb.delete, let uuid = self.activity.object {
            self.id = WebexId(type: .message, uuid: uuid)?.base64Id
        }
        self.textAsObject = Message.Text(plain: activity.objectDisplayName, html: activity.objectConetnt, markdown: activity.objectMarkdown)
    }
    
    private var mentions: [Mention]? {
        var mentionList = [Mention]()
        if let peoples = self.activity.mentionedPeople {
            mentionList.append(contentsOf: (peoples.map { Mention.person(WebexId(type: .people, uuid: $0)!.base64Id)}))
        }
        if let groups = self.activity.mentionedGroup {
            for group in groups where group == "all" {
                mentionList.append(Mention.all)
                break
            }
        }
        return mentionList.count > 0 ? mentionList : nil
    }
}

extension Message : CustomStringConvertible {
    /// Json format descrition of message.
    ///
    /// - since: 1.4.0
    public var description: String {
        get {
            return activity.toJSONString(prettyPrint: true) ?? ""
        }
    }
}

/// A data type represents a local file.
///
/// - since: 1.4.0
public class LocalFile {
    
    /// A data type represents the thumbnail of this local file.
    /// The thumbnail typically is an image file to provide preview of the local file without opening.
    ///
    /// - since: 1.4.0
    public class Thumbnail {
        /// The local path of the thumbnail file to be uploaded.
        public let path: String
        /// The width of the thumbnail.
        public let width: Int
        /// The height of the thumbnail.
        public let height: Int
        /// The size in bytes of the thumbnail.
        public let size: UInt64
        /// The MIME type of thumbnail.
        public let mime: String
        
        /// LocalFile thumbnail constructor.
        ///
        /// - parameter path: the local path of the thumbnail file.
        /// - parameter mine: the MIME type of the thumbnail.
        /// - parameter width: the width of the thumbnail.
        /// - parameter height: the height of the thumbnail.
        /// - since: 1.4.0
        public init?(path: String, mime: String? = nil, width: Int, height: Int) {
            if width <= 0 || height <= 0 {
                return nil
            }
            self.path = path
            self.width = width
            self.height = height
            self.mime = mime ?? URL(fileURLWithPath: path).lastPathComponent.mimeType
            if !FileManager.default.fileExists(atPath: path) || !FileManager.default.isReadableFile(atPath: path) {
                return nil
            }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path), let size = attrs[FileAttributeKey.size] as? UInt64 else {
                return nil
            }
            self.size = size
        }
    }
    /// The path of the local file to be uploaded.
    public let path: String
    /// The display name of the file.
    public let name: String
    /// The MIME type of the file.
    public let mime: String
    /// The size in bytes of the file.
    public let size: UInt64
    /// The progress indicator callback for uploading progresses.
    public let progressHandler: ((Double) -> Void)?
    /// The thumbnail for the local file. If not nil, the thumbnail will be uploaded with the local file.
    public let thumbnail: Thumbnail?
    
    /// LocalFile constructor.
    /// - parameter path: The path of the local file.
    /// - parameter name: The name of the uploaded file.
    /// - parameter mime: The MIME type of the local file.
    /// - parameter thumbnail: The thumbnail for the local file.
    /// - parameter progressHandler: the progress indicator callback for uploading progresses.
    /// - since: 1.4.0
    public init?(path: String, name: String? = nil, mime: String? = nil, thumbnail: Thumbnail? = nil, progressHandler: ((Double) -> Void)? = nil) {
        let tempName = name ?? URL(fileURLWithPath: path).lastPathComponent
        self.path = path
        self.name = tempName
        self.mime = mime ?? tempName.mimeType
        self.thumbnail = thumbnail
        self.progressHandler = progressHandler
        if !FileManager.default.fileExists(atPath: path) || !FileManager.default.isReadableFile(atPath: path) {
            return nil
        }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path), let size = attrs[FileAttributeKey.size] as? UInt64 else {
            return nil
        }
        self.size = size
    }

    var shouldTranscode: Bool {
        return FileType.from(name: self.name, mime: self.mime, url: nil, path: self.path).shouldTranscode
    }
}

/// A data struct represents a remote file on Cisco Webex.
/// The content of the remote file can be downloaded via `MessageClient.downloadFile(...)`.
///
/// - since: 1.4.0
public struct RemoteFile {

    /// A data type represents a thumbnail for this remote file.
    /// The thumbnail typically is an image file which provides preview of the remote file without downloading.
    /// The content of the thumbnail can be downloaded via `MessageClient.downloadThumbnail(...)`.
    /// - since: 1.4.0
    public struct Thumbnail {
        /// The width of thumbanil.
        public internal(set) var width: Int?
        /// The height of thumbanil.
        public internal(set) var height: Int?
        /// The MIME type of thumbanil file.
        public internal(set) var mimeType: String?
        var url: String?
        var secureContentRef: String?
    }
    
    /// The display name of the remote file.
    public internal(set) var displayName: String?
    /// The MIME type of the remote file.
    public internal(set) var mimeType: String?
    /// The size in bytes of the remote file.
    public internal(set) var size: UInt64?
    /// The thumbnail of the remote file. Nil if no thumbnail availabe.
    public internal(set) var thumbnail: Thumbnail?
    
    var url: String?
    var secureContentRef: String?

    var shouldTranscode: Bool {
        return FileType.from(name: self.displayName, mime: self.mimeType, url: self.url, path: nil).shouldTranscode
    }
}

extension RemoteFile {
    
    init(local: LocalFile, downloadUrl: String) {
        self.url = downloadUrl
        self.displayName = local.name
        self.size = local.size
        self.mimeType = local.mime
    }
    
    mutating func encrypt(key: String?, scr: SecureContentReference) {
        self.displayName = self.displayName?.encrypt(key: key)
        if let chilerScr = try? scr.encryptedSecureContentReference(withKey: key) {
            self.secureContentRef = chilerScr
        }
    }
    
    mutating func decrypt(key: String?) {
        self.displayName = self.displayName?.decrypt(key: key)
        self.secureContentRef = self.secureContentRef?.decrypt(key: key)
        self.thumbnail?.decrypt(key: key)
    }
}

extension RemoteFile.Thumbnail {
    
    init(local: LocalFile.Thumbnail, downloadUrl: String) {
        self.url = downloadUrl
        self.mimeType = local.mime
        self.width = local.width
        self.height = local.height
    }
    
    mutating func encrypt(key: String?, scr: SecureContentReference) {
        if let chilerScr = try? scr.encryptedSecureContentReference(withKey: key) {
            self.secureContentRef = chilerScr
        }
    }
    
    fileprivate mutating func decrypt(key: String?) {
        self.secureContentRef = self.secureContentRef?.decrypt(key: key)
    }
    
}

extension RemoteFile : Mappable {
    
    /// File constructor.
    ///
    /// - note: for internal use only.
    public init?(map: Map) {
    }
    
    /// File mapping from JSON.
    ///
    /// - note: for internal use only.
    public mutating func mapping(map: Map) {
        url <- map["url"]
        displayName <- map["displayName"]
        mimeType <- map["mimeType"]
        size <- map["fileSize"]
        thumbnail <- map["image"]
        secureContentRef <- map["scr"]
    }
}

extension RemoteFile.Thumbnail : Mappable {
    
    /// File thumbnail constructor.
    ///
    /// - note: for internal use only.
    public init?(map: Map) {}
    
    /// File thumbnail mapping from JSON.
    ///
    /// - note: for internal use only.
    public mutating func mapping(map: Map) {
        url <- map["url"]
        mimeType <- map["mimeType"]
        width <- map["width"]
        height <- map["height"]
        secureContentRef <- map["scr"]
    }
}

enum FileType: String, CaseIterable {
    case image
    case excel
    case powerpoint
    case word
    case pdf
    case video
    case audio
    case zip
    case unknown

    var shouldTranscode: Bool {
        switch self {
        case .powerpoint, .excel, .word, .pdf:
            return true
        default:
            return false
        }
    }

    var extensions: [String] {
        switch self {
        case .image:
            return ["jpg", "jpeg", "png", "gif"]
        case .excel:
            return ["xls", "xlsx", "xlsm", "xltx", "xltm"]
        case .powerpoint:
            return ["ppt", "pptx", "pptm", "potx", "potm", "ppsx", "ppsm", "sldx", "sldm"]
        case .word:
            return ["doc", "docx", "docm", "dotx", "dotm"]
        case .pdf:
            return ["pdf"]
        case .video:
            return ["mp4", "m4p", "mpg", "mpeg", "3gp", "3g2", "mov", "avi", "wmv", "qt", "m4v", "flv", "m4v"]
        case .audio:
            return ["mp3", "wav", "wma"]
        case .zip:
            return ["zip"]
        case .unknown:
            return []
        }
    }

    private static func from(_ ext: String) -> FileType? {
        if let type = FileType.allCases.find(predicate: { $0.extensions.contains(ext) }) {
            return type
        }
        return nil
    }

    static func from(name: String?, mime: String?, url: String?, path: String?) -> FileType {
        if let mime = mime,
           let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
           let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension),
           let type = from((ext.takeRetainedValue() as String).lowercased()) {
            return type
        }
        if let urlString = url,
           let url = URL(string: urlString),
           let type = from(url.pathExtension.lowercased()) {
            return type
        }
        if let path = path,
           let ext = path.components(separatedBy: ".").last, ext.count > 0,
           let type = from(ext.lowercased()) {
            return type
        }
        if let name = name,
           let ext = name.components(separatedBy: ".").last, ext.count > 0,
           let type = from(ext.lowercased()) {
            return type
        }
        return .unknown
    }
}
