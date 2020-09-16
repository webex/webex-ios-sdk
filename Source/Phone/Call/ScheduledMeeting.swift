//
//  ScheduledMeeting.swift
//  WebexSDK
//
//  Created by yonshi on 2020/9/15.
//

import Foundation


public enum MeetingEvent {
    case received(ScheduledMeeting)
    case updated(ScheduledMeeting)
    case removed(ScheduledMeeting)
}

public class ScheduledMeeting {
    
    private let model: CallModel
    internal let call:Call
    
    /// the Id of the meeting associated with the call
    ///
    /// - since: 2.6.0
    public var id: String? {
        return model.meeting?.meetingId
    }
    
    /// The start time of the meeting.
    ///
    /// - since: 2.6.0
    public var startTime: Date? {
        return model.meeting?.startTime
    }
    
    /// The duration minutes of the meeting.
    ///
    /// - since: 2.6.0
    public var duration: Int? {
        return model.meeting?.durationMinutes
    }
    
    /// The sipUri of the meeting.
    ///
    /// - since: 2.6.0
    public var sipAddress: String? {
        return model.meetingInfo?.sipUri
    }
    
    /// True if the meeting has started.
    ///
    /// - since: 2.6.0
    public var isActive: Bool? {
        return model.fullState?.active
    }
    
    /// True if the meeting has  removed or ended.
    ///
    /// - since: 2.6.0
    public var isRemoved: Bool? {
        return model.meeting?.removed
    }
    
    /// The topic of the meeting
    ///
    /// - since: 2.6.0
    public var topic: String? {
        return model.meetingInfo?.topic
    }

    /// The Id of the meeting host
    ///
    /// - since: 2.6.0
    public var hostId: String? {
        return WebexId(type: .people, uuid: model.host?.id)?.base64Id ?? model.host?.email
    }
    
    /// The name of the meeting host
    ///
    /// - since: 2.6.0
    public var hostName: String? {
        return model.host?.name
    }
    
    
    init(model: CallModel, call: Call) {
        self.model = model
        self.call = call
    }
    
    public func join(_ option: MediaOption, completionHandler:@escaping (Call?, Error?) -> Void) {
        if isRemoved == true {
            completionHandler(nil, WebexError.illegalOperation(reason: "Cannot join a removed meeting."))
            return
        }
        self.call.answer(option: option) { (error) in
            completionHandler(self.call, error)
        }
    }
    
}

