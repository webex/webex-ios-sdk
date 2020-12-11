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

/// An iOS client wrapper of the Cisco Webex [Space Memberships REST API](https://developer.webex.com/docs/api/v1/memberships) .
///
/// - since: 1.2.0
public class MembershipClient {
    
    /// The callback to receive events about membership changes
    ///
    /// - since: 2.3.0
    public var onEvent: ((MembershipEvent) -> Void)?

    /// The callback to receive events with the event payload about membership changes.
    ///
    /// - since: 2.3.0
    public var onEventWithPayload: ((MembershipEvent, WebexEventPayload) -> Void)?
    
    private let phone: Phone
    private let messages: MessageClient

    init(phone: Phone, messages: MessageClient) {
        self.phone = phone
        self.messages = messages
    }
    
    private func hydraReqeust() -> ServiceRequest.Builder {
        return Service.hydra.global.authenticator(self.phone.authenticator).path("memberships")
    }
        
    /// Lists all space memberships where the authenticated user belongs.
    ///
    /// - parameter max: The maximum number of items in the response.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(max: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: nil, personId: nil, personEmail: nil, max: max, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists all memberships in the given space by space Id.
    ///
    /// - parameter spaceId: The identifier of the space where the membership belongs.
    /// - parameter max: The maximum number of memberships in the response.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, max: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: nil, personEmail: nil, max: max, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists any space memberships for the given space (by space id) and person (by person id).
    ///
    /// - parameter spaceId: The identifier of the space where the memberships belong.
    /// - parameter personId: The identifier of the person who has the memberships.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, personId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: personId, personEmail: nil, max: nil, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists any space memberships for the given space (by space id) and person (by email address).
    ///
    /// - parameter spaceId: The identifier of the space where the memberships belong.
    /// - parameter personEmail: The email address of the person who has the memberships.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, personEmail: EmailAddress, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: nil, personEmail: personEmail, max: nil, queue: queue, completionHandler: completionHandler)
    }
    
    private func list(spaceId: String?, personId: String?, personEmail: EmailAddress?, max: Int?, queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        let request = hydraReqeust()
            .method(.get)
            .query(["spaceId": spaceId, "roomId": spaceId, "personId": personId, "personEmail": personEmail?.toString(), "max": max])
            .keyPath("items")
            .queue(queue)
            .build()
        
        request.responseArray(completionHandler)
    }
    
    /// Adds a person to a space by person id; optionally making the person a moderator.
    ///
    /// - parameter spaceId: The identifier of the space where the person is to be added.
    /// - parameter personId: The identifier of the person to be added.
    /// - parameter isModerator: If true, make the person a moderator of the space. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func create(spaceId: String, personId: String, isModerator: Bool = false, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = hydraReqeust()
                .method(.post)
                .body(["spaceId": spaceId, "roomId": spaceId, "personId": personId, "isModerator": isModerator])
                .queue(queue)
                .build()

        request.responseObject(completionHandler)
    }

    /// Adds a person to a space by email address; optionally making the person a moderator.
    ///
    /// - parameter spaceId: The identifier of the space where the person is to be added.
    /// - parameter personEmail: The email address of the person to be added.
    /// - parameter isModerator: If true, make the person a moderator of the space. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func create(spaceId: String, personEmail: EmailAddress, isModerator: Bool = false, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = hydraReqeust()
                .method(.post)
                .queue(queue)
                .body(["spaceId": spaceId, "roomId": spaceId, "personEmail": personEmail.toString(), "isModerator": isModerator])
                .build()

        request.responseObject(completionHandler)
    }
    
    /// Retrieves the details for a membership by membership id.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func get(membershipId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = hydraReqeust()
            .method(.get)
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Updates the properties of a membership by membership id.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter isModerator: If true, make the person a moderator of the space in this membership. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func update(membershipId: String, isModerator: Bool, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = hydraReqeust()
            .method(.put)
            .body(["isModerator": isModerator])
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Deletes a membership by membership id. It removes the person from the space where the membership belongs.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func delete(membershipId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = hydraReqeust()
            .method(.delete)
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
    /// Returns a list of memberships with details about the lastSeenId for each user so that application can tell
    /// which message was the last message was read by each user.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func listWithReadStatus(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[MembershipReadStatus]>) -> Void) {
        // TODO additionalUrls
        guard let conversation = WebexId.from(base64Id: spaceId), conversation.is(.room), let convUrl = conversation.urlBy(device: self.phone.devices.device) else {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.failure(WebexError.illegalOperation(reason: "Cannot found the space: \(spaceId)"))))
            }
            return
        }
        let request = ServiceRequest.make(convUrl)
                .authenticator(self.phone.authenticator)
                .query(["uuidEntryFormat": true, "personRefresh": true, "activitiesLimit": 0, "includeConvWithDeletedUserUUID": false, "participantAckFilter": "all"])
                .queue(queue)
                .build()

        request.responseObject { (response: ServiceResponse<ConversationModel>) in
            switch response.result {
            case .success(let conv):
                let statuses = conv.participants?.items?.map( { MembershipReadStatus(conv: conv, person: $0, clusterId: conversation.clusterId) }) ?? []
                completionHandler(ServiceResponse(response.response, Result.success(statuses)))
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }
}
