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

struct Device {
    let phone: Phone
    let deviceType:String = UIDevice.current.kind
    let deviceModel: DeviceModel
    let regionModel: RegionModel
    
    var deviceUrl: URL { return deviceModel.deviceUrl! }
    var webSocketUrl: URL { return deviceModel.webSocketUrl! }
    var countryCode: String { return regionModel.countryCode! }
    var regionCode: String { return regionModel.regionCode! }
    
    subscript(service name: String) -> String? {
        return self.deviceModel[service: name]
    }
}

class DeviceService {
    
    private let client: DeviceClient
    
    init(authenticator: Authenticator) {
        client = DeviceClient(authenticator: authenticator)
    }

    var device: Device?
    
    func registerDevice(phone: Phone, queue: DispatchQueue, completionHandler: @escaping (Result<Device>) -> Void) {
        self.client.fetchRegion(queue: queue) { regionRes in
            var region = regionRes.result.data ?? RegionModel()
            if region.regionCode == nil {
                region.regionCode = "US-WEST"
            }
            if region.countryCode == nil {
                region.countryCode = "US"
            }
            
            let registrationHandler: (ServiceResponse<DeviceModel>) -> Void = { response in
                switch response.result {
                case .success(let model):
                    if let _ = model.deviceUrl, let _ = model.webSocketUrl {
                        self.device = Device(phone: phone, deviceModel: model, regionModel: region)
                        UserDefaults.sharedInstance.deviceUrl = model.deviceUrlString
                        UserDefaults.sharedInstance.deviceIdentifier = model.deviceIdentifier
                        completionHandler(Result.success(self.device!))
                    } else {
                        let error = WebexError.serviceFailed(code: -7000, reason: "Missing required URLs when registering device")
                        SDKLogger.shared.error("Failed to register device", error: error)
                        completionHandler(Result.failure(error))
                    }
                case .failure(let error):
                    SDKLogger.shared.error("Failed to register device", error: error)
                    completionHandler(Result.failure(error))
                }
            }
            
            let deviceInfo: [String: Any] = [
                "deviceName": UIDevice.current.name.isEmpty ? "notset" : UIDevice.current.name,
                "name": UIDevice.current.name.isEmpty ? "notset" : UIDevice.current.name,
                "model": UIDevice.current.model,
                "localizedModel": UIDevice.current.localizedModel,
                "systemName": UIDevice.current.systemName,
                "systemVersion": UIDevice.current.systemVersion,
                "deviceType": UIDevice.current.kind,
                "deviceIdentifier": UserDefaults.sharedInstance.deviceIdentifier ?? UUID().uuidString,
                "countryCode": region.countryCode!,
                "regionCode": region.regionCode!,
                "ttl": String(180*24*3600),
                "capabilities": ["sdpSupported":true, "groupCallSupported":true]
            ]
            if let deviceUrl = UserDefaults.sharedInstance.deviceUrl {
                self.client.update(url: deviceUrl, deviceInfo: deviceInfo, queue: queue, completionHandler: registrationHandler)
            }
            else {
                self.client.fetchHosts(queue: queue) { hostsRes in
                    // TDOO handle u2c error
                    self.client.create(deviceInfo: deviceInfo, hosts: hostsRes.result.data, queue: queue, completionHandler: registrationHandler)
                }
            }
        }
    }
    
    func deregisterDevice(queue: DispatchQueue, completionHandler: @escaping (Error?) -> Void) {
        if let deviceUrl = UserDefaults.sharedInstance.deviceUrl {
            self.client.delete(url: deviceUrl, queue: queue) { (response: ServiceResponse<Any>) in
                switch response.result {
                case .success:
                    completionHandler(nil)
                case .failure(let error):
                    SDKLogger.shared.error("Failed to deregister device", error: error)
                    completionHandler(error)
                }
            }
            UserDefaults.sharedInstance.deviceUrl = nil
            UserDefaults.sharedInstance.deviceIdentifier = nil
        } else {
            completionHandler(nil)
        }
        self.device = nil
    }
}

extension UIDevice {
    
    var kind: String {

        if self.userInterfaceIdiom == .pad {
            return "IPAD"
        } else if self.userInterfaceIdiom == .phone {
            return "IPHONE"
        } else {
            return "UNKNOWN"
        }
    }
    
}

