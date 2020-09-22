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

/// The struct of a membership event
///
/// - since: 2.3.0
public enum MembershipEvent {
    // The event when a user is added to a space.
    case created(Membership)
    // The event when a user is removed from a space.
    case deleted(Membership)
    // The event when a membership's properties changed.
    case update(Membership)
    /// The event when a membership has sent a read receipt.
    case messageSeen(Membership, lastSeenMessage: String)
}

/// Membership contents.
///
/// - since: 1.2.0
public struct Membership {
    
    /// The id of this membership.
    ///
    /// - since: 1.2.0
    public var id: String?
    
    /// The id of the person.
    ///
    /// - since: 1.2.0
    public var personId: String?
    
    /// The email address of the person.
    ///
    /// - since: 1.2.0
    public var personEmail: EmailAddress?
    
    /// The id of the space.
    ///
    /// - since: 1.2.0
    public var spaceId: String?
    
    /// Whether this member is a moderator of the space in this membership.
    ///
    /// - since: 1.2.0
    public var isModerator: Bool?
    
    /// Whether this member is a monitor of the space in this membership.
    ///
    /// - since: 1.2.0
    @available(*, deprecated)
    public var isMonitor: Bool?
    
    /// The timestamp that the membership being created.
    ///
    /// - since: 1.2.0
    public var created: Date?
    
    /// The display name of the person
    ///
    /// - since: 1.4.0
    public var personDisplayName : String?
    
    /// The personOrgId name of the person
    ///
    /// - since: 1.4.0
    public var personOrgId : String?
    
}

extension Membership : Mappable {
    
    /// Membership constructor.
    ///
    /// - note: for internal use only.
    public init?(map: Map){
    }
    
    /// Membership mapping from JSON.
    ///
    /// - note: for internal use only.
    public mutating func mapping(map: Map) {
        id <- map["id"]
        personId <- map["personId"]
        personEmail <- (map["personEmail"], EmailTransform())
        if map.JSON["spaceId"] == nil {
            spaceId <- map["roomId"]
        }
        else {
            spaceId <- map["spaceId"]
        }
        isModerator <- map["isModerator"]
        isMonitor <- map["isMonitor"]
        created <- (map["created"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        personDisplayName <- map["personDisplayName"]
        personOrgId <- map["personOrgId"]
    }
}

extension Membership {

    init(conv: ConversationModel, person: PersonModel, clusterId: String?) {
        if let convId = conv.id, let personId = person.id {
            self.id = WebexId(type: .membership, cluster: clusterId, uuid: "\(personId):\(convId)").base64Id
            self.spaceId = WebexId(type: .room, cluster: clusterId, uuid: convId).base64Id
            self.personId = WebexId(type: .people, cluster: clusterId, uuid: personId).base64Id
        }
        if let orgId = person.orgId {
            self.personOrgId = WebexId(type: .organization, cluster: WebexId.DEFAULT_CLUSTER_ID, uuid: orgId).base64Id
        }
        self.personEmail = EmailAddress.fromString(person.emailAddress)
        self.personDisplayName = person.displayName
        self.isModerator = person.roomProperties?.isModerator
        self.isMonitor = self.isModerator
        self.created = person.published
    }

    init(activity: ActivityModel, clusterId: String?) {
        var person: PersonModel?
        if activity.verb == .acknowledge {
            person = activity.actor
        }
        else if activity.object is PersonModel {
            person = activity.object as? PersonModel
        }
        if let person = person, let convId = activity.target?.id, let personId = person.id {
            self.id = WebexId(type: .membership, cluster: clusterId, uuid: "\(personId):\(convId)").base64Id
            self.spaceId = WebexId(type: .room, cluster: clusterId, uuid: convId).base64Id
            self.personId = WebexId(type: .people, cluster: clusterId, uuid: personId).base64Id
        }
        if let orgId = person?.orgId {
            self.personOrgId = WebexId(type: .organization, cluster: WebexId.DEFAULT_CLUSTER_ID, uuid: orgId).base64Id
        }
        self.personEmail = EmailAddress.fromString(person?.emailAddress)
        self.personDisplayName = person?.displayName
        self.isModerator = person?.roomProperties?.isModerator
        self.isMonitor = self.isModerator
        self.created = activity.published
    }

}

/// The read status of the membership for space.
///
/// - since: 2.3.0
public struct MembershipReadStatus {

    /// The membership of the space
    public var member: Membership
    
    /// The id of the last message which the member have read
    public var lastSeenId: String?
    
    /// The last date and time the member have read messages
    public var lastSeenDate: Date?

    init(conv: ConversationModel, person: PersonModel, clusterId: String?) {
        self.member = Membership(conv: conv, person: person, clusterId: clusterId)
        if let lastSeenActivityUUID = person.roomProperties?.lastSeenActivityUUID {
            self.lastSeenId = WebexId(type: .message, cluster: clusterId, uuid: lastSeenActivityUUID).base64Id
        }
        self.lastSeenDate = person.roomProperties?.lastSeenActivityDate
    }

}
