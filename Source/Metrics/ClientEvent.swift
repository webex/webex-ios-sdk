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

struct ClientEvent: Mappable {
    
    // Base
    private(set) var canProceed: Bool?
    private(set) var csi: Int?
    private(set) var eventData: [String: Any]?
    private(set) var identifiers: SparkIdentifiers?
    private(set) var labels: [String]?
    private(set) var mediaCapabilities: ClientEventMediaCapabilities?
    private(set) var mediaLines: [ClientEventMediaLine]?
    private(set) var mediaType: ClientEventMediaType?
    private(set) var state: String?
    
    // Client
    private(set) var dialedDomain: String?
    private(set) var displayLocation: ClientEventDisplayLocation?
    private(set) var errors: [ClientEventError]?
    private(set) var trigger: ClientEventTrigger?
    // private(set) var reachabilityStatus: ClientEventReachabilityStatus?
    // private(set) var recoveredBy: ClientEventRecoveredBy?
    
    // Media
    private(set) var intervals: [[String: Any]]?
    
    // Both
    private(set) var name: ClientEventName?

    init(name: ClientEventName,
         state: String?,
         identifiers: SparkIdentifiers,
         canProceed: Bool,
         mediaType: ClientEventMediaType?,
         csi: Int?,
         mediaCapabilities: ClientEventMediaCapabilities?,
         mediaLines: [ClientEventMediaLine]?,
         errors: [ClientEventError]?,
         trigger: ClientEventTrigger?,
         displayLocation: ClientEventDisplayLocation?,
         dialedDomain: String?,
         labels: [String]?,
         eventData: [String: Any]?,
         intervals: [[String: Any]]?) {
        
        self.name = name
        self.state = state
        self.identifiers = identifiers
        self.canProceed = canProceed
        self.mediaType = mediaType
        self.csi = csi
        self.mediaCapabilities = mediaCapabilities
        self.mediaLines = mediaLines
        self.errors = errors
        self.trigger = trigger
        self.displayLocation = displayLocation
        self.dialedDomain = dialedDomain
        self.labels = labels
        self.eventData = eventData
        self.intervals = intervals
    }

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.name <- map["name"]
        self.state <- map["state"]
        self.identifiers <- map["identifiers"]
        self.canProceed <- map["canProceed"]
        self.mediaType <- map["mediaType"]
        self.csi <- map["csi"]
        self.mediaLines <- map["mediaLines"]
        self.mediaCapabilities <- map["mediaCapabilities"]
        self.errors <- map["errors"]
        self.trigger <- map["trigger"]
        self.displayLocation <- map["displayLocation"]
        self.dialedDomain <- map["dialedDomain"]
        self.labels <- map["labels"]
        self.eventData <- map["eventData"]
        self.intervals <- map["intervals"]
    }
}
