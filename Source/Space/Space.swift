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

/// The enumeration of the types of a space.
public enum SpaceType: String {
    /// 1-to-1 space between two people
    case direct  = "direct"
    /// Group space among multiple people
    case group = "group"
}

/// The enumeration of sorting result
/// - since: 1.4.0
public enum SpaceSortType: String{
    /// sort result by id
    case byId = "id"
    /// last active space comes first
    case byLastActivity = "lastactivity"
    /// last created space comes first
    case byCreated = "created"
}

/// The struct of a space event
/// - since: 2.3.0
public enum SpaceEvent {
    /// The callback when a new space was created.
    case create(Space)
    /// The callback when a space was changed (usually a rename).
    case update(Space)
}

/// A data type represents a Space at Cisco Webex cloud.
///
/// - since: 1.2.0
public struct Space {
    
    /// The identifier of this space.
    ///
    /// - since: 1.2.0
    public var id: String?
    
    /// The title of this space.
    ///
    /// - since: 1.2.0
    public var title: String?
    
    /// The type of this space.
    ///
    /// - since: 1.2.0
    public var type: SpaceType?
    
    /// Indicate if this space is locked.
    ///
    /// - since: 1.2.0
    public var isLocked: Bool?
    
    /// The timestamp that last activity of this space.
    ///
    /// - since: 1.3.0
    public var lastActivityTimestamp: Date?
    
    /// The timestamp that this space being created.
    ///
    /// - since: 1.2.0
    public var created: Date?
    
    /// The team Id that this space associated with.
    ///
    /// - since: 1.2.0
    public var teamId: String?
    
    /// The sipAddress that this space associated with.
    ///
    /// - since: 1.4.0
    public var sipAddress: String?
    
}

extension Space: Mappable {
    
    /// Constructs a `Space` object.
    ///
    /// - note: for internal use only.
    public init?(map: Map){
    }
    
    /// Maps a `Space` from JSON.
    ///
    /// - note: for internal use only.
    public mutating func mapping(map: Map) {
        id <- map["id"]
        title <- map["title"]
        type <- (map["type"], EnumTransform<SpaceType>())
        isLocked <- map["isLocked"]
        lastActivityTimestamp <- (map["lastActivity"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        created <- (map["created"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"))
        teamId <- map["teamId"]
        sipAddress <- map["sipAddress"]
    }
}

/// Read status about the date of last activity in the space and the date of current user last presence in the space.
///
/// For spaces where lastActivityDate > lastSeenDate the space can be considered to be "unread".
///
/// - since: 2.3.0
public struct SpaceReadStatus {
    
    /// The identifier of this space.
    public var id: String?
    
    /// The type of this space.
    public var type: SpaceType?
    
    /// The date of last activity in the space.
    public var lastActivityDate: Date?
    
    /// The date of the last message in the space that login user has read.
    public var lastSeenActivityDate: Date?

    init(model: ConversationModel, clusterId: String?) {
        self.id = WebexId(type: .room, cluster: clusterId, uuid: model.id!).base64Id
        self.type = model.isOneOnOne ? SpaceType.direct : SpaceType.group
        self.lastActivityDate = model.lastReadableActivityDate ?? model.lastRelevantActivityDate
        self.lastSeenActivityDate = model.lastSeenActivityDate ?? Date(timeIntervalSince1970: 0)
    }

}

/// The Webex meeting details for a space such as the SIP address, meeting URL, toll-free and toll dial-in numbers.
///
/// - since: 2.3.0
public struct SpaceMeetingInfo: Mappable {
    
    /// A unique identifier for the space.
    public var spaceId:String?
    
    /// The Webex meeting URL for the space.
    public var meetingLink:String?
    
    /// The SIP address for the space.
    public var sipAddress:String?
    
    /// The Webex meeting number for the space.
    public var meetingNumber:String?
    
    /// The toll-free PSTN number for the space.
    public var callInTollFreeNumber:String?
    
    /// The toll (local) PSTN number for the space.
    public var callInTollNumber:String?
    
    
    public init(map: Map) {
    }
    
    public mutating func mapping(map: Map) {
        if map.JSON["spaceId"] == nil {
            self.spaceId <- map["roomId"]
        }
        else {
            self.spaceId <- map["spaceId"]
        }
        self.meetingLink      <- map["meetingLink"]
        self.sipAddress       <- map["sipAddress"]
        self.meetingNumber    <- map["meetingNumber"]
        self.callInTollNumber <- map["callInTollNumber"]
        self.callInTollFreeNumber <- map["callInTollFreeNumber"]
    }
}
