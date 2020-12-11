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

struct LocusInfoModel: Mappable {

    private(set) var globalMeetingId: String?
    private(set) var webExMeetingId: String?
    private(set) var webExMeetingName: String?
    private(set) var owner: String?
    private(set) var conversationUrl: String?
    private(set) var webexServiceType: String?
    private(set) var callInTollFreeNumber: String?
    private(set) var callInTollNumber:String?
    private(set) var isPmr: Bool?
    private(set) var meetingAvatarUrl: String?
    private(set) var topic:String?
    private(set) var sipUri:String?
    private(set) var tags: [String]?

    init?(map: Map) {
    }

    mutating func mapping(map: Map) {
        globalMeetingId <- map["globalMeetingId"]
        webExMeetingId <- map["webExMeetingId"]
        webExMeetingName <- map["webExMeetingName"]
        owner <- map["owner"]
        conversationUrl <- map["conversationUrl"]
        webexServiceType <- map["webexServiceType"]
        callInTollFreeNumber <- map["callInTollFreeNumber"]
        callInTollNumber <- map["callInTollNumber"]
        isPmr <- map["isPmr"]
        meetingAvatarUrl <- map["meetingAvatarUrl"]
        topic <- map["topic"]
        sipUri <- map["sipUri"]
        self.tags <- map["locusTags"]
    }
}
