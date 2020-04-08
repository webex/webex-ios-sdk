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

class CallClient {
    
    enum DialTarget {
        case peopleId(String)
        case peopleMail(String)
        case spaceId(String)
        case spaceMail(String)
        case other(String)
        
        var isEndpoint: Bool {
            switch self {
            case .peopleId(_), .peopleMail(_), .spaceMail(_), .other(_):
                return true
            case .spaceId(_):
                return false
            }
        }
        
        var isGroup: Bool {
            switch self {
            case .peopleId(_), .peopleMail(_), .other(_):
                return false
            case .spaceId(_), .spaceMail(_):
                return true
            }
        }
        
        var address: String {
            switch self {
            case .peopleId(let id):
                return id
            case .peopleMail(let mail):
                return mail
            case .spaceId(let id):
                return id
            case .spaceMail(let mail):
                return mail
            case .other(let other):
                return other
            }
        }
        
        static func lookup(_ address: String, by webex: Webex, completionHandler: @escaping (DialTarget) -> Void) {
            if let target = parseHydraId(id: address) {
                completionHandler(target)
            }
            else if let email = EmailAddress.fromString(address) {
                if address.lowercased().hasSuffix("@meet.ciscospark.com") {
                    completionHandler(DialTarget.spaceMail(address))
                }
                else if address.contains("@") && !address.contains(".") {
                    webex.people.list(email: email, displayName: nil, max: 1) { persons in
                        if let id = persons.result.data?.first?.id, let target = parseHydraId(id: id) {
                            completionHandler(target)
                        }
                        else {
                            completionHandler(DialTarget.peopleMail(address))
                        }
                    }
                }
                else {
                    completionHandler(DialTarget.peopleMail(address))
                }
            }
            else {
                completionHandler(DialTarget.other(address))
            }
        }
        
        private static func parseHydraId(id: String) -> DialTarget? {
            if let decode = id.base64Decoded(), let uri = URL(string: decode), uri.scheme == "ciscospark" {
                let path = uri.pathComponents
                if path.count > 2 {
                    let type = path[path.count - 2]
                    if type == "PEOPLE" {
                        return DialTarget.peopleId(path[path.count - 1])
                    }
                    else if type == "ROOM" {
                        return DialTarget.spaceId(path[path.count - 1])
                    }
                }
            }
            return nil
        }
    }
    
    private let authenticator: Authenticator
    
    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }
    
    private func body(deviceUrl: URL, json: [String:Any?] = [:]) -> RequestParameter {
        var result = json
        result["deviceUrl"] = deviceUrl.absoluteString
        result["respOnlySdp"] = true //coreFeatures.isResponseOnlySdpEnabled()
        return RequestParameter(result)
    }

    private func body(composedVideo: Bool, device: Device, json: [String:Any?] = [:]) -> RequestParameter {
        var result = json
        result["device"] = ["url":device.deviceUrl.absoluteString, "deviceType": (composedVideo ? "WEB" : device.deviceType), "regionCode":device.countryCode, "countryCode":device.regionCode, "capabilities":["groupCallSupported":true, "sdpSupported":true]]
        result["respOnlySdp"] = true //coreFeatures.isResponseOnlySdpEnabled()
        return RequestParameter(result)
    }
    
    private func convertToJson(_ mediaID: String? = nil, mediaInfo: MediaModel) -> [String:Any?] {
        let mediaInfoJSON = Mapper().toJSONString(mediaInfo, prettyPrint: true)!
        if let id = mediaID {
            return ["localMedias": [["mediaId":id ,"type": "SDP", "localSdp": mediaInfoJSON]]]
        }
        return ["localMedias": [["type": "SDP", "localSdp": mediaInfoJSON]]]
    }
    
    private func handleLocusOnlySDPResponse(layout: MediaOption.VideoLayout? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) ->((ServiceResponse<CallResponseModel>) -> Void) {
        return {
            result in
            switch result.result {
            case .success(let callResponse):
                if var callModel = callResponse.callModel {
                    callModel.setMediaConnections(newMediaConnections: callResponse.mediaConnections)
                    if let layout = layout, let url = callModel.myself?.url, let device = callModel.myself?.deviceUrl  {
                        self.layout(url, by: device, layout: layout, queue: queue ?? DispatchQueue.main) { _ in
                            completionHandler(ServiceResponse.init(result.response, Result.success(callModel)))
                        }
                        return;
                    }
                    completionHandler(ServiceResponse.init(result.response, Result.success(callModel)))
                }
            case .failure(let error):
                completionHandler(ServiceResponse.init(result.response, Result.failure(error)))
            }
        }
    }
    
    func create(_ toAddress: String, moderator:Bool? = false, PIN:String? = nil, by device: Device, localMedia: MediaModel, layout: MediaOption.VideoLayout?, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        var json = convertToJson(mediaInfo: localMedia)
        json["invitee"] = ["address" : toAddress]
        json["supportsNativeLobby"] = true
        json["moderator"] = moderator
        json["pin"] = PIN
        let request = ServiceRequest.Builder(authenticator, service: .locus, device: device)
            .method(.post)
            .path("loci").path("call")
            .body(body(composedVideo: layout != .single, device: device, json: json))
            .queue(queue)
            .build()
        
        request.responseObject(handleLocusOnlySDPResponse(layout: layout, queue: queue, completionHandler: completionHandler))
    }
    
    func join(_ callUrl: String, by device: Device, localMedia: MediaModel, layout: MediaOption.VideoLayout?, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let json = convertToJson(mediaInfo: localMedia)
        let request = ServiceRequest.Builder(authenticator, endpoint: callUrl)
            .method(.post)
            .path("participant")
            .body(body(composedVideo: layout != .single, device: device, json: json))
            .queue(queue)
            .build()
        request.responseObject(handleLocusOnlySDPResponse(layout: layout, queue: queue, completionHandler: completionHandler))
    }
    
    func leave(_ participantUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, endpoint: participantUrl)
            .method(.put)
            .path("leave")
            .body(body(deviceUrl: device.deviceUrl))
            .queue(queue)
            .build()
        
        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }
    
    func decline(_ callUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, endpoint: callUrl)
            .method(.put)
            .path("participant").path("decline")
            .body(body(deviceUrl: device.deviceUrl))
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }

    func alert(_ callUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, endpoint: callUrl)
            .method(.put)
            .path("participant").path("alert")
            .body(body(deviceUrl: device.deviceUrl))
            .keyPath("locus")
            .queue(queue)
            .build()
    
        request.responseJSON(completionHandler)
    }
    
    func sendDtmf(_ participantUrl: String, by device: Device, correlationId: Int, events: String, volume: Int? = nil, durationMillis: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        var dtmfInfo: [String:Any] = [
            "tones": events,
            "correlationId" : correlationId]
        if let volume = volume {
            dtmfInfo["volume"] = volume
        }
        if let durationMillis = durationMillis {
            dtmfInfo["durationMillis"] = durationMillis
        }
        let json: [String: Any] = ["dtmf" : dtmfInfo]
        
        let request = ServiceRequest.Builder(authenticator, endpoint: participantUrl)
            .method(.post)
            .path("sendDtmf")
            .body(body(deviceUrl: device.deviceUrl, json: json))
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
    func update(_ mediaUrl: String,by mediaID: String, by device: Device, localMedia: MediaModel, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let json = convertToJson(mediaID,mediaInfo: localMedia)
        let request = ServiceRequest.Builder(authenticator, endpoint: mediaUrl)
            .method(.put)
            .body(body(deviceUrl: device.deviceUrl, json: json))
            .queue(queue)
            .build()
        
        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }
    
    func fetch(_ callUrl: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, endpoint: callUrl)
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    func fetch(by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<[CallModel]>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, service: .locus, device: device)
            .path("loci")
            .keyPath("loci")
            .queue(queue)
            .build()
        
        request.responseArray(completionHandler)
    }
    
    func updateMediaShare(_ mediaShare: MediaShareModel, by device: Device, mediaShareUrl:String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        var mediaShareUpdateParam: [String: Any?]
        let floorParam: [String: Any?] = ["disposition": mediaShare.shareFloor?.disposition?.rawValue.uppercased() ?? "RELEASE",
                                          "requester": ["url": mediaShare.shareFloor?.requester?.url],
                                          "beneficiary": ["url": mediaShare.shareFloor?.beneficiary?.url as Any,
                                                          "devices": ["url": device.deviceUrl.absoluteString] as Any]]
        mediaShareUpdateParam = ["floor": floorParam]
        let body = RequestParameter(mediaShareUpdateParam)
        let request = ServiceRequest.Builder(authenticator, endpoint: mediaShareUrl)
            .method(.put)
            .body(body)
            .keyPath("locus")
            .queue(queue)
            .build()
            
        request.responseJSON(completionHandler)
    }
    
    func letIn(_ locusUrl: String, memberships:[CallMembership], queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let participantIds = memberships.compactMap {$0.model.id}
        let parameters: [String: Any?] = ["admit":["participantIds":participantIds]]
        let request = ServiceRequest.Builder(authenticator, endpoint: locusUrl)
            .method(.patch)
            .path("controls")
            .body(RequestParameter(parameters))
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    func layout(_ participantUrl: String, by deviceUrl: String, layout: MediaOption.VideoLayout, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<CallModel>) -> Void) {
        let parameters: [String: Any?] = ["layout":["deviceUrl":deviceUrl, "type":layout.type]]
        let request = ServiceRequest.Builder(authenticator, endpoint: participantUrl)
            .method(.patch)
            .path("controls")
            .body(RequestParameter(parameters))
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    func keepAlive(_ url: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, endpoint: url)
            .method(.get)
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
}
