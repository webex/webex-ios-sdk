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

/// An iOS client wrapper of the Cisco Webex [Spaces REST API](https://developer.webex.com/resource-rooms.html) .
///
/// - since: 1.2.0
public class SpaceClient {
    
    /// The callback handler for incoming space events.
    ///
    /// - since: 2.3.0
    public var onEvent: ((SpaceEvent) -> Void)?
    
    /// The callback handler for incoming space events.
    /// 
    /// - since: 2.3.0
    public var onEventWithPayload: ((SpaceEvent, WebexEventPayload) -> Void)?
    
    let phone: Phone

    var authenticator: Authenticator {
        return self.phone.authenticator
    }
    
    init(phone: Phone) {
        self.phone = phone
    }
    
    private func requestBuilder() -> ServiceRequest.Builder {
        return ServiceRequest.Builder(authenticator, service: .hydra, device: phone.devices.device).path("rooms")
    }
    
    private func convServiceBuilder() -> ServiceRequest.Builder {
        return ServiceRequest.Builder(authenticator, service: .conv, device: phone.devices.device)
    }
    
    /// Lists all spaces where the authenticated user belongs.
    ///
    /// - parameter teamId: If not nil, only list the spaces that are associated with the team by team id.
    /// - parameter max: The maximum number of spaces in the response.
    /// - parameter type: If not nil, only list the spaces of this type. Otherwise all spaces are listed.
    /// - parameter sortBy: Sort results by spaceId(id), most recent activity(lastactivity), or most recently created(created).
    ///                     Possible values: id, lastactivity, created
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(teamId: String? = nil , max: Int? = nil, type: SpaceType? = nil, sortBy: SpaceSortType? = nil,queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Space]>) -> Void) {
        let request = requestBuilder()
            .method(.get)
            .query(RequestParameter(["teamId": teamId, "max": max, "type": type?.rawValue, "sortBy": sortBy?.rawValue]))
            .keyPath("items")
            .queue(queue)
            .build()
        
        request.responseArray(completionHandler)
    }
    
    /// Creates a space. The authenticated user is automatically added as a member of the space. See the Memberships API to learn how to add more people to the space.
    ///
    /// - parameter title: A user-friendly name for the space.
    /// - parameter teamId: If not nil, this space will be associated with the team by team id. Otherwise, this space is not associated with any team.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    /// - see: see MemebershipClient API
    public func create(title: String, teamId: String? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Space>) -> Void) {
        let request = requestBuilder()
            .method(.post)
            .body(RequestParameter(["title": title, "teamId": teamId]))
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Retrieves the details for a space by id.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func get(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Space>) -> Void) {
        let request = requestBuilder()
            .method(.get)
            .path(spaceId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Updates the details for a space by id.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter title: A user-friendly name for the space.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func update(spaceId: String, title: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Space>) -> Void) {
        let request = requestBuilder()
            .method(.put)
            .body(RequestParameter(["title": title]))
            .path(spaceId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Deletes a space by id.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func delete(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = requestBuilder()
            .method(.delete)
            .path(spaceId)
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
    /// Shows Webex meeting details for a space such as the SIP address, meeting URL, toll-free and toll dial-in numbers.
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func getMeetingInfo(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<SpaceMeetingInfo>) -> Void) {
        let request = requestBuilder()
            .path(spaceId)
            .path("meetingInfo")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Returns a SpaceReadStatus with the details about the date of the last
    /// activity in the space, and the date of current user last presence in the space.
    ///
    /// For spaces where lastActivityDate > lastSeenDate the space can be considered to be "unread"
    ///
    /// - parameter spaceId: The identifier of the space.
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func getWithReadStatus(spaceId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<SpaceReadStatus>) -> Void) {
        let request = self.convServiceBuilder()
            .path("conversations")
            .path(spaceId.locusFormat)
            .query(RequestParameter(forConversation: ["includeParticipants": false]))
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Returns a list of SpaceReadStatus with details about the date of the last
    /// activity in the space, and the date of current user last presence in the space. The
    /// list is sorted with this with most recent activity first.
    ///
    /// For spaces where lastActivityDate > lastSeenDate the space can be considered to be "unread"
    ///
    /// - parameter max: recommend that the parameter is limited between 1 and 100
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 2.3.0
    public func listWithReadStatus(max:UInt, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[SpaceReadStatus]>) -> Void) {
        let parameter: [String: Any] = ["participantsLimit": 0, "isActive": true, "conversationsLimit": max]
        let request = convServiceBuilder()
            .path("conversations")
            .query(RequestParameter(forConversation: parameter))
            .keyPath("items")
            .queue(queue)
            .build()
        
        request.responseArray { (response:ServiceResponse<[SpaceReadStatus]>) in
            switch response.result {
            case .success(let spaceInfoArray):
                let spaceInfos = spaceInfoArray.sorted(by: { (value1, value2) -> Bool in
                    guard let date1 = value1.lastActivityDate else {return false}
                    guard let date2 = value2.lastActivityDate else {return true}
                    return Double(date1.timeIntervalSince1970) > Double(date2.timeIntervalSince1970)
                })
                completionHandler(ServiceResponse(response.response, Result.success(spaceInfos)))
                
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }
}

extension SpaceClient {
    
    func handle(activity: ActivityModel) {
        guard let verb = activity.verb else {
            return
        }
        var event: SpaceEvent?
        var space = Space()
        if verb == ActivityModel.Verb.create {
            space.id = activity.objectUUID?.hydraFormat(for: .room)
            space.type = activity.objectTag
            space.isLocked = activity.objectLocked
            space.lastActivityTimestamp = activity.created
            event = SpaceEvent.create(space)
        } else if verb == ActivityModel.Verb.update {
            space.id = activity.targetId
            space.type = activity.targetTag
            space.isLocked = activity.targetLocked
            event = SpaceEvent.update(space)
        }
        if let event = event {
            self.onEvent?(event)
            self.onEventWithPayload?(event, WebexEventPayload(activity: activity, person: self.phone.me))
        }
    }
}

extension RequestParameter {
    
    init(forConversation parameters: [String: Any?] = [:]) {
        var defaultParams:[String: Any?] = ["uuidEntryFormat":true,
                                            "personRefresh":true,
                                            "activitiesLimit":0,
                                            "includeConvWithDeletedUserUUID":false]
        for (key, value) in parameters {
            defaultParams.updateValue(value, forKey: key)
        }

        self.init(defaultParams)
    }
}
