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

class Identifier: Equatable, Hashable {

    let id: WebexId
    var url: String?
    
    var uuid: String {
        return id.uuid
    }
    
    init?(base64Id: String) {
        if let id = WebexId.from(base64Id: base64Id) {
            self.id = id
        }
        else {
            return nil
        }
    }
    
    init(id: WebexId, url: String? = nil) {
        self.id = id
        self.url = url
    }
    
    func url(device: Device?) -> String {
        if self.url == nil {
            // TODO Find the cluster for the identifier instead of use home cluster always.
            if self.id.is(.room) {
                self.url = Service.conv.homed(for: device).path("conversations").path(self.uuid).url.absoluteString
            }
            else if self.id.is(.message) {
                self.url = Service.conv.homed(for: device).path("activities").path(self.uuid).url.absoluteString
            }
            else if self.id.is(.team) {
                self.url = Service.conv.homed(for: device).path("teams").path(self.uuid).url.absoluteString
            }
        }
        return self.url!
    }
    
    static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        if let lurl = lhs.url, let rurl = rhs.url {
            return lurl == rurl
        }
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        if let url = self.url {
            hasher.combine(url)
        }
        hasher.combine(id)
    }

}
