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

class DeviceClient {
    
    private let authenticator: Authenticator

    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }
    
    func create(wdmUrl: String, deviceInfo: [String: Any], queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<DeviceModel>) -> Void) {
        let request = ServiceRequest.make(wdmUrl)
            .authenticator(self.authenticator)
            .method(.post)
            .path("devices")
            .body(deviceInfo)
            .headers(["x-catalog-version2": "true"])
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    func update(deviceUrl: String, deviceInfo: [String: Any], queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<DeviceModel>) -> Void) {
        let request = ServiceRequest.make(deviceUrl)
            .authenticator(self.authenticator)
            .method(.put)
            .body(deviceInfo)
            .headers(["x-catalog-version2": "true"])
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    func delete(deviceUrl: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.make(deviceUrl)
            .authenticator(self.authenticator)
            .method(.delete)
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
    func fetchRegion(queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<RegionModel>) -> Void) {
        let request = Service.region.global
            .authenticator(self.authenticator)
            .method(.get)
            .path("region")
            .headers(["Content-Type": "application/json"])
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }

    func fetchClusters(queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<ServicesClusterModel>) -> Void) {
        let request = Service.u2c.global
                .authenticator(self.authenticator)
                .method(.get)
                .path("catalog")
                .query(["format": "serviceList", "services": "identityLookup"])
                .queue(queue)
                .build()

        request.responseObject(completionHandler)
    }
    
    func fetchHosts(queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<ServiceHostModel>) -> Void) {
        let request = Service.u2c.global
            .authenticator(self.authenticator)
            .method(.get)
            .path("user/catalog")
            .query(["format": "hostMap"])
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
}
