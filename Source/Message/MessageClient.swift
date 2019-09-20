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
    
    /// The callback handler when receiving a message event.
    ///
    /// - since: 1.4.0
    public var onEvent: ((MessageEvent) -> Void)? {
        get {
            return self.phone.messages?.onEvent
        }
        set {
            self.phone.messages?.onEvent = newValue
        }
    }
    
    private let phone: Phone
    
    private let queue = SerialQueue()
    
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
            if let impl = self.phone.messages {
                impl.list(spaceId: spaceId, mentionedPeople: mentionedPeople, before: before, max: max, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
            }
        }
    }
    
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
    public func post(personEmail: EmailAddress,
                     text: String? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let impl = self.phone.messages {
                impl.post(person: personEmail.toString(), text: text, files: files, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
            }
        }
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
    public func post(personId: String,
                     text: String? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let impl = self.phone.messages {
                impl.post(person: personId, text: text, files: files, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
            }
        }
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
    public func post(spaceId: String,
                     text: String? = nil,
                     mentions: [Mention]? = nil,
                     files: [LocalFile]? = nil,
                     queue: DispatchQueue? = nil,
                     completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let impl = self.phone.messages {
                impl.post(spaceId: spaceId, text: text, mentions: mentions, files: files, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
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
            if let impl = self.phone.messages {
                impl.get(messageId: messageId, decrypt: true, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
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
            if let impl = self.phone.messages {
                impl.delete(messageId: messageId, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
            }
        }
    }
    
    /// Send read receipt when the login user read a message, let others know you have seen it
    ///
    /// - parameter spaceId: The identifier of the space where the message is.
    /// - parameter messageId: The identifier of the message which user read.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the delete readReceipt has finished.
    /// - returns: Void
    /// - since: 2.2.0
    public func markAsRead(spaceId:String, messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let impl = self.phone.messages {
                impl.markAsRead(spaceId: spaceId, messageId: messageId, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
                }
            }
        }
    }
    
    /// Send read receipt when the login user read all the messages in the space, let others know you have seen them
    ///
    /// - parameter messageId: The identifier of the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the delete readReceipt has finished.
    /// - returns: Void
    /// - since: 2.2.0
    public func markAsRead(spaceId:String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.doSomethingAfterRegistered { error in
            if let impl = self.phone.messages {
                impl.markAsRead(spaceId: spaceId, queue: queue, completionHandler: completionHandler)
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(error ?? WebexError.unregistered)))
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
            if let impl = self.phone.messages {
                impl.downloadFile(file, to: to, progressHandler: progressHandler, completionHandler: completionHandler)
            }
            else {
                (DispatchQueue.main).async {
                    completionHandler(Result.failure(error ?? WebexError.unregistered))
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
            if let impl = self.phone.messages {
                impl.downloadThumbnail(for: file, to: to, progressHandler: progressHandler, completionHandler: completionHandler)
            }
            else {
                (DispatchQueue.main).async {
                    completionHandler(Result.failure(error ?? WebexError.unregistered))
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
                completionHandler(Result.failure(response.error ?? MessageClientImpl.MSGError.downloadError))
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
}


