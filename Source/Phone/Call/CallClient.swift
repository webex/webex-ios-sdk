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

class CallClient {
    
    enum DialTarget {
        case callable(String)
        case joinable(WebexId)

        static func lookup(_ address: String, by webex: Webex, completionHandler: @escaping (DialTarget) -> Void) {
            if let id = WebexId.from(base64Id: address) {
                if id.is(.room) {
                    completionHandler(.joinable(id))
                }
                else {
                    completionHandler(.callable(id.uuid))
                }
            }
            else if let email = EmailAddress.fromString(address), address.contains("@") && !address.contains(".") {
                webex.people.list(email: email, displayName: nil, max: 1) { persons in
                    if let id = persons.result.data?.first?.id, let target = WebexId.from(base64Id: id) {
                        completionHandler(.callable(target.uuid))
                    }
                    else {
                        completionHandler(.callable(address))
                    }
                }
            }
            else {
                completionHandler(.callable(address))
            }
        }
    }
    
    private let authenticator: Authenticator
    
    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }

    func getOrCreatePermanentLocus(conversation: WebexId, by device: Device, queue: DispatchQueue, completionHandler: @escaping (Result<String>) -> Void) {
        let request = ServiceRequest.make(conversation.urlBy(device: device)!)
                .authenticator(self.authenticator)
                .method(.get)
                .path("locus")
                .queue(queue)
                .build()
        request.responseObject { (response: ServiceResponse<LocusUrlResponseModel>) in
            if let url = response.result.data?.locusUrl {
                completionHandler(Result.success(url))
            }
            else {
                completionHandler(Result.failure(response.result.error ?? WebexError.illegalStatus(reason: "No locus uri")))
            }
        }
    }

    func call(_ target: String, correlationId: UUID, by device: Device, option: MediaOption, localMedia: MediaModel, streamMode: Phone.VideoStreamMode, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let request = Service.locus.homed(for: device)
            .authenticator(self.authenticator)
            .method(.post)
            .path("loci").path("call")
            .body(self.makeBody(correlationId: correlationId, option: option, device: device, localMedia: localMedia, callee: target, streamMode: streamMode))
            .queue(queue)
            .build()
        
        request.responseObject(handleLocusOnlySDPResponse(option: option, queue: queue, completionHandler: completionHandler))
    }
    
    func join(_ locusUrl: String, correlationId: UUID, by device: Device, option: MediaOption, localMedia: MediaModel, streamMode: Phone.VideoStreamMode, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let request = ServiceRequest.make(locusUrl)
            .authenticator(self.authenticator)
            .method(.post)
            .path("participant")
            .body(makeBody(correlationId: correlationId, option: option, device: device, localMedia: localMedia, callee: nil, streamMode: streamMode))
            .queue(queue)
            .build()

        request.responseObject(handleLocusOnlySDPResponse(option: option, queue: queue, completionHandler: completionHandler))
    }
    
    func leave(_ participantUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let request = ServiceRequest.make(participantUrl)
            .authenticator(self.authenticator)
            .method(.put)
            .path("leave")
            .body(makeBody(deviceUrl: device.deviceUrl))
            .queue(queue)
            .build()
        
        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }
    
    func decline(_ locusUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.make(locusUrl)
            .authenticator(self.authenticator)
            .method(.put)
            .path("participant").path("decline")
            .body(makeBody(deviceUrl: device.deviceUrl))
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }

    func alert(_ locusUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.make(locusUrl)
            .authenticator(self.authenticator)
            .method(.put)
            .path("participant").path("alert")
            .body(makeBody(deviceUrl: device.deviceUrl))
            .keyPath("locus")
            .queue(queue)
            .build()
    
        request.responseJSON(completionHandler)
    }

    func update(_ mediaUrl: String, mediaID: String, localMedia: MediaModel, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let request = ServiceRequest.make(mediaUrl)
                .authenticator(self.authenticator)
                .method(.put)
                .body(makeBody(deviceUrl: device.deviceUrl, mediaId: mediaID, localMedia: localMedia))
                .queue(queue)
                .build()

        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }

    func updateMediaShare(_ share: MediaShareModel, shareUrl: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let floor: [String: Any?] = ["disposition": share.disposition,
                                     "requester": ["url": share.requesterUrl],
                                     "beneficiary": ["url": share.beneficiaryUrl as Any, "devices": ["url": device.deviceUrl.absoluteString] as Any]]
        let request = ServiceRequest.make(shareUrl)
                .authenticator(self.authenticator)
                .method(.put)
                .body(["floor": floor])
                .keyPath("locus")
                .queue(queue)
                .build()

        request.responseJSON(completionHandler)
    }

    func fetch(_ locusUrl: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let request = ServiceRequest.make(locusUrl)
                .authenticator(self.authenticator)
                .queue(queue)
                .build()

        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }

    func fetch(by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LociResponseModel>) -> Void) {
        let request = Service.locus.homed(for: device)
                .authenticator(self.authenticator)
                .path("loci")
                .queue(queue)
                .build()

        request.responseObject(completionHandler)
    }
    
    func fetch(clusterUrl: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LociResponseModel>) -> Void) {
        let request = ServiceRequest.make(clusterUrl)
                .authenticator(self.authenticator)
                .queue(queue)
                .build()

        request.responseObject(completionHandler)
    }

    func admit(_ locusUrl: String, memberships:[CallMembership], queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let body: [String: Any?] = ["admit": ["participantIds": memberships.compactMap {$0.model.id}]]
        let request = ServiceRequest.make(locusUrl)
                .authenticator(self.authenticator)
                .method(.patch)
                .path("controls")
                .body(body)
                .queue(queue)
                .build()

        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }

    func layout(_ participantUrl: String, by deviceUrl: String, layout: MediaOption.CompositedVideoLayout, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) {
        let body: [String: Any?] = ["layout": ["deviceUrl":deviceUrl, "type":layout.type]]
        let request = ServiceRequest.make(participantUrl)
                .authenticator(self.authenticator)
                .method(.patch)
                .path("controls")
                .body(body)
                .queue(queue)
                .build()

        request.responseObject(handleLocusOnlySDPResponse(completionHandler: completionHandler))
    }

    func keepAlive(_ url: String, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = ServiceRequest.make(url)
                .authenticator(self.authenticator)
                .method(.get)
                .queue(queue)
                .build()

        request.responseJSON(completionHandler)
    }

    func sendDtmf(_ participantUrl: String, by device: Device, correlationId: Int, events: String, volume: Int? = nil, durationMillis: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        var dtmf: [String: Any] = ["tones": events, "correlationId" : correlationId]
        if let volume = volume {
            dtmf["volume"] = volume
        }
        if let durationMillis = durationMillis {
            dtmf["durationMillis"] = durationMillis
        }
        var body: [String: Any?] = makeBody(deviceUrl: device.deviceUrl)
        body["dtmf"] = dtmf

        let request = ServiceRequest.make(participantUrl)
            .authenticator(self.authenticator)
            .method(.post)
            .path("sendDtmf")
            .body(body)
            .keyPath("locus")
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }

    private func makeBody(deviceUrl: URL) -> [String:Any?]  {
        return ["deviceUrl": deviceUrl.absoluteString, "respOnlySdp": true]
    }

    private func makeBody(deviceUrl: URL, mediaId: String, localMedia: MediaModel) -> [String:Any?]  {
        var json = localMedia.toJson(mediaId: mediaId)
        json["deviceUrl"] = deviceUrl.absoluteString
        json["respOnlySdp"] = true
        return json
    }

    private func makeBody(correlationId: UUID, option: MediaOption, device: Device, localMedia: MediaModel, callee: String?, streamMode: Phone.VideoStreamMode) -> [String:Any?] {
        var json = localMedia.toJson()
        json["device"] = ["url":device.deviceUrl.absoluteString, "deviceType": DeviceService.Types.ios_sdk.rawValue, "regionCode":device.countryCode, "countryCode":device.regionCode, "capabilities":["groupCallSupported":true, "sdpSupported":true]]
        json["respOnlySdp"] = true
        json["correlationId"] = correlationId.uuidString
        if streamMode == .composited {
            json["clientMediaPreferences"] = ["preferTranscoding": true]
        }
        if let pin = option.pin {
            json["pin"] = pin
        }
        if option.moderator {
            json["moderator"] = true
        }
        if let callee = callee {
            json["invitee"] = ["address" : callee]
            json["supportsNativeLobby"] = true
            json["moderator"] = false
        }
        return json
    }

    private func handleLocusOnlySDPResponse(option: MediaOption? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<LocusModel>) -> Void) -> (ServiceResponse<LocusMediaResponseModel>) -> Void {
        return {
            result in
            switch result.result {
            case .success(let model):
                if var locus = model.locus {
                    if let media = model.mediaConnections {
                        locus.mediaConnections = media
                    }
                    if let layout = option?.layout, let url = locus.myself?.url, let device = locus.myself?.deviceUrl  {
                        self.layout(url, by: device, layout: layout, queue: queue ?? DispatchQueue.main) { _ in
                            completionHandler(ServiceResponse(result.response, Result.success(locus)))
                        }
                        return;
                    }
                    completionHandler(ServiceResponse(result.response, Result.success(locus)))
                }
            case .failure(let error):
                completionHandler(ServiceResponse(result.response, Result.failure(error)))
            }
        }
    }
    
}

fileprivate extension MediaModel {

    func toJson(mediaId: String? = nil) -> [String:Any?] {
        let sdp = Mapper().toJSONString(self, prettyPrint: true)
        if let mediaId = mediaId {
            return ["localMedias": [["mediaId": mediaId ,"type": "SDP", "localSdp": sdp]]]
        }
        return ["localMedias": [["type": "SDP", "localSdp": sdp]]]
    }

}
