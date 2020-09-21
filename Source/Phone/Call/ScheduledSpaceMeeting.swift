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

/// A SpaceScheduledMeeting represents a scheduled space meeting.
///
/// - since: 2.6.0
public class ScheduledSpaceMeeting {

    public enum Event {
        case ready(ScheduledSpaceMeeting)
        case updated(ScheduledSpaceMeeting)
        case removed(ScheduledSpaceMeeting)
    }

    public enum State {
        case active
        case removed
    }

    private let phone: Phone
    private let model: MeetingModel
    private let locus: LocusModel
    private let _meetingInfo: SpaceMeetingInfo?

    /// The unique identifier for meeting.
    ///
    /// - since: 2.6.0
    public var id: String? {
        return self.model.meetingId
    }

    /// Meeting title.
    ///
    /// - since: 2.6.0
    public var title: String? {
        return self.locus.info?.webExMeetingName
    }

    /// Start time for meeting in ISO 8601 compliant format.
    ///
    /// - since: 2.6.0
    public var start: Date? {
        return model.startTime
    }

    /// End time for meeting in ISO 8601 compliant format.
    ///
    /// - since: 2.6.0
    public var end: Date? {
        if let min = model.durationMinutes {
            return model.startTime?.addingTimeInterval(TimeInterval(min * 60))
        }
        return model.startTime
    }

    /// The unique identifier for meeting host
    ///
    /// - since: 2.6.0
    public var hostUserId: String? {
        if let uuid = locus.host?.id {
            return WebexId(type: .people, cluster: WebexId.DEFAULT_CLUSTER_ID, uuid: uuid).base64Id
        }
        return nil
    }

    /// The display name for meeting host.
    ///
    /// - since: 2.6.0
    public var hostDisplayName: String? {
        return locus.host?.name
    }

    /// The email address for meeting host.
    ///
    /// - since: 2.6.0
    public var hostEmail: String? {
        return locus.host?.email
    }

    /// The SpaceMeetingInfo of the meeting.
    ///
    /// - since: 2.6.0
    public var meetingInfo: SpaceMeetingInfo? {
        return self._meetingInfo
    }

    /// The state of the meeting.
    ///
    /// - since: 2.6.0
    public var state: State {
        if let remove = model.removed, remove {
            return .removed
        }
        return .active
    }

    init(phone: Phone, model: MeetingModel, locus: LocusModel, meetingInfo: SpaceMeetingInfo?) {
        self.phone = phone
        self.model = model
        self.locus = locus
        self._meetingInfo = meetingInfo
    }

    public func join(_ option: MediaOption, completionHandler: @escaping (Result<Call>) -> Void) {
        if self.state == .removed {
            DispatchQueue.main.async {
                completionHandler(Result.failure(WebexError.illegalOperation(reason: "Cannot join a removed meeting.")))
            }
            return
        }
        guard let device = self.phone.devices.device else {
            DispatchQueue.main.async {
                completionHandler(Result.failure(WebexError.unregistered))
            }
            return
        }
        let call = Call(model: self.locus, device: device, media: self.phone.mediaContext ?? MediaSessionWrapper(), direction: Call.Direction.incoming, group: !self.locus.isOneOnOne, correlationId:UUID())
        phone.add(call: call)
        call.answer(option: option) { error in
            if let error = error {
                completionHandler(Result.failure(error))
            }
            else {
                completionHandler(Result.success(call))
            }
        }
    }



}
