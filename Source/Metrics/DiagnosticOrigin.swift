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

struct DiagnosticOriginTime: Mappable {
    
    private(set) var triggered: String?
    private(set) var sent: String?
    
    init(triggered: String, sent: String) {
        self.triggered = triggered
        self.sent = sent
    }

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.triggered <- map["triggered"]
        self.sent <- map["sent"]
    }
}

struct ClientInfo: Mappable {
    private(set) var clientType: String?
    private(set) var os: String?
    private(set) var osVersion: String?

    init(clientType: String, os: String, osVersion: String) {
        self.clientType = clientType
        self.os = os
        self.osVersion = osVersion
    }

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.clientType <- map["clientType"]
        self.os <- map["os"]
        self.osVersion <- map["osVersion"]
    }
}

enum DiagnosticOriginBuildType: String {
    case debug
    case test
    case prod
}

enum DiagnosticOriginNetworkType: String {
    case wifi
    case ethernet
    case cellular
    case unknown
}

struct DiagnosticOrigin: Mappable {

    private(set) var name: String? = "endpoint"
    private(set) var buildType: DiagnosticOriginBuildType? = .prod
    private(set) var userAgent: String?
    private(set) var networkType: DiagnosticOriginNetworkType?
    private(set) var localIpAddress: String?
    private(set) var usingProxy: Bool?
    private(set) var mediaEngineSoftwareVersion: String?
    private(set) var clientInfo: ClientInfo?
    
    init(userAgent: String,
         networkType: DiagnosticOriginNetworkType,
         localIpAddress: String?,
         usingProxy: Bool,
         mediaEngineSoftwareVersion: String?,
         clientInfo: ClientInfo) {
        self.userAgent = userAgent
        self.networkType = networkType
        self.localIpAddress = localIpAddress
        self.usingProxy = usingProxy
        self.mediaEngineSoftwareVersion = mediaEngineSoftwareVersion
        self.clientInfo = clientInfo
    }
    
    init?(map: Map) {}

    mutating func mapping(map: Map) {
        self.name <- map["name"]
        self.buildType <- map["buildType"]
        self.userAgent <- map["userAgent"]
        self.networkType <- map["networkType"]
        self.localIpAddress <- map["localIP"]
        self.usingProxy <- map["usingProxy"]
        self.mediaEngineSoftwareVersion <- map["mediaEngineSoftwareVersion"]
        self.clientInfo <- map["clientInfo"]
    }

}

