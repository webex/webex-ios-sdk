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

struct ClientEventMediaCapabilities: Mappable {
    private(set) var transmitCapability: ClientEventMediaCapability?
    private(set) var receiveCapability: ClientEventMediaCapability?
    
    init(transmitCapability: ClientEventMediaCapability, receiveCapability: ClientEventMediaCapability) {
        self.transmitCapability = transmitCapability
        self.receiveCapability = receiveCapability
    }
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.transmitCapability <- map["tx"]
        self.receiveCapability <- map["rx"]
    }
}

struct ClientEventMediaCapability: Mappable {
    private(set) var audio: Bool?
    private(set) var video: Bool?
    private(set) var share: Bool?
    private(set) var shareAudio: Bool?
    private(set) var whiteboard: Bool?
    
    init(audio: Bool, video: Bool, share: Bool, shareAudio: Bool, whiteboard: Bool) {
        self.audio = audio
        self.video = video
        self.share = share
        self.shareAudio = shareAudio
        self.whiteboard = whiteboard
    }
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.audio <- map["audio"]
        self.video <- map["video"]
        self.share <- map["share"]
        self.shareAudio <- map["shareAudio"]
        self.whiteboard <- map["whiteboard"]
    }
}
