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

/// A data type represents a Space at Cisco Webex cloud.
///
/// - note: Space has been renamed to Space in Cisco Webex.
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

