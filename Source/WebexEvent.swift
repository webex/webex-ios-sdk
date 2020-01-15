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

/// The payload of the event.
///
/// - since: 2.3.0
public struct WebexEventPayload {
    
    init(activity: ActivityModel?, person: Person?) {
        self.actorId = activity?.actorId
        //        self.createdBy = person?.id
        //        self.orgId = person?.orgId
    }
    
    /// Returns the identifier of the user that caused the event to be sent. For example, for a messsage received event,
    /// the author of the message will be the actor. For a membership deleted event, the actor is the person who removed the user
    /// from space.
    public let actorId: String?
    
    /// the current date on client
    //    public let created: Date = Date()
    
    //    /// default is "creator"
    //    public let ownedBy: String = "creator"
    //
    //    /// default is "active"
    //    public let status: String = "active"
    
}
