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
import ObjectMapper

struct SparkIdentifiers: Mappable {
    
    private(set) var locusUrl: String?
    private(set) var locusId: String?
    private(set) var locusStartTime: String?
    private(set) var locusSessionId: String?
    private(set) var correlationId: String?
    private(set) var trackingId: String?
    private(set) var deviceId: String?
    private(set) var userId: String?
    private(set) var orgId: String?
    
    init(locusUrl: String?, locusId: String?, locusStartTime: String?, locusSessionId: String?, correlationId: String, trackingId: String?, deviceId: String?, userId: String?, orgId: String?) {
        self.locusUrl = locusUrl
        self.locusId = locusId
        self.locusStartTime = locusStartTime
        self.locusSessionId = locusSessionId
        self.correlationId = correlationId
        self.trackingId = trackingId
        self.deviceId = deviceId
        self.userId = userId
        self.orgId = orgId
    }
    
    init(call: Call, device: Device?, person: Person?) {
        self.init(locusUrl: call.model.locusUrl,
                  locusId: call.model.locusId,
                  locusStartTime: call.model.fullState?.lastActive ?? call.connectedTime?.utc,
                  locusSessionId: nil,
                  correlationId: call.correlationId.uuidString,
                  trackingId: TrackingId.generator.next,
                  deviceId: device?.deviceModel.deviceIdentifier ?? "-",
                  userId: person?.id == nil ? nil : WebexId.uuid((person?.id)!),
                  orgId: person?.orgId == nil ? nil : WebexId.uuid((person?.orgId)!))
    }
        
    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.locusUrl <- map["locusUrl"]
        self.locusId <- map["locusId"]
        self.locusStartTime <- map["locusStartTime"]
        self.locusSessionId <- map["locusSessionId"]
        self.correlationId <- map["correlationId"]
        self.trackingId <- map["trackingId"]
        self.deviceId <- map["deviceId"]
        self.userId <- map["userId"]
        self.orgId <- map["orgId"]
    }
}

