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
import Alamofire
import SwiftyJSON

/// The enumeration of Before types.
///
/// - since: 1.4.0
public enum Before {
    /// Before one particular message by message Id.
    case message(String)
    /// Before a particular time point by date.
    case date(Date)
}

/// The enumeration of mention types in Webex Message Client.
///
/// - since: 1.4.0
public enum Mention {
    /// Mention one particular person by person Id.
    case person(String)
    /// Mention all people in a space.
    case all
}

/// MessageClient represents a client to the Webex Teams platform. It can send and receive messages.
///
/// Use `Webex.messages` to get an instance of MessageClient.
///
/// - since: 1.4.0
public class MessageClient {

    /// The callback handler for incoming message events.
    ///
    /// - since: 1.4.0
    public var onEvent: ((MessageEvent) -> Void)?

    /// The callback handler for incoming message events.
    ///
    /// - since: 2.3.0
    public var onEventWithPayload: ((MessageEvent, WebexEventPayload) -> Void)?

    let phone: Phone
    private let queue = SerialQueue()
    
    private var userUUID: String?
    private var kmsCluster: String?
    private var rsaPublicKey: String?
    private var ephemeralKey: String?
    private var keySerialization: String?

    private var ephemeralKeyRequest: (request: KmsEphemeralKeyRequest, callback: (Error?) -> Void)?
    private var keyMaterialCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [:]
    private var keysCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [:]
    private var encryptionKeys: [String: EncryptionKey] = [:]
    private var conversations: [String: (convUrl: String, convId: String)] = [:]
    private typealias KeyHandler = (Result<(String, String)>) -> Void
    private var cachedMessages: [String: String] = [:]

    var authenticator: Authenticator {
        return self.phone.authenticator
    }

    var deviceUrl: String? {
        return self.phone.devices.device?.deviceUrl.absoluteString
    }

    var device: Device? {
        return self.phone.devices.device
    }

    init(phone: Phone) {
        self.phone = phone
    }

    /// Lists all messages in a space by space Id.
    /// The list sorts the messages in descending order by creation date.
    ///
    /// Note that the file attachment of the message are not downloaded.
    /// Use the `downloadFile(...)` or `downloadThumbnail(...)` to download
    /// the actual content or the thumbnail of the attachment.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter before: If not nil, only list messages sent before this condition.
    /// - parameter max: Limit the maximum number of messages in the response, default is 50.
    /// - parameter mentionedPeople: List messages where a person (using `Mention.person`) or all (using `Mention.all`) is mentioned.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished with a list of messages based on the above criteria.
    /// - returns: Void
    /// - since: 1.4.0
    public func list(spaceId: String,
                     before: Before? = nil,
                     max: Int = 50,
                     mentionedPeople: Mention? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<[Message]>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            } else {
                if max == 0 {
                    (queue ?? DispatchQueue.main).async {
                        completionHandler(ServiceResponse(nil, Result.success([])))
                    }
                    return
                }
                if let before = before {
                    switch before {
                    case .message(let messageId):
                        self.get(messageId: messageId, decrypt: false, queue: queue) { response in
                            if let error = response.result.error {
                                completionHandler(ServiceResponse(response.response, Result.failure(error)))
                            } else {
                                self.listBefore(spaceId: spaceId, mentionedPeople: mentionedPeople, date: response.result.data?.created, max: max, result: [], queue: queue, completionHandler: completionHandler)
                            }
                        }
                    case .date(let date):
                        self.listBefore(spaceId: spaceId, mentionedPeople: mentionedPeople, date: date, max: max, result: [], queue: queue, completionHandler: completionHandler)
                    }
                } else {
                    self.listBefore(spaceId: spaceId, mentionedPeople: mentionedPeople, date: nil, max: max, result: [], queue: queue, completionHandler: completionHandler)
                }
            }
        }
    }

    private func listBefore(spaceId: String, mentionedPeople: Mention? = nil, date: Date?, max: Int, result: [ActivityModel], queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<[Message]>) -> Void) {
        guard let conversation = WebexId.from(base64Id: spaceId), conversation.is(.room),
              let serviceUrl = self.phone.devices.device?.getIdentityServiceClusterUrl(urn: conversation.clusterId),
              let convUrl = conversation.urlBy(device: phone.devices.device) else {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.failure(WebexError.illegalOperation(reason: "Cannot found the space: \(spaceId)"))))
            }
            return
        }
        let requestMax = max * 2
        let dateKey = mentionedPeople == nil ? "maxDate" : "sinceDate"
        let request = ServiceRequest.make(serviceUrl)
                .authenticator(self.authenticator)
                .path(mentionedPeople == nil ? "activities" : "mentions")
                .query(["conversationId": conversation.uuid, "limit": requestMax, dateKey: (date ?? Date()).iso8601String])
                .keyPath("items")
                .queue(queue)
                .build()
        request.responseArray { (response: ServiceResponse<[ActivityModel]>) in
            switch response.result {
            case .success:
                let responseValue: [ActivityModel] = response.result.data ?? []
                let result = result + responseValue.filter({ $0.verb == ActivityModel.Verb.post || $0.verb == ActivityModel.Verb.share })
                if result.count >= max || responseValue.count < requestMax {
                    let key = self.encryptionKey(convUrl: convUrl)
                    key.material(client: self) { material in
                        if let material = material.data {
                            let messages: [Message] = result.prefix(max).map { activity in
                                activity.decrypt(key: material)
                                return self.cacheMessageIfNeeded(message: Message(activity: activity, clusterId: conversation.clusterId, person: self.phone.me))
                            }
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.success(messages)))
                            }
                        } else {
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.failure(material.error ?? MSGError.keyMaterialFetchFail)))
                            }
                        }
                    }
                } else {
                    self.listBefore(spaceId: spaceId, mentionedPeople: mentionedPeople, date: responseValue.last?.published, max: max, result: result, queue: queue, completionHandler: completionHandler)
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }

    /// Posts a message with optional file attachments to a user by email address.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// - parameter toPersonEmail: The email address of the user to whom the message is to be posted.
    /// - parameter withFiles: Local files to be uploaded with the message.
    /// - parameter parent: If not nil, the sent message will belong to the thread of the parent message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toPersonEmail: EmailAddress,
                     withFiles: [LocalFile]? = nil,
                     parent: Message? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(person: toPersonEmail.toString(), text: text, files: withFiles, parent: parent, queue: queue, completionHandler: completionHandler)
    }

    /// Posts a message with optional file attachments to a user by id.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// - parameter toPerson: The id of the user to whom the message is to be posted.
    /// - parameter withFiles: Local files to be attached to the message.
    /// - parameter parent: If not nil, the sent message will belong to the thread of the parent message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toPerson: String,
                     withFiles: [LocalFile]? = nil,
                     parent: Message? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(person: toPerson, text: text, files: withFiles, parent: parent, queue: queue, completionHandler: completionHandler)
    }

    /// Posts a message with optional file attachments to a space by spaceId.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// To notify specific person or everyone in a space, mentions should be used.
    /// Having <code>@johndoe</code> in the content of the message does not generate notification.
    ///
    /// - parameter toSpace: The identifier of the space where the message is to be posted.
    /// - parameter mentions: Notify these mentions.
    /// - parameter withFiles: Local files to be uploaded to the space.
    /// - parameter parent: If not nil, the sent message will belong to the thread of the parent message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toSpace: String,
                     mentions: [Mention]? = nil,
                     withFiles: [LocalFile]? = nil,
                     parent: Message? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        if let conv = WebexId.from(base64Id: toSpace), conv.is(.room), let convUrl = conv.urlBy(device: self.phone.devices.device) {
            self.post(text, convUrl: convUrl, convId: conv.uuid, mentions: mentions, withFiles: withFiles, parent: parent, queue: queue, completionHandler: completionHandler)
        } else {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.failure(WebexError.illegalOperation(reason: "Illegal Space \(toSpace)"))))
            }
        }
    }

    private func post(_ text: Message.Text? = nil,
                      convUrl: String,
                      convId: String,
                      mentions: [Mention]? = nil,
                      withFiles: [LocalFile]? = nil,
                      parent: Message? = nil,
                      queue: DispatchQueue? = nil,
                      completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            } else {
                let plainText = text?.plain
                let formattedText = text?.html
                let markdown = text?.markdown
                var object = [String: Any]()
                object["objectType"] = ObjectType.comment.rawValue
                object["displayName"] = plainText
                object["content"] = formattedText
                object["markdown"] = markdown
                var mentionedGroup = [[String: String]]()
                var mentionedPeople = [[String: String]]()
                mentions?.forEach { mention in
                    switch mention {
                    case .all:
                        mentionedGroup.append(["objectType": "groupMention", "groupType": "all"])
                    case .person(let person):
                        mentionedPeople.append(["objectType": "person", "id": WebexId.uuid(person)])
                    }
                }
                object["mentions"] = ["items": mentionedPeople]
                object["groupMentions"] = ["items": mentionedGroup]

                var parentModel: [String: Any]?
                if let message = parent, let id = message.id {
                    parentModel = ["id": WebexId.uuid(id), "type": "reply"]
                }

                var verb = ActivityModel.Verb.post
                let key = self.encryptionKey(convUrl: convUrl)
                key.material(client: self) { material in
                    if let material = material.data {
                        var set1 = false
                        var set2 = false
                        if let encrypt = plainText?.encrypt(key: material) {
                            object["displayName"] = encrypt
                            if plainText == formattedText {
                                object["content"] = encrypt
                                set1 = true
                            }
                            if plainText == markdown {
                                object["markdown"] = encrypt
                                set2 = true
                            }
                        }
                        if !set1, let encrypt = formattedText?.encrypt(key: material) {
                            object["content"] = encrypt
                            if !set2 && formattedText == markdown {
                                object["markdown"] = encrypt
                                set2 = true
                            }
                        }
                        if !set2, let encrypt = markdown?.encrypt(key: material) {
                            object["markdown"] = encrypt
                        }
                    }
                    let opeations = UploadFileOperations(key: key, files: withFiles ?? [LocalFile]())
                    opeations.run(client: self) { result in
                        if let files = result.data, files.count > 0 {
                            object["objectType"] = ObjectType.content.rawValue
                            object["contentCategory"] = "documents"
                            object["files"] = ["items": files.toJSON()]
                            verb = ActivityModel.Verb.share
                        }
                        let target: [String: Any] = ["id": convId, "objectType": ObjectType.conversation.rawValue]
                        key.encryptionUrl(client: self) { encryptionUrl in
                            if let keyUrl = encryptionUrl.data {
                                let request = ServiceRequest.make(convUrl)
                                        .authenticator(self.authenticator)
                                        .method(.post)
                                    .body(["verb": verb.rawValue, "encryptionKeyUrl": keyUrl, "object": object, "target": target, "clientTempId": "\(self.phone.phoneId):\(UUID().uuidString)", "parent": parentModel])
                                        .path(verb == ActivityModel.Verb.share ? "content" : "activities")
                                        .query(((withFiles ?? []).contains {
                                            $0.shouldTranscode
                                        }) ? ["async": false, "transcode": true] : [:])
                                        .queue(queue)
                                        .build()
                                request.responseObject { (response: ServiceResponse<ActivityModel>) in
                                    switch response.result {
                                    case .success(let activity):
                                        activity.decrypt(key: material.data)
                                        let message = Message(activity: activity, clusterId: self.phone.devices.device?.getClusterId(url: activity.url), person: self.phone.me)
                                        completionHandler(ServiceResponse(response.response, Result.success(self.cacheMessageIfNeeded(message: message))))
                                    case .failure(let error):
                                        completionHandler(ServiceResponse(response.response, Result.failure(error)))
                                    }
                                }
                            } else {
                                (queue ?? DispatchQueue.main).async {
                                    completionHandler(ServiceResponse(nil, Result.failure(encryptionUrl.error ?? MSGError.encryptionUrlFetchFail)))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func post(person: String,
                      text: Message.Text? = nil,
                      files: [LocalFile]? = nil,
                      parent: Message? = nil,
                      queue: DispatchQueue? = nil,
                      completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.getOrCreateConversationWithPerson(person: WebexId.from(base64Id: person)?.uuid ?? person, queue: queue) { result in
            if let pair = result.data {
                self.post(text, convUrl: pair.convUrl, convId: pair.convId, withFiles: files, parent: parent, queue: queue, completionHandler: completionHandler)
            } else {
                completionHandler(ServiceResponse(nil, Result.failure(result.error ?? MSGError.spaceFetchFail)))
            }
        }
    }

    /// Retrieves the details of a message by id.
    ///
    /// Note that the file attachment of the message are not downloaded.
    /// Use the `downloadFile(...)` or `downloadThumbnail(...)` to download
    /// the actual content or the thumbnail of the attachment.
    ///
    /// - parameter messageId: The identifier of the message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is retrieved.
    /// - returns: Void
    /// - since: 1.2.0
    public func get(messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            } else {
                self.get(messageId: messageId, decrypt: true, queue: queue, completionHandler: completionHandler)
            }
        }
    }

    private func get(messageId: String, decrypt: Bool, queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        guard let id = WebexId.from(base64Id: messageId), id.is(.message), let serviceUrl = self.phone.devices.device?.getIdentityServiceClusterUrl(urn: id.clusterId) else {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.failure(WebexError.illegalOperation(reason: "Cannot found the message: \(messageId)"))))
            }
            return
        }
        let request = ServiceRequest.make(serviceUrl)
                .authenticator(self.authenticator)
                .path("activities").path(id.uuid)
                .queue(queue)
                .build()
        request.responseObject { (response: ServiceResponse<ActivityModel>) in
            switch response.result {
            case .success(let activity):
                if let convUrl = activity.conversationUrl, decrypt {
                    let key = self.encryptionKey(convUrl: convUrl)
                    key.material(client: self) { material in
                        activity.decrypt(key: material.data)
                        (queue ?? DispatchQueue.main).async {
                            completionHandler(ServiceResponse(response.response, Result.success(self.cacheMessageIfNeeded(message: Message(activity: activity, clusterId: id.clusterId, person: self.phone.me)))))
                        }
                    }
                } else {
                    completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity, clusterId: id.clusterId, person: self.phone.me))))
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }

    /// Deletes a message by id.
    ///
    /// - parameter messageId: The identifier of the message to be deleted.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is deleted.
    /// - returns: Void
    /// - since: 1.2.0
    public func delete(messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        Service.hydra.global.authenticator(self.authenticator).path("messages").path(messageId).method(.delete).queue(queue).build().responseJSON(completionHandler)
        DispatchQueue.main.async {
            for (key, value) in self.cachedMessages where value == messageId {
                self.cachedMessages.removeValue(forKey: key)
            }
        }
    }

    /// Mark all messages in the space read.
    ///
    /// - parameter spaceId: The identifier of the space where the message is.
    /// - parameter messageId: The identifier of the message which user read.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func markAsRead(spaceId: String, messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        guard let conversation = WebexId.from(base64Id: spaceId), conversation.is(.room), let convUrl = self.phone.devices.device?.getIdentityServiceClusterUrl(urn: conversation.clusterId) else {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.failure(WebexError.illegalOperation(reason: "Cannot found the space: \(spaceId)"))))
            }
            return
        }
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            } else {
                let object = ["id": WebexId.uuid(messageId), "objectType": ObjectType.activity.rawValue]
                let target = ["id": conversation.uuid, "objectType": ObjectType.conversation.rawValue]
                let request = ServiceRequest.make(convUrl)
                        .authenticator(self.authenticator)
                        .path("activities")
                        .method(.post)
                        .body(["objectType": ObjectType.activity.rawValue, "verb": ActivityModel.Verb.acknowledge.rawValue, "object": object, "target": target])
                        .queue(queue)
                        .build()
                request.responseJSON(completionHandler)
            }
        }
    }

    /// Mark all messages in the space read.
    ///
    /// - parameter spaceId: The identifier of the space where the message is.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func markAsRead(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            } else {
                self.list(spaceId: spaceId, max: 1, queue: queue) { (response) in
                    switch response.result {
                    case .success(let messages):
                        if let message = messages.first, let lastMessageId = message.id {
                            self.markAsRead(spaceId: spaceId, messageId: lastMessageId, queue: queue, completionHandler: completionHandler)
                        } else {
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.failure(response.result.error ?? MSGError.spaceMessageFetchFail)))
                            }
                        }
                    case .failure(let error):
                        completionHandler(ServiceResponse(response.response, Result.failure(error)))
                    }
                }
            }
        }
    }

    /// Download a file attachement to the specified local directory.
    ///
    /// - parameter file: The RemoteFile object need to be downloaded. Use `Message.remoteFiles` to get the references.
    /// - parameter to: The local file directory for saving dwonloaded file attahement.
    /// - parameter progressHandler: The download progress indicator.
    /// - parameter completionHandler: A closure to be executed once the download is completed. The URL contains the path to the downloded file.
    /// - returns: Void
    /// - since: 1.4.0
    public func downloadFile(_ file: RemoteFile, to: URL? = nil, progressHandler: ((Double) -> Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(error))
                }
            } else {
                if let url = file.model.url {
                    let operation = DownloadFileOperation(authenticator: self.authenticator,
                            url: url,
                            displayName: file.displayName,
                            scr: file.model.scrObject,
                            thnumnail: false,
                            target: to,
                            queue: nil,
                            progressHandler: progressHandler,
                            completionHandler: completionHandler)
                    operation.run()
                } else {
                    DispatchQueue.main.async {
                        completionHandler(Result.failure(MSGError.downloadError))
                    }
                }
            }
        }
    }

    /// Download the thumbnail for a file attachment to the specified local directory.
    /// Note Cisco Webex doesn't generate thumbnail for all files.
    ///
    /// - parameter file: The RemoteFile object whose thumbnail needs to be downloaded.
    /// - parameter to: The local file directory for saving downloaded thumbnail.
    /// - parameter progressHandler: The download progress indicator.
    /// - parameter completionHandler: A closure to be executed once the download is completed. The URL contains the path to the downloded thumbnail.
    /// - returns: Void
    /// - since: 1.4.0
    public func downloadThumbnail(for file: RemoteFile, to: URL? = nil, progressHandler: ((Double) -> Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(error))
                }
            } else {
                if let url = file.thumbnail?.model.url {
                    let operation = DownloadFileOperation(authenticator: self.authenticator,
                            url: url,
                            displayName: file.displayName,
                            scr: file.thumbnail?.model.scrObject,
                            thnumnail: true,
                            target: to,
                            queue: nil,
                            progressHandler: progressHandler,
                            completionHandler: completionHandler)
                    operation.run()
                } else {
                    DispatchQueue.main.async {
                        completionHandler(Result.failure(MSGError.downloadError))
                    }
                }
            }
        }
    }
    
    func decrypt(activity: ActivityModel, of convUrl: String, completionHandler: @escaping (ActivityModel) -> Void) {
        let key = self.encryptionKey(convUrl: convUrl)
        if let encryptionUrl = activity.encryptionKeyUrl {
            key.tryRefresh(encryptionUrl: encryptionUrl)
        }
        key.material(client: self) { material in
            activity.decrypt(key: material.data)
            completionHandler(activity)
        }
    }
    
    func doMessageUpdated(content: ContentModel, completionHandler: @escaping (MessageEvent) -> Void) {
        DispatchQueue.main.async {
            if let contentId = content.id, let messageId = self.cachedMessages[contentId], let items = content.files?.items, !items.isEmpty {
                let files = items.compactMap { RemoteFile(model: $0) }
                // TODO Check the validity of the caches regularly
                if files.first(where: { $0.thumbnail == nil && $0.shouldTranscode }) == nil {
                    self.cachedMessages[contentId] = nil
                }
                completionHandler(MessageEvent.messageUpdated(messageId: messageId, type: .fileThumbnail(files)))
            }
        }
    }
    
    func doMessageDeleted(messageId: WebexId, completionHandler: @escaping (MessageEvent) -> Void) {
        DispatchQueue.main.async {
            let base64Id = messageId.base64Id
            for (key, value) in self.cachedMessages where value == base64Id {
                self.cachedMessages.removeValue(forKey: key)
            }
            completionHandler(MessageEvent.messageDeleted(base64Id))
        }
    }
    
    func handle(kms: KmsMessageModel) {
        if let response = kms.kmsMessages?.first {
            if let request = self.ephemeralKeyRequest {
                if let key = try? KmsEphemeralKeyResponse(responseMessage: response, request: request.request).jwkEphemeralKey {
                    self.ephemeralKey = key
                    request.callback(nil)
                } else {
                    request.callback(MSGError.ephemaralKeyFetchFail)
                }
                self.ephemeralKeyRequest = nil
            } else {
                handleSpaceKeyMaterialRequest(response: response)
            }
        }
    }

    private func handleSpaceKeyMaterialRequest(response: String) {
        if let key = self.ephemeralKey, let data = try? CjoseWrapper.content(fromCiphertext: response, key: key), let json = try? JSON(data: data) {
            if let key = json["key"].object as? [String: Any] {
                if let jwk = key["jwk"], let uri = key["uri"], let keyMaterial = JSON(jwk).rawString(), let keyUri = JSON(uri).rawString() {
                    if var handlers = self.keyMaterialCompletionHandlers[keyUri], handlers.count > 0 {
                        let handler = handlers.removeFirst()
                        self.keyMaterialCompletionHandlers[keyUri] = handlers
                        handler(Result.success((keyUri, keyMaterial)))
                    }
                    if let handlers = self.keyMaterialCompletionHandlers[keyUri], handlers.count == 0 {
                        self.keyMaterialCompletionHandlers[keyUri] = nil
                    }
                }
            } else if let dict = (json["keys"].object as? [[String: Any]])?.first {
                if let key = try? KmsKey(from: dict), let convUrl = self.keysCompletionHandlers.keys.first, let handlers = self.keysCompletionHandlers.popFirst()?.value {
                    self.authenticator.accessToken { token in
                        let spaceUserIds = self.encryptionKey(convUrl: convUrl).spaceUserIds
                        let requestId = UUID().uuidString
                        if let deviceUrl = self.deviceUrl, let request = try? KmsRequest(requestId: requestId, clientId: deviceUrl, userId: self.userUUID, bearer: token, method: "create", uri: "/resources") {
                            request.additionalAttributes = ["keyUris": [key.uri], "userIds": spaceUserIds]
                            if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: self.ephemeralKey) {
                                let object = ["objectType": ObjectType.conversation.rawValue, "defaultActivityEncryptionKeyUrl": key.uri]
                                let target = ["objectType": ObjectType.conversation.rawValue, "id": (convUrl as NSString).lastPathComponent]
                                let request = ServiceRequest.make(convUrl)
                                        .authenticator(self.authenticator)
                                        .path("activities")
                                        .method(.post)
                                        .body(["objectType": "activity", "verb": ActivityModel.Verb.updateKey.rawValue, "object": object, "target": target, "kmsMessage": chiperText])
                                        .build()
                                request.responseJSON { (response: ServiceResponse<Any>) in
                                    switch response.result {
                                    case .success(_):
                                        handlers.forEach {
                                            $0(Result.success((key.uri, key.jwk)))
                                        }
                                    case .failure(let error):
                                        handlers.forEach {
                                            $0(Result.failure(error))
                                        }
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func requestSpaceEncryptionURL(convUrl: String, completionHandler: @escaping (Result<String?>) -> Void) {
        self.prepareEncryptionKey { error in
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }

            func handleResourceObjectUrl(model: ConversationModel) {
                if let paticipients = model.participants?.items {
                    paticipients.forEach { person in
                        if let userId = (person.entryUUID ?? person.id) {
                            if !self.encryptionKey(convUrl: convUrl).spaceUserIds.contains(userId) {
                                self.encryptionKey(convUrl: convUrl).spaceUserIds.append(userId)
                            }
                        }
                    }
                }
                completionHandler(Result.success(nil))
            }

            let request = ServiceRequest.make(convUrl)
                    .authenticator(self.authenticator)
                    .query(["includeActivities": false, "includeParticipants": true])
                    .build()
            request.responseObject { (response: ServiceResponse<ConversationModel>) in
                if let model = response.result.data {
                    if let encryptionUrl = model.encryptionKeyUrl ?? model.defaultActivityEncryptionKeyUrl {
                        completionHandler(Result.success(encryptionUrl))
                    } else if let _ = model.kmsResourceObjectUrl {
                        handleResourceObjectUrl(model: model)
                    }
                } else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.encryptionUrlFetchFail))
                }
            }
        }
    }

    func requestSpaceKeyMaterial(convUrl: String, encryptionUrl: String?, completionHandler: @escaping (Result<(String, String)>) -> Void) {
        self.prepareEncryptionKey { error in
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }
            self.authenticator.accessToken { token in
                guard let token = token else {
                    completionHandler(Result.failure(WebexError.noAuth))
                    return
                }
                guard let userUUID = self.userUUID, let ephemeralKey = self.ephemeralKey else {
                    completionHandler(Result.failure(MSGError.ephemaralKeyFetchFail))
                    return
                }
                self.processSpaceKeyMaterialRequest(convUrl: convUrl,
                        encryptionUrl: encryptionUrl,
                        token: token,
                        userUUID: userUUID,
                        ephemeralKey: ephemeralKey,
                        completionHandler: completionHandler)
            }
        }
    }

    private func processSpaceKeyMaterialRequest(convUrl: String, encryptionUrl: String?, token: String, userUUID: String, ephemeralKey: String?, completionHandler: @escaping (Result<(String, String)>) -> Void) {
        var parameters: [String: Any]?
        var failed: () -> Void
        let requestId = UUID().uuidString
        if let deviceUrl = self.deviceUrl, let encryptionUrl = encryptionUrl {
            if let request = try? KmsRequest(requestId: requestId, clientId: deviceUrl, userId: userUUID, bearer: token, method: "retrieve", uri: encryptionUrl),
               let serialize = request.serialize(),
               let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                self.keySerialization = chiperText
                parameters = ["kmsMessages": [chiperText], "destination": "unused"] as [String: Any]
                var handlers: [(Result<(String, String)>) -> Void] = self.keyMaterialCompletionHandlers[encryptionUrl] ?? []
                handlers.append(completionHandler)
                self.keyMaterialCompletionHandlers[encryptionUrl] = handlers
            }
            failed = {
                self.keyMaterialCompletionHandlers[encryptionUrl]?.forEach {
                    $0(Result.failure(MSGError.keyMaterialFetchFail))
                }
                self.keyMaterialCompletionHandlers[encryptionUrl] = nil
            }
        } else {
            if let deviceUrl = self.deviceUrl, let request = try? KmsRequest(requestId: requestId, clientId: deviceUrl, userId: userUUID, bearer: token, method: "create", uri: "/keys") {
                request.additionalAttributes = ["count": 1]
                if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                    self.keySerialization = chiperText
                    parameters = ["kmsMessages": [chiperText], "destination": "unused"] as [String: Any]
                    var handlers: [(Result<(String, String)>) -> Void] = self.keysCompletionHandlers[convUrl] ?? []
                    handlers.append(completionHandler)
                    self.keysCompletionHandlers[convUrl] = handlers
                }
            }
            failed = {
                self.keysCompletionHandlers[convUrl]?.forEach {
                    $0(Result.failure(MSGError.keyMaterialFetchFail))
                }
                self.keysCompletionHandlers[convUrl] = nil
            }
        }

        if let parameters = parameters, parameters.count >= 2 {
            Service.kms.homed(for: self.device)
                    .authenticator(self.authenticator)
                    .path("kms").path("messages")
                    .method(.post)
                    .headers(["Cisco-Request-ID": requestId])
                    .body(parameters)
                    .build().responseString { (response: ServiceResponse<String>) in
                        SDKLogger.shared.debug("Request KMS Material Response ============  \(response.result)")
                        switch response.result {
                        case .success(_):
                            break
                        case .failure(_):
                            failed()
                            break
                        }
                    }
        } else {
            failed()
        }
    }

    private func prepareEncryptionKey(completionHandler: @escaping (Error?) -> Void) {
        func validateResult(_ error: Error?) -> Bool {
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                self.queue.yield()
                return false
            }
            return true
        }

        func processResult() {
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }

        func validateKeyRequest(error: Error?) {
            if validateResult(error) {
                self.requestEphemeralKey { error in
                    if validateResult(error) {
                        self.queue.yield()
                        processResult()
                    }
                }
            }
        }

        self.queue.sync {
            self.requestUserId { error in
                if validateResult(error) {
                    self.requestClusterAndRSAPubKey { error in
                        validateKeyRequest(error: error)
                    }
                }
            }
        }
    }

    private func requestUserId(completionHandler: @escaping (Error?) -> Void) {
        if self.userUUID != nil {
            completionHandler(nil)
            return
        }
        let request = Service.conv.homed(for: self.device)
                .authenticator(self.authenticator)
                .path("users")
                .build()
        request.responseJSON { (response: ServiceResponse<Any>) in
            if let usersDict = response.result.data as? [String: Any], let uuid = usersDict["id"] as? String {
                self.userUUID = uuid
                completionHandler(nil)
            } else {
                completionHandler(MSGError.clientInfoFetchFail)
            }
        }
    }

    private func requestClusterAndRSAPubKey(completionHandler: @escaping (Error?) -> Void) {
        if self.kmsCluster != nil && self.rsaPublicKey != nil {
            completionHandler(nil)
            return
        }
        Service.kms.homed(for: self.device)
                .path("kms")
                .authenticator(self.authenticator)
                .build()
                .responseJSON { (response: ServiceResponse<Any>) in
                    if let kmsDict = response.result.data as? [String: Any], let kmsCluster = kmsDict["kmsCluster"] as? String, let rsaPublicKey = kmsDict["rsaPublicKey"] as? String {
                        self.kmsCluster = kmsCluster
                        self.rsaPublicKey = rsaPublicKey
                        completionHandler(nil)
                    } else {
                        completionHandler(MSGError.clientInfoFetchFail)
                    }
                }
    }

    private func requestEphemeralKey(completionHandler: @escaping (Error?) -> Void) {
        if self.ephemeralKey != nil {
            completionHandler(nil)
            return
        }
        self.authenticator.accessToken { token in
            guard let token = token else {
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            guard let deviceUrl = self.deviceUrl else {
                SDKLogger.shared.debug("No Device URL")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            if (self.ephemeralKeyRequest != nil) {
                SDKLogger.shared.debug("Request EphemeralKey duplicated")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            guard let userUUID = self.userUUID, let cluster = self.kmsCluster, let clusterURI = URL(string: cluster), let rsaPubKey = self.rsaPublicKey else {
                SDKLogger.shared.debug("Request EphemeralKey failed")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            let requestId = UUID().uuidString
            let ecdhe = clusterURI.appendingPathComponent("ecdhe").absoluteString
            guard let request = try? KmsEphemeralKeyRequest(requestId: requestId, clientId: deviceUrl, userId: userUUID, bearer: token, method: "create", uri: ecdhe, kmsStaticKey: rsaPubKey),
                  let message = request.message else {
                SDKLogger.shared.debug("Request EphemeralKey failed, illegal ephemeral key request")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            self.ephemeralKeyRequest = (request: request, callback: completionHandler)
            Service.kms.homed(for: self.device)
                    .authenticator(self.authenticator)
                    .path("kms").path("messages").method(.post).headers(["Cisco-Request-ID": requestId]).body(["kmsMessages": message, "destination": cluster])
                    .build().responseString { (response: ServiceResponse<String>) in
                        SDKLogger.shared.debug("Request EphemeralKey Response ============ \(response.result)")
                        switch response.result {
                        case .success(_):
                            break
                        case .failure(_):
                            self.ephemeralKeyRequest = nil
                            completionHandler(MSGError.ephemaralKeyFetchFail)
                            break
                        }
                    }
        }
    }

    private func doSomethingAfterRegistered(block: @escaping (Error?) -> Void) {
        self.queue.sync {
            if self.phone.connected {
                self.queue.yield()
                block(nil)
            } else {
                self.phone.register { error in
                    self.queue.yield()
                    block(error)
                }
            }
        }
    }

    private func encryptionKey(convUrl: String) -> EncryptionKey {
        var key = self.encryptionKeys[convUrl]
        if key == nil {
            key = EncryptionKey(convUrl: convUrl)
            self.encryptionKeys[convUrl] = key
        }
        return key!
    }

    private func getOrCreateConversationWithPerson(person: String, queue: DispatchQueue?, completionHandler: @escaping (Result<(convUrl: String, convId: String)>) -> Void) {
        if let pair = self.conversations[person] {
            (queue ?? DispatchQueue.main).async {
                completionHandler(Result.success(pair))
            }
        } else {
            let request = Service.conv.homed(for: self.device)
                    .authenticator(self.authenticator)
                    .method(.put)
                    .path("conversations").path("user").path(person)
                    .query(["activitiesLimit": 0, "compact": true])
                    .queue(queue)
                    .build()
            request.responseObject { (response: ServiceResponse<ConversationModel>) in
                if let uuid = response.result.data?.id, let url = response.result.data?.url {
                    let pair = (convUrl: url, convId: uuid)
                    self.conversations[person] = pair
                    completionHandler(Result.success(pair))
                } else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.spaceFetchFail))
                }
            }
        }
    }

    // MARK: cache messages for update activities
    func cacheMessageIfNeeded(message: Message) -> Message {
        if (message.created ?? Date()).timeIntervalSinceNow <= 3 * 60 && message.isMissingThumbnail {
            if let contentId = message.activity.object?.id, let messageId = message.id {
                DispatchQueue.main.async {
                    self.cachedMessages[contentId] = messageId
                    SDKLogger.shared.debug("Cache a transcode message, messageId: \(messageId)")
                }
            }
        }
        return message
    }

    // MARK: - Deprecated

    /// Posts a message with optional file attachments to a user by email address.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// - parameter personEmail: The email address of the user to whom the message is to be posted.
    /// - parameter content: The content of message to be posted to the user. The content can be plain text, html, or markdown.
    /// - parameter files: Local files to be uploaded with the message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 1.4.0
    @available(*, deprecated)
    public func post(personEmail: EmailAddress,
                     text: String? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(text?.toTextObject, toPersonEmail: personEmail, withFiles: files, queue: queue, completionHandler: completionHandler)
    }

    /// Posts a message with optional file attachments to a user by id.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// - parameter personId: The id of the user to whom the message is to be posted.
    /// - parameter text: The content message to be posted to the user. The content can be plain text, html, or markdown.
    /// - parameter files: Local files to be attached to the message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 1.4.0
    @available(*, deprecated)
    public func post(personId: String,
                     text: String? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(text?.toTextObject, toPerson: personId, withFiles: files, queue: queue, completionHandler: completionHandler)
    }

    /// Posts a message with optional file attachments to a space by spaceId.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// To notify specific person or everyone in a space, mentions should be used.
    /// Having <code>@johndoe</code> in the content of the message does not generate notification.
    ///
    /// - parameter spaceId: The identifier of the space where the message is to be posted.
    /// - parameter text: The content message to be posted to the space. The content can be plain text, html, or markdown.
    /// - parameter mentions: Notify these mentions.
    /// - parameter files: Local files to be uploaded to the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 1.4.0
    @available(*, deprecated)
    public func post(spaceId: String,
                     text: String? = nil,
                     mentions: [Mention]? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(text?.toTextObject, toSpace: spaceId, mentions: mentions, withFiles: files, queue: queue, completionHandler: completionHandler)
    }
}

fileprivate extension String {

    var toTextObject: Message.Text {
        return Message.Text.html(html: self, plain: self)
    }

}
