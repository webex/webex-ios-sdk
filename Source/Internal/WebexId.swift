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

    static let DEFAULT_CLUSTER: String = "us"
    static let DEFAULT_CLUSTER_ID: String = "urn:TEAM:us-east-2_a"

    static func uuid(_ base64Id: String) -> String {
        return from(base64Id: base64Id)?.uuid ?? base64Id
    }
    
    static func from(base64Id: String) -> WebexId? {
        if let decode = base64Id.base64Decoded() {
            let ids = decode.components(separatedBy: "/")
            if let id = ids[safeIndex: ids.count - 1],
                let typeString = ids[safeIndex: ids.count - 2], let type = IdentityType(rawValue: typeString.lowercased()),
                let cluster = ids[safeIndex: ids.count - 3] {
                return WebexId(type: type, cluster: cluster, uuid: id)
            }
        }
        return nil
    }

    static func from(url: String, by: Device?) -> WebexId? {
        if url.hasPrefix("https://conv") {
            return WebexId(type: .room, cluster: by?.getClusterId(url: url), uuid: (url as NSString).lastPathComponent)
        }
        return nil
    }

    let uuid: String
    let type: IdentityType
    let cluster: String
    var clusterId: String {
        return self.cluster == WebexId.DEFAULT_CLUSTER ? WebexId.DEFAULT_CLUSTER_ID : self.cluster
    }

    var base64Id: String {
        return "ciscospark://\(self.cluster)/\(self.type.name)/\(self.uuid)".base64Encoded() ?? self.uuid
    }

    init(type: IdentityType, cluster: String?, uuid: String) {
        self.uuid = uuid
        self.type = type
        if let cluster = cluster, !cluster.isEmpty && cluster != WebexId.DEFAULT_CLUSTER_ID {
            self.cluster = cluster
        }
        else {
            self.cluster = WebexId.DEFAULT_CLUSTER
        }
    }

    func urlBy(device: Device?) -> String? {
        let id = "\(self.clusterId):identityLookup"
        let url = device?.getServiceClusterUrl(serviceClusterId: id) ?? Service.conv.baseUrl(for: device)
        if self.is(.room) {
            return "\(url)/conversations/\(self.uuid)"
        }
        else if self.is(.message) {
            return "\(url)/activities/\(self.uuid)"
        }
        else if self.is(.team) {
            return "\(url)/teams/\(self.uuid)"
        }
        return nil
    }
    
    func `is`(_ type: IdentityType) -> Bool {
        return self.type == type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: WebexId, rhs: WebexId) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}
