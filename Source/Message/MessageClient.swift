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
    
    private var uuid: String = UUID().uuidString
    private var userId : String?
    private var kmsCluster: String?
    private var rsaPublicKey: String?
    private var ephemeralKey: String?
    private var keySerialization: String?
    
    private var ephemeralKeyRequest: (KmsEphemeralKeyRequest, (Error?) -> Void)?
    private var keyMaterialCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [String: [(Result<(String, String)>) -> Void]]()
    private var keysCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [String: [(Result<(String, String)>) -> Void]]()
    private var encryptionKeys: [String: EncryptionKey] = [String: EncryptionKey]()
    private var spaces: [String: String] = [String: String]()
    private typealias KeyHandler = (Result<(String, String)>) -> Void
    
    var authenticator: Authenticator {
        return self.phone.authenticator
    }
    
    var deviceUrl: String? {
        return self.phone.devices.device?.deviceUrl.absoluteString
    }
    
    init(phone: Phone) {
        self.phone = phone
    }
    
    private var messageServiceBuilder: ServiceRequest.Builder {
        return ServiceRequest.Builder(self.authenticator, service: .conv, device: phone.devices.device)
    }
    
    private var kmsServiceBuilder: ServiceRequest.Builder {
        return ServiceRequest.Builder(self.authenticator, service: .kms, device: phone.devices.device)
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
            }
            else {
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
                                }
                                else {
                                    self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: response.result.data?.created, max:max, result: [], completionHandler: completionHandler)
                                }
                        }
                        case .date(let date):
                            self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: date, max:max, result: [], completionHandler: completionHandler)
                    }
                }
                else {
                    self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: nil, max:max, result: [], completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func listBefore(spaceId: String, mentionedPeople: Mention? = nil, date: Date?, max: Int, result: [ActivityModel], queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Message]>) -> Void) {
        let requestMax = max * 2
        let dateKey = mentionedPeople == nil ? "maxDate" : "sinceDate"
        let request = self.messageServiceBuilder.path(mentionedPeople == nil ? "activities" : "mentions")
            .query(RequestParameter(["conversationId": spaceId.locusFormat, "limit": requestMax, dateKey: (date ?? Date()).iso8601String]))
            .keyPath("items")
            .queue(queue)
            .build()
        request.responseArray { (response: ServiceResponse<[ActivityModel]>) in
            switch response.result {
                case .success:
                    guard let responseValue = response.result.data else { return }
                    let result = result + responseValue.filter({$0.verb == ActivityModel.Verb.post || $0.verb == ActivityModel.Verb.share})
                    if result.count >= max || responseValue.count < requestMax {
                        let key = self.encryptionKey(spaceId: spaceId)
                        key.material(client: self) { material in
                            if let material = material.data {
                                let messages = result.prefix(max).map { $0.decrypt(key: material) }.map { Message(activity: $0) }
                                (queue ?? DispatchQueue.main).async {
                                    completionHandler(ServiceResponse(response.response, Result.success(messages)))
                                }
                            }
                            else {
                                (queue ?? DispatchQueue.main).async {
                                    completionHandler(ServiceResponse(response.response, Result.failure(material.error ?? MSGError.keyMaterialFetchFail)))
                                }
                            }
                        }
                    }
                    else {
                        self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: responseValue.last?.created, max:max, result: result, completionHandler: completionHandler)
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
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toPersonEmail: EmailAddress,
                     withFiles: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(person: toPersonEmail.toString(), text: text, files: withFiles, queue: queue, completionHandler: completionHandler)
    }
        
    /// Posts a message with optional file attachments to a user by id.
    ///
    /// The content of the message can be plain text, html, or markdown.
    ///
    /// - parameter toPerson: The id of the user to whom the message is to be posted.
    /// - parameter withFiles: Local files to be attached to the message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toPerson: String,
                     withFiles: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.post(person: toPerson, text: text, files: withFiles, queue: queue, completionHandler: completionHandler)
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
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the message is posted.
    /// - returns: Void
    /// - since: 2.3.0
    public func post(_ text: Message.Text? = nil,
                     toSpace: String,
                     mentions: [Mention]? = nil,
                     withFiles: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            }
            else {
                var plainText = text?.plain
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
                            mentionedPeople.append(["objectType": "person", "id": person.locusFormat])
                    }
                }
                object["mentions"] = ["items" : mentionedPeople]
                object["groupMentions"] = ["items" : mentionedGroup]
                
                var verb = ActivityModel.Verb.post
                let key = self.encryptionKey(spaceId: toSpace)
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
                        let target: [String: Any] = ["id": toSpace.locusFormat, "objectType": ObjectType.conversation.rawValue]
                        key.encryptionUrl(client: self) { encryptionUrl in
                            postMessageRequest(encryptionUrl: encryptionUrl, material: material,target: target)
                        }
                    }
                }
                
                func postMessageRequest(encryptionUrl: Result<String?>, material: Result<String>, target: [String: Any]){
                    if let url = encryptionUrl.data {
                        let body = RequestParameter(["verb": verb.rawValue, "encryptionKeyUrl": url, "object": object, "target": target, "clientTempId": "\(self.uuid):\(UUID().uuidString)", "kmsMessage": self.keySerialization ?? nil])
                        let request = self.messageServiceBuilder.path("activities")
                            .method(.post)
                            .body(body)
                            .queue(queue)
                            .build()
                        request.responseObject { (response: ServiceResponse<ActivityModel>) in
                            switch response.result{
                                case .success(let activity):
                                    completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity.decrypt(key: material.data)))))
                                case .failure(let error):
                                    completionHandler(ServiceResponse(response.response, Result.failure(error)))
                            }
                        }
                    }
                    else {
                        (queue ?? DispatchQueue.main).async {
                            completionHandler(ServiceResponse(nil, Result.failure(encryptionUrl.error ?? MSGError.encryptionUrlFetchFail)))
                        }
                    }
                }
            }
        }
    }
    
    private func post(person: String,
                      text: Message.Text? = nil,
                      files: [LocalFile]? = nil,
                      queue: DispatchQueue? = nil,
                      completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.lookupSpace(person: person, queue: queue) { result in
            if let spaceId = result.data {
                self.post(text, toSpace: spaceId, withFiles: files, queue: queue, completionHandler: completionHandler)
            }
            else {
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
            }
            else {
                self.get(messageId: messageId, decrypt: true, queue: queue, completionHandler: completionHandler)
            }
        }
    }
    
    private func get(messageId: String, decrypt: Bool, queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        let request = self.messageServiceBuilder.path("activities").path(messageId.locusFormat).queue(queue).build()
        request.responseObject { (response : ServiceResponse<ActivityModel>) in
            switch response.result {
                case .success(let activity):
                    if let spaceId = activity.targetId, decrypt {
                        let key = self.encryptionKey(spaceId: spaceId)
                        key.material(client: self) { material in
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity.decrypt(key: material.data)))))
                            }
                        }
                    }
                    else {
                        completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity))))
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
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            }
            else {
                let request = self.messageServiceBuilder.path("activities").path(messageId.locusFormat).queue(queue).build()
                request.responseObject { (response : ServiceResponse<ActivityModel>) in
                    switch response.result {
                        case .success(let activity):
                            if let spaceId = activity.targetId {
                                let object: [String: Any] = ["id": messageId.locusFormat, "objectType": ObjectType.activity.rawValue]
                                let target: [String: Any] = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                                let body = RequestParameter(["verb": ActivityModel.Verb.delete.rawValue, "object": object, "target": target])
                                let request = self.messageServiceBuilder.path("activities")
                                    .method(.post)
                                    .body(body)
                                    .queue(queue)
                                    .build()
                                request.responseJSON(completionHandler)
                            }
                            else {
                                (queue ?? DispatchQueue.main).async {
                                    completionHandler(ServiceResponse(response.response, Result.failure(response.result.error ?? MSGError.spaceFetchFail)))
                                }
                        }
                        case .failure(let error):
                            completionHandler(ServiceResponse(response.response, Result.failure(error)))
                            break
                    }
                }
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
    public func markAsRead(spaceId:String, messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            }
            else {
                let object = ["id": messageId.locusFormat, "objectType": ObjectType.activity.rawValue]
                let target = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                let body = RequestParameter(["objectType":ObjectType.activity.rawValue,
                                             "verb": ActivityModel.Verb.acknowledge.rawValue,
                                             "object": object,
                                             "target": target])
                let request = self.messageServiceBuilder
                    .path("activities")
                    .method(.post)
                    .body(body)
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
    public func markAsRead(spaceId:String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error)))
                }
            }
            else {
                self.list(spaceId: spaceId, max: 1, queue:queue) { (response) in
                    switch response.result {
                        case .success(let messages):
                            if let message = messages.first, let lastMessageId = message.id {
                                self.markAsRead(spaceId: spaceId, messageId: lastMessageId, queue: queue,  completionHandler: completionHandler)
                            }
                            else {
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
    public func downloadFile(_ file: RemoteFile, to: URL? = nil, progressHandler: ((Double)->Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(error))
                }
            }
            else {
                if let source = file.url {
                    let operation = DownloadFileOperation(authenticator: self.authenticator,
                                                          uuid: self.uuid,
                                                          source: source,
                                                          displayName: file.displayName,
                                                          secureContentRef: file.secureContentRef,
                                                          thnumnail: false,
                                                          target: to,
                                                          queue: nil,
                                                          progressHandler: progressHandler,
                                                          completionHandler: completionHandler)
                    operation.run()
                }
                else {
                    completionHandler(Result.failure(MSGError.downloadError))
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
    public func downloadThumbnail(for file: RemoteFile, to: URL? = nil, progressHandler: ((Double)->Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(error))
                }
            }
            else {
                if let source = file.thumbnail?.url {
                    let operation = DownloadFileOperation(authenticator: self.authenticator,
                                                          uuid: self.uuid,
                                                          source: source,
                                                          displayName: file.displayName,
                                                          secureContentRef: file.thumbnail?.secureContentRef,
                                                          thnumnail: true,
                                                          target: to,
                                                          queue: nil,
                                                          progressHandler: progressHandler,
                                                          completionHandler: completionHandler)
                    operation.run()
                }
                else {
                    completionHandler(Result.failure(MSGError.downloadError))
                }
            }
        }
    }
    
    private func download(from: String, completionHandler: @escaping (Result<LocalFile>) -> Void) {
        Alamofire.download(from, to: DownloadRequest.suggestedDownloadDestination()).response { response in
            if response.error == nil, let url = response.destinationURL, let file = LocalFile(path: url.path) {
                completionHandler(Result.success(file))
            }
            else {
                completionHandler(Result.failure(response.error ?? MSGError.downloadError))
            }
        }
    }
    
    // MARK: Encryption Feature Functions
    func handle(activity: ActivityModel) {
        guard let spaceId = activity.targetId else {
            SDKLogger.shared.error("Not a space message \(activity.uuid ?? (activity.toJSONString() ?? ""))")
            return
        }
        if let clientTempId = activity.clientTempId, clientTempId.starts(with: self.uuid) {
            return
        }
        let key = self.encryptionKey(spaceId: spaceId)
        if let encryptionUrl = activity.encryptionKeyUrl {
            key.tryRefresh(encryptionUrl: encryptionUrl)
        }
        key.material(client: self) { material in
            var decryption = activity.decrypt(key: material.data)
            guard let verb = decryption.verb else {
                SDKLogger.shared.error("Not a valid message \(activity.uuid ?? (activity.toJSONString() ?? ""))")
                return
            }
            DispatchQueue.main.async {
                switch verb {
                    case .post, .share:
                        decryption.toPersonId = self.userId?.hydraFormat(for: .people)
                        let message = Message(activity: decryption)
                        let event = MessageEvent.messageReceived(message)
                        self.onEvent?(event)
                        self.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.phone.me));
                    case .delete:
                        let message = Message(activity: decryption)
                        let event = MessageEvent.messageDeleted(message.id ?? "illegal id")
                        self.onEvent?(event)
                        self.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.phone.me));
                    default:
                        SDKLogger.shared.error("Not a valid message \(activity.uuid ?? (activity.toJSONString() ?? ""))")
                }
            }
        }
    }
    
    func handle(kms: KmsMessageModel) {
        if let response = kms.kmsMessages?.first {
            if let request = self.ephemeralKeyRequest {
                handleEphemeralKeyRequest(request: request, response: response)
            }
            else {
                handleSpaceKeyMaterialRequest(response: response)
            }
        }
    }
    
    private func handleEphemeralKeyRequest(request: (KmsEphemeralKeyRequest, (Error?) -> Void), response: String) {
        if let key = try? KmsEphemeralKeyResponse(responseMessage: response, request: request.0).jwkEphemeralKey {
            self.ephemeralKey = key
            request.1(nil)
        }
        else {
            request.1(MSGError.ephemaralKeyFetchFail)
        }
        self.ephemeralKeyRequest = nil
    }
    
    private func handleSpaceKeyMaterialRequest(response: String) {
        if let key = self.ephemeralKey, let data = try? CjoseWrapper.content(fromCiphertext: response, key: key), let json = try? JSON(data: data) {
            if let key = json["key"].object as? [String:Any] {
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
            }
            else if let dict = (json["keys"].object as? [[String : Any]])?.first {
                if let key = try? KmsKey(from: dict), let spaceId = self.keysCompletionHandlers.keys.first ,let handlers = self.keysCompletionHandlers.popFirst()?.value  {
                    self.updateConversationWithKey(key: key, spaceId: spaceId, handlers: handlers)
                }
            }
        }
    }
    
    func requestSpaceEncryptionURL(spaceId: String, completionHandler: @escaping (Result<String?>) -> Void) {
        self.prepareEncryptionKey { error in
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }
            
            func handleResourceObjectUrl(dict: [String: Any]) {
                if let paticipients = dict["participants"] as? [String: Any], let participantsArray = paticipients["items"] as? [[String: Any]]{
                    participantsArray.forEach{ pdict in
                        if let userId = pdict["entryUUID"] as? String{
                            if !self.encryptionKey(spaceId: spaceId).spaceUserIds.contains(userId){
                                self.encryptionKey(spaceId: spaceId).spaceUserIds.append(userId)
                            }
                        }
                    }
                }
                completionHandler(Result.success(nil))
            }
            
            let request = self.messageServiceBuilder.path("conversations").path(spaceId.locusFormat)
                .query(RequestParameter(["includeActivities": false, "includeParticipants": true]))
                .build()
            request.responseJSON { (response: ServiceResponse<Any>) in
                if let dict = response.result.data as? [String: Any] {
                    if let spaceEncryptionUrl = (dict["encryptionKeyUrl"] ?? dict["defaultActivityEncryptionKeyUrl"]) as? String{
                        completionHandler(Result.success(spaceEncryptionUrl))
                    }else if let _ = dict["kmsResourceObjectUrl"] {
                        handleResourceObjectUrl(dict: dict)
                    }
                }
                else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.encryptionUrlFetchFail))
                }
            }
        }
    }
    
    func requestSpaceKeyMaterial(spaceId: String, encryptionUrl: String?, completionHandler: @escaping (Result<(String, String)>) -> Void) {
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
                guard let userId = self.userId, let ephemeralKey = self.ephemeralKey else {
                    completionHandler(Result.failure(MSGError.ephemaralKeyFetchFail))
                    return
                }
                self.processSpaceKeyMaterialRequest(spaceId: spaceId, encryptionUrl: encryptionUrl, token: token, userId: userId, ephemeralKey: ephemeralKey, completionHandler: completionHandler)
            }
        }
    }
    
    private func processSpaceKeyMaterialRequest(spaceId: String, encryptionUrl: String?, token: String, userId: String, ephemeralKey: String?, completionHandler: @escaping (Result<(String, String)>) -> Void){
        let header: [String: String]  = ["Cisco-Request-ID": self.uuid, "Authorization": "Bearer " + token]
        var parameters: [String: Any]?
        var failed: () -> Void
        if let deviceUrl = self.deviceUrl, let encryptionUrl = encryptionUrl{
            if let request = try? KmsRequest(requestId: self.uuid, clientId: deviceUrl, userId: userId, bearer: token, method: "retrieve", uri: encryptionUrl),
                let serialize = request.serialize(),
                let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                self.keySerialization = chiperText
                parameters = ["kmsMessages": [chiperText], "destination": "unused" ] as [String : Any]
                var handlers: [(Result<(String, String)>) -> Void] = self.keyMaterialCompletionHandlers[encryptionUrl] ?? []
                handlers.append(completionHandler)
                self.keyMaterialCompletionHandlers[encryptionUrl] = handlers
            }
            failed = {
                self.keyMaterialCompletionHandlers[encryptionUrl]?.forEach { $0(Result.failure(MSGError.keyMaterialFetchFail)) }
                self.keyMaterialCompletionHandlers[encryptionUrl] = nil
            }
        }
        else {
            if let deviceUrl = self.deviceUrl, let request = try? KmsRequest(requestId: self.uuid, clientId: deviceUrl, userId: userId, bearer: token, method: "create", uri: "/keys") {
                request.additionalAttributes = ["count": 1]
                if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                    self.keySerialization = chiperText
                    parameters = ["kmsMessages": [chiperText], "destination": "unused" ] as [String: Any]
                    var handlers: [(Result<(String, String)>) -> Void] = self.keysCompletionHandlers[spaceId] ?? []
                    handlers.append(completionHandler)
                    self.keysCompletionHandlers[spaceId] = handlers
                }
            }
            failed = {
                self.keysCompletionHandlers[spaceId]?.forEach { $0(Result.failure(MSGError.keyMaterialFetchFail)) }
                self.keysCompletionHandlers[spaceId] = nil
            }
        }
        
        if let parameters = parameters, parameters.count >= 2 {
            Alamofire.request(URL(string: Service.kms.endpoint(for: phone.devices.device) + "/kms/messages")!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header).responseString { (response) in
                SDKLogger.shared.debug("RequestKMS Material Response ============  \(response)")
                if response.result.isFailure {
                    failed()
                }
            }
        }
        else {
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
        if self.userId != nil {
            completionHandler(nil)
            return
        }
        let request = self.messageServiceBuilder.path("users").build()
        request.responseJSON { (response: ServiceResponse<Any>) in
            if let usersDict = response.result.data as? [String: Any], let userId = usersDict["id"] as? String {
                self.userId = userId
                completionHandler(nil)
            }
            else {
                completionHandler(MSGError.clientInfoFetchFail)
            }
        }
    }
    
    private func requestClusterAndRSAPubKey(completionHandler: @escaping (Error?) -> Void) {
        if self.kmsCluster != nil && self.rsaPublicKey != nil {
            completionHandler(nil)
            return
        }
        let request = self.kmsServiceBuilder.path("kms").build()
        request.responseJSON { (response: ServiceResponse<Any>) in
            if let kmsDict = response.result.data as? [String: Any], let kmsCluster = kmsDict["kmsCluster"] as? String, let rsaPublicKey = kmsDict["rsaPublicKey"] as? String {
                self.kmsCluster = kmsCluster
                self.rsaPublicKey = rsaPublicKey
                completionHandler(nil)
            }
            else {
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
            guard let userId = self.userId, let cluster = self.kmsCluster, let clusterURI = URL(string: cluster), let rsaPubKey = self.rsaPublicKey else {
                SDKLogger.shared.debug("Request EphemeralKey failed")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            let ecdhe = clusterURI.appendingPathComponent("ecdhe").absoluteString
            guard let request = try? KmsEphemeralKeyRequest(requestId: self.uuid, clientId: deviceUrl , userId: userId, bearer: token , method: "create", uri: ecdhe, kmsStaticKey: rsaPubKey), let message = request.message else {
                SDKLogger.shared.debug("Request EphemeralKey failed, illegal ephemeral key request")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            self.ephemeralKeyRequest = (request, completionHandler)
            let parameters: [String: String] = ["kmsMessages": message, "destination": cluster]
            let header: [String: String]  = ["Cisco-Request-ID": self.uuid, "Authorization" : "Bearer " + token]
            Alamofire.request(URL(string: Service.kms.endpoint(for: self.phone.devices.device) + "/kms/messages")!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header).responseString { response in
                SDKLogger.shared.debug("Request EphemeralKey Response ============ \(response)")
                if response.result.isFailure {
                    self.ephemeralKeyRequest = nil
                    completionHandler(MSGError.ephemaralKeyFetchFail)
                }
            }
        }
    }
    
    private func updateConversationWithKey(key: KmsKey, spaceId: String, handlers: [KeyHandler]) {
        self.authenticator.accessToken{ token in
            let spaceUserIds = self.encryptionKey(spaceId: spaceId).spaceUserIds
            if let deviceUrl = self.deviceUrl, let request = try? KmsRequest(requestId: self.uuid, clientId: deviceUrl, userId: self.userId, bearer: token, method: "create", uri: "/resources") {
                request.additionalAttributes = ["keyUris":[key.uri],"userIds": spaceUserIds]
                if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: self.ephemeralKey) {
                    var object = [String: Any]()
                    object["objectType"] = ObjectType.conversation.rawValue
                    object["defaultActivityEncryptionKeyUrl"] = key.uri
                    let target: [String: Any] = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                    let verb = ActivityModel.Verb.updateKey
                    let body = RequestParameter(["objectType":"activity",
                                                 "verb": verb.rawValue,
                                                 "object": object,
                                                 "target": target,
                                                 "kmsMessage":chiperText])
                    let request = self.messageServiceBuilder.path("activities")
                        .method(.post)
                        .body(body)
                        .build()
                    request.responseJSON { (response: ServiceResponse<Any>) in
                        switch response.result {
                            case .success(_):
                                handlers.forEach { $0(Result.success((key.uri, key.jwk))) }
                            case .failure(let error):
                                handlers.forEach { $0(Result.failure(error)) }
                                break
                        }
                    }
                }
            }
        }
    }
    
    private func doSomethingAfterRegistered(block: @escaping (Error?) -> Void) {
        self.queue.sync {
            if self.phone.connected {
                self.queue.yield()
                block(nil)
            }
            else {
                self.phone.register { error in
                    self.queue.yield()
                    block(error)
                }
            }
        }
    }
    
    private func encryptionKey(spaceId: String) -> EncryptionKey {
        var key = self.encryptionKeys[spaceId]
        if key == nil {
            key = EncryptionKey(spaceId: spaceId)
            self.encryptionKeys[spaceId] = key
        }
        return key!
    }
    
    private func lookupSpace(person: String, queue: DispatchQueue?, completionHandler: @escaping (Result<String>) -> Void) {
        if let spaceId = self.spaces[person] {
            (queue ?? DispatchQueue.main).async {
                completionHandler(Result.success(spaceId))
            }
        }
        else {
            let request = self.messageServiceBuilder.path("conversations").path("user").path(person.locusFormat)
                .method(.put)
                .query(RequestParameter(["activitiesLimit": 0, "compact": true]))
                .queue(queue)
                .build()
            request.responseObject { (response: ServiceResponse<Space>) in
                if let space = response.result.data?.id {
                    let spaceId = space.hydraFormat(for: .room)
                    self.spaces[person] = spaceId
                    completionHandler(Result.success(spaceId))
                }
                else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.spaceFetchFail))
                }
            }
        }
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

extension Date {
    
    var iso8601String: String {
        return Timestamp.iSO8601FullFormatterInUTC.string(from: self.addingTimeInterval(-0.1))
    }
    
    static func fromISO860(_ string: String) -> Date? {
        return  Timestamp.iSO8601FullFormatterInUTC.date(from:string)
    }
}

extension String {
    
    var toTextObject: Message.Text {
        return Message.Text.html(html: self, plain: self)
    }
    
}
