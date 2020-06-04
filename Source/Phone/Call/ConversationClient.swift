//
//  ConversationClient.swift
//  WebexSDK
//
//  Created by zhiyuliu on 20/08/2017.
//  Copyright © 2017 Cisco. All rights reserved.
//

import Foundation
import ObjectMapper

class ConversationClient {
    
    private let authenticator: Authenticator
    
    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }
    
    func getLocusUrl(conversation: String, by device: Device, queue: DispatchQueue, completionHandler: @escaping (ServiceResponse<LocusUrlResponseModel>) -> Void) {
        // TODO Find the cluster for the conversation instead of use home cluster always.
        let request = Service.conv.homed(for: device)
            .authenticator(self.authenticator)
            .method(.get)
            .path("conversations").path(conversation).path("locus")
            .keyPath("")
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
}
