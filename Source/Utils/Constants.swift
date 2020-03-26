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

enum ObjectType : String {
    case activity
    case comment
    case content
    case conversation
}

class MSGError {
    static let spaceFetchFail = WebexError.serviceFailed(code: -7000, reason: "Space Fetch Fail")
    static let clientInfoFetchFail = WebexError.serviceFailed(code: -7000, reason: "Client Info Fetch Fail")
    static let ephemaralKeyFetchFail = WebexError.serviceFailed(code: -7000, reason: "EphemaralKey Fetch Fail")
    static let kmsInfoFetchFail = WebexError.serviceFailed(code: -7000, reason: "KMS Info Fetch Fail")
    static let keyMaterialFetchFail = WebexError.serviceFailed(code: -7000, reason: "Key Info Fetch Fail")
    static let encryptionUrlFetchFail = WebexError.serviceFailed(code: -7000, reason: "Encryption Info Fetch Fail")
    static let spaceUrlFetchFail = WebexError.serviceFailed(code: -7000, reason: "Space Info Fetch Fail")
    static let spaceMessageFetchFail = WebexError.serviceFailed(code: -7000, reason: "Messages Of Space Fetch Fail")
    static let emptyTextError = WebexError.serviceFailed(code: -7000, reason: "Expected Text Not Found")
    static let downloadError = WebexError.serviceFailed(code: -7000, reason: "Expected File Not Found")
    static let timeOut = WebexError.serviceFailed(code: -7000, reason: "Timeout")
}


