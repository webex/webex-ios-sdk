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

struct ClientEventMediaLine: Mappable {
    
    enum Direction: String {
        case sendrecv, sendonly, recvonly, inactive
    }

    enum Transport: String {
        case udp, tcp, xtls
    }

    enum Status: String {
        case succeeded = "succeeded"
        case inProgress = "in-progress"
        case failed = "failed"
    }

    enum FailureReason: String {
        case network, transport, rejected, timeout
    }
    
    private(set) var mediaType: ClientEventMediaType?
    private(set) var remoteIp: String?
    private(set) var remotePort: NSNumber?
    private(set) var localIp: String?
    private(set) var localPort: NSNumber?
    private(set) var transport: Transport?
    private(set) var direction: Direction?
    private(set) var status: Status?
    private(set) var failureReason: FailureReason?
    private(set) var clusterName: String?
    private(set) var sdpData: [String: Any]?
    private(set) var errorCode: NSNumber?
    
    init(mediaType: ClientEventMediaType?, remoteIp: String?, remotePort: NSNumber?, localIp: String?, localPort: NSNumber?, transport: Transport, direction: Direction, status: Status, failureReason: FailureReason, clusterName: String?, sdpData:  [String: Any]?, errorCode: NSNumber?) {
        self.mediaType = mediaType
        self.remoteIp = remoteIp
        self.remotePort = remotePort
        self.localIp = localIp
        self.localPort = localPort
        self.transport = transport
        self.direction = direction
        self.status = status
        self.failureReason = failureReason
        self.clusterName = clusterName
        self.sdpData = sdpData
        self.errorCode = errorCode
    }
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.mediaType <- map["mediaType"]
        self.remoteIp <- map["remoteIP"]
        self.remotePort <- map["remotePort"]
        self.localIp <- map["localIP"]
        self.localPort <- map["localPort"]
        self.transport <- map["protocol"]
        self.direction <- map["direction"]
        self.status <- map["status"]
        self.failureReason <- map["failureReason"]
        self.clusterName <- map["clusterName"]
        self.sdpData <- map["sdpData"]
        self.errorCode <- map["errorCode"]
    }
}
