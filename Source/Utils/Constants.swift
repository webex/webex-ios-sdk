//
//  Constants.swift
//  WebexSDK
//
//  Created by yonshi on 2019/7/18.
//  Copyright © 2019 Cisco. All rights reserved.
//

import Foundation


struct Event {
    struct Verb {
        static let acknowledge = "acknowledge"
        static let create = "create"
        static let post = "post"
        static let share = "share"
        static let delete = "delete"
        static let add = "add"
        static let leave = "leave"
        static let assignModerator = "assignModerator"
        static let unassignModerator = "unassignModerator"
        static let hide = "hide"
        static let update = "update"
        
        static func isContained(_ verb:String) -> Bool {
            if verb == post || verb == share || verb == delete
                || verb == add || verb == leave || verb == acknowledge
                || verb == assignModerator || verb == unassignModerator {
                return true
            }else {
                return false
            }
        }
    }
    
    struct EventType {
        static let created = "created"
        static let deleted = "deleted"
        static let updated = "updated"
        static let seen = "seen"
    }
    
    struct Resource {
        static let memberships = "memberships"
        static let messages = "messages"
        static let rooms = "rooms"
    }
}

