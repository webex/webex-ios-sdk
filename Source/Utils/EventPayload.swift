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

/// The data representation of the resource that triggered the event.
///
/// - since: 2.2.0
public protocol WebexEvent {
}


public protocol EventData {

}

public enum EventType: String {
    case created, deleted, updated, seen
}

public enum EventResource: String {
    case memberships, messages, spaces
}

extension Membership: EventData {
    
}

extension Message: EventData {
    
}

extension Space: EventData {
    
}

/// The raw payload of the event.
///
/// - since: 2.2.0
public struct EventPayload {
    
    init(activity: ActivityModel?, person: Person?, data: EventData) {
        self.actorId = activity?.actorId
        self.createdBy = person?.id
        self.orgId = person?.orgId
        switch activity?.verb {
        case .add, .create, .post, .share:
            self.event = EventType.created
        case .leave, .delete:
            self.event = EventType.deleted
        case .assignModerator, .unassignModerator, .hide, .update:
            self.event = EventType.updated
        case .acknowledge:
            self.event = EventType.seen
        default:
            break
        }
        self.data = data
        switch data {
        case is Message:
            self.resource = EventResource.messages
        case is Membership:
            self.resource = EventResource.memberships
        case is Space:
            self.resource = EventResource.spaces
        default:
            break
        }
    }
    
    /// The personId of the user who caused the event to be sent
    public internal(set) var actorId: String?
    
    /// The personId of login user
    public internal(set) var createdBy: String?
    
    /// The organizationId of login user
    public internal(set) var orgId: String?
    
    /// The type of the event
    public internal(set) var event: EventType?
    
    /// The resource the event data is about.
    public internal(set) var resource: EventResource?
    
    public internal(set) var data: EventData?
    
    /// the current date on client
    public let created: Date = Date()
    
    /// default is "creator"
    public let ownedBy: String = "creator"
    
    /// default is "active"
    public let status: String = "active"

}
