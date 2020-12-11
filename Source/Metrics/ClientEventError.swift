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

struct ClientEventError: Mappable {
    
    enum Name: String {
        case mediaEngine = "media-engine"
        case iceFailed = "ice.failed"
        case locusResponse = "locus.response"
        case clientLeave = "client.leave"
        case other = "other"
    }

    enum Category: String {
        case signaling
        case media
        case expected
        case other
    }

    struct ErrorType {
        
        // https://sqbu-github.cisco.com/WebExSquared/event-dictionary/wiki/Error-codes-for-metric-events
        // https://sqbu-github.cisco.com/WebExSquared/spark-client-framework/blob/720e49c0590f1aa20cc531bb8a5ae7947fe7b13b/spark-client-framework/Services/TelephonyService/telephony_error_codes.csv
        // https://sqbu-github.cisco.com/WebExSquared/cisco-spark-base/blob/58166be0d6aab2b4b91f01f159e2ac0917244b7d/wx2-core/common/src/main/java/com/cisco/wx2/dto/ErrorCode.java
        // https://sqbu-github.cisco.com/WebExSquared/cisco-spark-base/blob/master/wx2-core/server/src/main/resources/server-common-error-codes.properties
        
        static let unknown = ErrorType(category: .signaling, errorCode: 1000, fatal: true)
        static let locusRateLimitedIncoming = ErrorType(category: .signaling, errorCode: 1001, fatal: true)
        static let locusRateLimitedOutgoing = ErrorType(category: .signaling, errorCode: 1002, fatal: true)
        static let locusUnavailable = ErrorType(category: .signaling, errorCode: 1003, fatal: true)
        static let locusConflict = ErrorType(category: .signaling, errorCode: 1004, fatal: true)
        static let timeout = ErrorType(category: .expected, errorCode: 1005, fatal: true)
        static let locusInvalidSequenceHash = ErrorType(category: .signaling, errorCode: 1006, fatal: true)
        static let updateMediaFailed = ErrorType(category: .signaling, errorCode: 1007, fatal: true)
        static let failedToCreateConversation = ErrorType(category: .signaling, errorCode: 1020, fatal: true)
        static let conversationMissingLocusUrl = ErrorType(category: .signaling, errorCode: 1021, fatal: true)
        static let failedToConnectMedia = ErrorType(category: .signaling, errorCode: 2001, fatal: true)
        static let mediaEngineLost = ErrorType(category: .signaling, errorCode: 2002, fatal: true)
        static let mediaConnectionLost = ErrorType(category: .signaling, errorCode: 2003, fatal: true)
        static let iceFailed = ErrorType(category: .signaling, errorCode: 2004, fatal: true)
        static let mediaEngineHang = ErrorType(category: .signaling, errorCode: 2005, fatal: true)
        static let mediaReconnectTimeout = ErrorType(category: .signaling, errorCode: 2008, fatal: true)
        static let callFull = ErrorType(category: .expected, errorCode: 3001, fatal: true)
        static let roomTooLarge = ErrorType(category: .expected, errorCode: 3002, fatal: true)
        static let callFullAddGuest = ErrorType(category: .expected, errorCode: 3003, fatal: false)
        static let guestAlreadyAdded = ErrorType(category: .expected, errorCode: 3004, fatal: false)
        static let locusUserNotAuthorised = ErrorType(category: .expected, errorCode: 3005, fatal: true)
        static let cloudberryUnavailable = ErrorType(category: .expected, errorCode: 3006, fatal: true)
        static let roomTooLargeFreeAccount = ErrorType(category: .expected, errorCode: 3007, fatal: true)
        static let streamInternal = ErrorType(category: .media, errorCode: 3008, fatal: false)
        static let streamTempInternal = ErrorType(category: .media, errorCode: 3009, fatal: false)
        static let streamInvalidRequest = ErrorType(category: .media, errorCode: 3010, fatal: false)
        static let streamPermanentlyUnavailable = ErrorType(category: .media, errorCode: 3011, fatal: false)
        static let streamInsufficientSrc = ErrorType(category: .media, errorCode: 3012, fatal: false)
        static let streamNoMedia = ErrorType(category: .media, errorCode: 3013, fatal: false)
        static let streamWrongStream = ErrorType(category: .media, errorCode: 3014, fatal: false)
        static let streamInsufficientBandwidth = ErrorType(category: .media, errorCode: 3015, fatal: false)
        static let streamMuteWithAvatar = ErrorType(category: .media, errorCode: 3016, fatal: false)
        static let videoCameraFail = ErrorType(category: .media, errorCode: 3020, fatal: false)
        static let videoCameraNotAuthorized = ErrorType(category: .media, errorCode: 3021, fatal: false)
        static let videoCameraNoDevice = ErrorType(category: .media, errorCode: 3022, fatal: false)
        static let videoCameraOccupied = ErrorType(category: .media, errorCode: 3023, fatal: false)
        static let videoCameraRuntimeDie = ErrorType(category: .media, errorCode: 3024, fatal: false)
        static let audioNoCaptureDevice = ErrorType(category: .media, errorCode: 3026, fatal: false)
        static let audioStartCaptureFailed = ErrorType(category: .media, errorCode: 3027, fatal: false)
        static let audioCannotCaptureFromDevice = ErrorType(category: .media, errorCode: 3028, fatal: false)
        static let audioNoPlaybackDevice = ErrorType(category: .media, errorCode: 3029, fatal: false)
        static let audioStartPlaybackFailed = ErrorType(category: .media, errorCode: 3030, fatal: false)
        static let audioCannotPlayToDevice = ErrorType(category: .media, errorCode: 3031, fatal: false)
        static let audioCannotUseThisDevice = ErrorType(category: .media, errorCode: 3032, fatal: false)
        static let audioServiceRunOut = ErrorType(category: .media, errorCode: 3033, fatal: false)
        static let meetingInactive = ErrorType(category: .expected, errorCode: 4001, fatal: true)
        static let meetingLocked = ErrorType(category: .expected, errorCode: 4002, fatal: true)
        static let meetingTerminating = ErrorType(category: .expected, errorCode: 4003, fatal: true)
        static let moderatorPinOrGuestRequired = ErrorType(category: .expected, errorCode: 4004, fatal: false)
        static let moderatorPinOrGuestPinRequired = ErrorType(category: .expected, errorCode: 4005, fatal: false)
        static let moderatorRequired = ErrorType(category: .expected, errorCode: 4006, fatal: false)
        static let userNotMemberOfRoom = ErrorType(category: .expected, errorCode: 4007, fatal: true)
        static let newLocusError = ErrorType(category: .signaling, errorCode: 4008, fatal: true)
        static let networkUnavailable = ErrorType(category: .expected, errorCode: 4009, fatal: true)
        static let meetingUnavailable = ErrorType(category: .expected, errorCode: 4010, fatal: true)
        static let meetingIDInvalid = ErrorType(category: .expected, errorCode: 4011, fatal: true)
        static let meetingSiteInvalid = ErrorType(category: .expected, errorCode: 4012, fatal: true)
        static let locusInvalidJoinTime = ErrorType(category: .expected, errorCode: 4013, fatal: true)
        static let lobbyExpired = ErrorType(category: .expected, errorCode: 4014, fatal: true)
        static let mediaConnectionLostPaired = ErrorType(category: .expected, errorCode: 4015, fatal: false)
        static let phoneNumberNotANumber = ErrorType(category: .expected, errorCode: 4016, fatal: true)
        static let phoneNumberTooLong = ErrorType(category: .expected, errorCode: 4017, fatal: true)
        static let invalidDialableKey = ErrorType(category: .expected, errorCode: 4018, fatal: true)
        static let oneOnOneToSelfNotAllowed = ErrorType(category: .expected, errorCode: 4019, fatal: true)
        static let removedParticipant = ErrorType(category: .expected, errorCode: 4020, fatal: true)
        static let meetingLinkNotFound = ErrorType(category: .expected, errorCode: 4021, fatal: true)
        static let phoneNumberTooShortAfterIdd = ErrorType(category: .expected, errorCode: 4022, fatal: true)
        static let invalidInviteeAddress = ErrorType(category: .expected, errorCode: 4023, fatal: true)
        static let pmrUserAccountLockedOut = ErrorType(category: .expected, errorCode: 4024, fatal: true)
        static let guestForbidden = ErrorType(category: .expected, errorCode: 4025, fatal: true)
        static let pmrAccountSuspended = ErrorType(category: .expected, errorCode: 4026, fatal: true)
        static let emptyPhoneNumberOrCountryCode = ErrorType(category: .expected, errorCode: 4027, fatal: true)
        static let conversationNotFound = ErrorType(category: .expected, errorCode: 4028, fatal: true)
        static let startRecordingFailed = ErrorType(category: .expected, errorCode: 4029, fatal: true)
        static let recordingStorageFull = ErrorType(category: .expected, errorCode: 4030, fatal: true)
        static let notWebexSite = ErrorType(category: .expected, errorCode: 4031, fatal: true)
        static let cameraPermissionDenied = ErrorType(category: .expected, errorCode: 4032, fatal: true)
        static let microphonePermissionDenied = ErrorType(category: .expected, errorCode: 4033, fatal: true)
        static let activeCallExists = ErrorType(category: .expected, errorCode: 4034, fatal: true)
        static let timeOutRecording = ErrorType(category: .expected, errorCode: 4035, fatal: true)
        static let autoJoinIsNotAllow = ErrorType(category: .expected, errorCode: 4036, fatal: true)
        static let numericDialPrevented = ErrorType(category: .expected, errorCode: 4037, fatal: true)
        static let locusJoinRestrictedPstn = ErrorType(category: .expected, errorCode: 4038, fatal: true)
        static let sipCalleeBusy = ErrorType(category: .expected, errorCode: 5000, fatal: true)
        static let sipCalleeNotFound = ErrorType(category: .expected, errorCode: 5001, fatal: true)
        static let couldNotCreateConfluence = ErrorType(category: .signaling, errorCode: 6000, fatal: true)
        static let meetingRegistryServiceNotAvailable = ErrorType(category: .signaling, errorCode: 6001, fatal: true)
        static let unableToGetConversation = ErrorType(category: .signaling, errorCode: 6005, fatal: true)
        static let callKitUnknown = ErrorType(category: .expected, errorCode: 7000, fatal: true)
        static let callKitNotEntitled = ErrorType(category: .expected, errorCode: 7001, fatal: true)
        static let callKitUUIDAlreadyExists = ErrorType(category: .expected, errorCode: 7002, fatal: true)
        static let callKitFilteredByDoNoDisturb = ErrorType(category: .expected, errorCode: 7003, fatal: true)
        static let callKitFilteredByBlockList = ErrorType(category: .expected, errorCode: 7004, fatal: true)
        static let callKitUnknownCallProvider = ErrorType(category: .expected, errorCode: 7005, fatal: true)
        static let callKitEmptyTransaction = ErrorType(category: .expected, errorCode: 7006, fatal: true)
        static let callKitUnknownCallUUID = ErrorType(category: .expected, errorCode: 7007, fatal: true)
        static let callKitInvalidAction = ErrorType(category: .expected, errorCode: 7008, fatal: true)
        static let callKitMaximumCallGroupsReached = ErrorType(category: .expected, errorCode: 7009, fatal: true)
        
        let category: Category
        let errorCode: Int
        let fatal: Bool
        
        init(category: Category, errorCode: Int, fatal: Bool) {
            self.category = category
            self.errorCode = errorCode
            self.fatal = fatal
        }
    }

    private(set) var name: Name?
    private(set) var category: Category?
    private(set) var errorCode: Int?
    private(set) var fatal: Bool?
    private(set) var shownToUser: Bool?
    private(set) var httpCode: Int?
    private(set) var errorDescription: String?
    private(set) var errorData:  [String: Any]?
    
    init(name: Name, type: ErrorType, shownToUser: Bool, httpCode: Int?, errorDescription: String?, errorData: [String: Any]?) {
        self.name = name
        self.category = type.category
        self.errorCode = type.errorCode
        self.fatal = type.fatal
        self.shownToUser = shownToUser
        self.httpCode = httpCode
        self.errorDescription = errorDescription
        self.errorData = errorData
    }
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.name <- map["name"]
        self.category <- map["category"]
        self.fatal <- map["fatal"]
        self.shownToUser <- map["shownToUser"]
        self.errorCode <- map["errorCode"]
        self.httpCode <- map["httpCode"]
        self.errorDescription <- map["errorDescription"]
        self.errorData <- map["errorData"]
    }
}
