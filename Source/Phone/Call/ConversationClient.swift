//
//  ConversationClient.swift
//  WebexSDK
//
//  Created by zhiyuliu on 20/08/2017.
//  Copyright © 2017 Cisco. All rights reserved.
//

import Foundation
import ObjectMapper

struct ConversationLocusModel {
    fileprivate(set) var locusUrl: String?
}

extension ConversationLocusModel: Mappable {
    init?(map: Map) { }
    
    mutating func mapping(map: Map) {
        locusUrl <- map["url"]
    }
}

class ConversationClient {
    
    private let authenticator: Authenticator
    
    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }
    
    func getLocusUrl(conversation: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<ConversationLocusModel>) -> Void) {
        let request = ServiceRequest.Builder(authenticator, service: .conv, device: device)
            .method(.get)
            .path("conversations").path(conversation).path("locus")
            .keyPath("")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
}
