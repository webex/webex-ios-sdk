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

struct DeviceModel : Mappable {
    
    private(set) var deviceUrlString: String?
    private(set) var deviceIdentifier: String?
    private(set) var deviceSettingsString: String?
    private var webSocketUrlString: String?
    private var serviceHostMap: ServiceHostModel?
    var deviceUrl: URL? {
        if let string = self.deviceUrlString {
            return URL(string: string)
        }
        return nil
    }
    
    var webSocketUrl: URL? {
        if let string = self.webSocketUrlString {
            return URL(string: string)
        }
        return nil
    }
    
    subscript(service name: String) -> String? {
        return self.serviceHostMap?.serviceLinks?[name]
    }
    
    init?(map: Map){
    }
    
    mutating func mapping(map: Map) {
        deviceUrlString <- map["url"]
        deviceIdentifier <- map["deviceIdentifier"]
        webSocketUrlString <- map["webSocketUrl"]
        deviceSettingsString <- map["deviceSettingsString"]
        serviceHostMap <- map["serviceHostMap"]
    }
}
