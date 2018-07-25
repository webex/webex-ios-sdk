// Copyright 2016-2018 Cisco Systems Inc
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

/// The enumeration of Before types in Webex Message Client.
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

/// An iOS client wrapper of the Cisco Webex Message APIs.
///
/// - since: 1.4.0
public class MessageClient {
    
    /// Callback when receive Message.
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
    /// If present, it includes the associated media content attachment for each message.
    /// The list sorts the messages in descending order by creation date.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter before: If not nil, only list messages sent only before this condition.
    /// - parameter max: Limit the maximum number of messages in the response, default is 50.
    /// - parameter mentionedPeople: List messages where the caller is mentioned by using Mention.person("me").
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Posts a plain text message, optionally a media content attachment, to a space by user email.
    ///
    /// - parameter personEmail: The EmailAddress of the user to whom the message is to be posted.
    /// - parameter content: The plain text message to be posted to the space.
    /// - parameter files: Local file objects to be uploaded to the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Posts a plain text message, optionally a media content attachment, to a space by person id.
    ///
    /// - parameter personId: The personId of the user to whom the message is to be posted.
    /// - parameter text: The plain text message to be posted to the space.
    /// - parameter files: Local file objects to be uploaded to the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Posts a plain text message, optionally a media content attachment, to a space by spaceId.
    ///
    /// - parameter spaceId: The identifier of the space where the message is to be posted.
    /// - parameter text: The plain text message to be posted to the space.
    /// - parameter mentions: The mention items to be posted to the space.
    /// - parameter files: Local file objects to be uploaded to the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Detail of one message.
    ///
    /// - parameter messageID: The identifier of the message.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Deletes a message to a space by messageId.
    ///
    /// - parameter messageId: The messageId to be deleted in the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
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
    
    /// Download a file object, save the file to pointed destination.
    ///
    /// - parameter file: The RemoteFile object need to be downloaded.
    /// - parameter to: The local file directory for saving dwonloaded file.
    /// - parameter progressHandler: The download progress indicator.
    /// - parameter completionHandler: Downloaded file local address wiil be stored in "file.localFileUrl"
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
    
    /// Download a file object, save the file thumbnail.
    ///
    /// - parameter file: The RemoteFile object need to be downloaded.
    /// - parameter to: The local file directory for saving file after download.
    /// - parameter progressHandler: The download progress indicator.
    /// - parameter completionHandler: Downloaded file local address wiil be stored in "file.localFileUrl"
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


