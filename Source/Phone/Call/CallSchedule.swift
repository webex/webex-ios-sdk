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

/// A CallSchedule represents the schedule of a scheduled call
///
/// - since: 2.6.0
public class CallSchedule: Equatable, CustomStringConvertible {

    ///  Start time of the call is scheduled.
    ///
    /// - since: 2.6.0
    public let start: Date?

    /// End time of the call is scheduled.
    ///
    /// - since: 2.6.0
    public let end: Date?

    init(meeting: MeetingModel, fullState: FullStateModel?) {
        self.start = meeting.startTime
        self.end = self.start?.addingTimeInterval(TimeInterval((meeting.durationMinutes ?? 0) * 60))
    }

    public static func ==(lhs: CallSchedule, rhs: CallSchedule) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end
    }
    
    public var description: String {
        return "CallSchedule(\(String(describing: self.start)), \(String(describing: self.end)))"
    }
}
