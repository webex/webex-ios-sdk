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

struct DiagnosticEvent: Mappable {
    
    static let sentTimeKeyPath = "originTime.sent"
    
    private(set) var eventId: String?
    private(set) var version: Int?
    private(set) var origin: DiagnosticOrigin?
    private(set) var originTime: DiagnosticOriginTime?
    private(set) var event: ClientEvent?
    
    init(eventId: UUID, version: Int?, origin: DiagnosticOrigin, originTime: DiagnosticOriginTime, event: ClientEvent) {
        self.eventId = eventId.uuidString
        self.version = version
        self.origin = origin
        self.originTime = originTime
        self.event = event
    }
    
    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.eventId <- map["eventId"]
        self.version <- map["version"]
        self.origin <- map["origin"]
        self.originTime <- map["originTime"]
        self.event <- map["event"]
    }
}
