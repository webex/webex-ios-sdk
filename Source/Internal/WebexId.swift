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

enum IdentityType : String {
    
    case room
    case people
    case message
    case membership
    case organization
    case content
    case team
    case unknown
    
    var name: String {
        return self.rawValue.uppercased()
    }
}

class WebexId: Equatable, Hashable {
    
    let uuid: String
    let type: IdentityType
    let cluster: String
    
    static func uuid(_ base64Id: String) -> String {
        return from(base64Id: base64Id)?.uuid ?? base64Id
    }
    
    static func from(base64Id: String) -> WebexId? {
        if let decode = base64Id.base64Decoded() {
            let ids = decode.components(separatedBy: "/")
            if let id = ids[safeIndex: ids.count - 1],
                let typeString = ids[safeIndex: ids.count - 2], let type = IdentityType(rawValue: typeString.lowercased()),
                let cluster = ids[safeIndex: ids.count - 3] {
                return WebexId(type:  type, uuid: id, cluster: cluster)
            }
        }
        return nil
    }
    
    var base64Id: String {
        return "ciscospark://\(self.cluster)/\(self.type.name)/\(self.uuid)".base64Encoded() ?? self.uuid
    }
    
    init?(type: IdentityType, uuid: String?, cluster: String = "us") {
        guard let uuid = uuid else {
            return nil
        }
        self.uuid = uuid
        self.type = type
        self.cluster = cluster
    }
    
    func `is`(_ type: IdentityType) -> Bool {
        return self.type == type
    }
    
    func belong(_ cluster: String) -> Bool {
        return self.cluster == cluster
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: WebexId, rhs: WebexId) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}
