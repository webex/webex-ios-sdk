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

class FileModel : ObjectModel {

    private(set) var fileSize: UInt64?
    private(set) var mimeType: String?
    var image: ImageModel?
    private(set) var scr: String?
    var scrObject: SecureContentReference?

    private var contentId: String?
    private var version: String?

    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        self.mimeType <- map["mimeType"]
        self.fileSize <- map["fileSize"]
        self.image <- map["image"]
        self.scr <- map["scr"]
    }

    override func encrypt(key: String?) {
        super.encrypt(key: key)
        if let url = self.url {
            self.scrObject?.loc = URL(string: url)
        }
        if let scrObject = self.scrObject {
            self.scr = try? scrObject.encryptedSecureContentReference(withKey: key)
            self.scrObject = nil
        }
        self.image?.encrypt(key: key)
    }

    override func decrypt(key: String?) {
        super.decrypt(key: key)
        self.scr = self.scr?.decrypt(key: key)
        if let scr = self.scr {
            self.scrObject = try? SecureContentReference(json: scr)
        }
        self.image?.decrypt(key: key)
    }

}

