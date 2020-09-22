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

class ConversationModel : ObjectModel {

    private let dateTransform = CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")

    private(set) var locusUrl: String?
    private(set) var defaultActivityEncryptionKeyUrl: String?
    private(set) var encryptionKeyUrl: String?
    private(set) var kmsResourceObjectUrl: String?
    private(set) var participants: ItemsModel<PersonModel>?
    private(set) var activities: ItemsModel<ActivityModel>?
    private(set) var tags: [String]?
    private(set) var lastReadableActivityDate: Date?
    private(set) var lastRelevantActivityDate: Date?
    private(set) var lastSeenActivityDate: Date?

    var isOneOnOne: Bool {
        return self.tags?.contains("ONE_ON_ONE") ?? false
    }

    var isLocked: Bool {
        return self.tags?.contains("LOCKED") ?? false
    }

    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        self.locusUrl <- map["locusUrl"]
        self.defaultActivityEncryptionKeyUrl <- map["defaultActivityEncryptionKeyUrl"]
        self.encryptionKeyUrl <- map["encryptionKeyUrl"]
        self.kmsResourceObjectUrl <- map["kmsResourceObjectUrl"]
        self.participants <- map["participants"]
        self.activities <- map["activities"]
        self.tags <- map["tags"]
        self.lastReadableActivityDate <- (map["lastReadableActivityDate"], dateTransform)
        self.lastRelevantActivityDate <- (map["lastRelevantActivityDate"], dateTransform)
        self.lastSeenActivityDate <- (map["lastSeenActivityDate"], dateTransform)
    }

}
