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
    let deviceType:String = DeviceService.Types.ios_sdk.rawValue
    let deviceModel: DeviceModel
    let regionModel: RegionModel
    let clusterUrls: [String: String]
    
    var deviceUrl: URL { return deviceModel.deviceUrl! }
    var webSocketUrl: URL { return deviceModel.webSocketUrl! }
    var deviceSettings: String? { return deviceModel.deviceSettingsString }
    var countryCode: String { return regionModel.countryCode! }
    var regionCode: String { return regionModel.regionCode! }
    
    subscript(service name: String) -> String? {
        return self.deviceModel[service: name]
    }

    // urn:TEAM:us-west-2_r:identityLookup, https://conv-r.wbx2.com/conversation/api/v1
    func getServiceClusterUrl(serviceClusterId: String) -> String? {
        return self.clusterUrls[serviceClusterId]
    }

    func getIdentityServiceClusterUrl(urn: String) -> String {
        return self.getServiceClusterUrl(serviceClusterId: "\(urn):identityLookup") ?? Service.conv.baseUrl(for: self)
    }

    func getClusterId(url: String?) -> String? {
        if let url = url, let key = clusterUrls.filter({url.hasPrefix($0.value)}).first?.key, let index = key.lastIndex(of: ":") {
            return String(key[..<index])
        }
        return nil
    }
}

class DeviceService {

    enum Types: String {
        case ios_sdk = "TEAMS_SDK_IOS"
        case web_client = "WEB"
        case teams_client = "TEAMS_CLIENT"
    }
    
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
            let deviceInfo: [String: Any] = [
                "deviceName": UIDevice.current.name.isEmpty ? "notset" : UIDevice.current.name,
                "name": UIDevice.current.name.isEmpty ? "notset" : UIDevice.current.name,
                "model": UIDevice.current.model,
                "localizedModel": UIDevice.current.localizedModel,
                "systemName": UIDevice.current.systemName,
                "systemVersion": UIDevice.current.systemVersion,
                "deviceType": DeviceService.Types.ios_sdk.rawValue,
                "deviceIdentifier": UserDefaults.sharedInstance.deviceIdentifier ?? UUID().uuidString,
                "countryCode": region.countryCode!,
                "regionCode": region.regionCode!,
                "ttl": String(180*24*3600),
                "capabilities": ["sdpSupported":true, "groupCallSupported":true]
            ]

            self.client.fetchClusters(queue: queue) { clusterRes in
                let urls = clusterRes.result.data?.clusterUrls ?? [:]
                SDKLogger.shared.debug("Service clusters: \(urls)")

                let registrationHandler: (ServiceResponse<DeviceModel>) -> Void = { response in
                    switch response.result {
                    case .success(let model):
                        if let _ = model.deviceUrl, let _ = model.webSocketUrl {
                            self.device = Device(phone: phone, deviceModel: model, regionModel: region, clusterUrls: urls)
                            UserDefaults.sharedInstance.deviceUrl = model.deviceUrlString
                            UserDefaults.sharedInstance.deviceIdentifier = model.deviceIdentifier
                            completionHandler(Result.success(self.device!))
                        } else {
                            WebexError.serviceFailed(reason: "Missing required URLs when registering device").report(resultCallback: completionHandler)
                        }
                    case .failure(let error):
                        SDKLogger.shared.error("Failed to register device", error: error)
                        completionHandler(Result.failure(error))
                    }
                }

                let deviceUrl = UserDefaults.sharedInstance.deviceUrl
                SDKLogger.shared.debug("Saved deviceUrl: \(deviceUrl ?? "Nil")")

                if let deviceUrl = deviceUrl, !deviceUrl.contains("/devices/ios/") {
                    SDKLogger.shared.debug("Updating device");
                    self.client.update(deviceUrl: deviceUrl, deviceInfo: deviceInfo, queue: queue, completionHandler: registrationHandler)
                }
                else {
                    SDKLogger.shared.debug("Creating new device");
                    self.client.fetchHosts(queue: queue) { hostsRes in
                        let url = hostsRes.result.data?.serviceLinks?[Service.wdm.rawValue] ?? Service.wdm.baseUrl()
                        self.client.create(wdmUrl: url, deviceInfo: deviceInfo, queue: queue, completionHandler: registrationHandler)
                    }
                }
            }
        }
    }
    
    func deregisterDevice(queue: DispatchQueue, completionHandler: @escaping (Error?) -> Void) {
        if let deviceUrl = UserDefaults.sharedInstance.deviceUrl {
            self.client.delete(deviceUrl: deviceUrl, queue: queue) { (response: ServiceResponse<Any>) in
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

//fileprivate extension UIDevice {
//
//    var kind: String {
//
//        if self.userInterfaceIdiom == .pad {
//            return "IPAD"
//        } else if self.userInterfaceIdiom == .phone {
//            return "IPHONE"
//        } else {
//            return "UNKNOWN"
//        }
//    }
//
//}

