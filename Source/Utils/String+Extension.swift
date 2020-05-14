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
import MobileCoreServices.UTCoreTypes
import MobileCoreServices.UTType

extension String {
    private static let allowedQueryCharactersPlusSpace = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~ ")
    
    var decodeString: String? {
        return self.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
    
    var encodeQueryParamString: String? {
        return self.addingPercentEncoding(withAllowedCharacters: String.allowedQueryCharactersPlusSpace)?.replacingOccurrences(of: " ", with: "+")
    }
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString().replacingOccurrences(of: "=", with: "")
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        var encoded64 = self
        let remainder = encoded64.count % 4
        if remainder > 0 {
            encoded64 = encoded64.padding(toLength: encoded64.count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        if let data = Data(base64Encoded: encoded64) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    subscript(r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            
            return String(self[Range(uncheckedBounds: (startIndex, endIndex))])
        }
    }
    
    subscript(start: Int, end: Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: start)
            let endIndex = self.index(self.startIndex, offsetBy: end+1)
            return String(self[Range(uncheckedBounds: (startIndex, endIndex))])
        }
    }
    
    var mimeType: String {
        if let ext = self.components(separatedBy: ".").last, ext.count > 0 {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() {
                if let mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeUnretainedValue() {
                    return mime as String;
                }
            }
        }
        return "application/octet-stream"
    }
    
    var bool: Bool? {
        switch self.lowercased() {
        case "true", "t", "yes", "y", "1":
            return true
        case "false", "f", "no", "n", "0":
            return false
        default:
            return nil
        }
    }
    
}

enum ContentType: String {
    case IMAGE
    case EXCEL
    case POWERPOINT
    case WORD
    case PDF
    case VIDEO
    case AUDIO
    case ZIP
    case UNKNOWN
}

extension String {
    static let imageExtensions = ["jpg", "jpeg", "png", "gif"]
    static let excelExtensions = ["xls", "xlsx", "xlsm", "xltx", "xltm"]
    static let powerpointExtensions = ["ppt", "pptx", "pptm", "potx", "potm", "ppsx", "ppsm", "sldx", "sldm"]
    static let wordExtensions = ["doc", "docx", "docm", "dotx", "dotm"]
    static let pdfExtensions = ["pdf"]
    static let videoExtensions = ["mp4", "m4p", "mpg", "mpeg", "3gp", "3g2", "mov", "avi", "wmv", "qt", "m4v", "flv", "m4v"]
    static let audioExtension = ["mp3", "wav", "wma"]
    static let zipExtension = ["zip"]
    
    var shouldTranscode: Bool {
        switch self.contentType {
        case .POWERPOINT, .WORD, .PDF, .EXCEL:
            return true
        default:
            return false
        }
    }
    
    var contentType: ContentType {
        guard let extention = self.extention else {
            return .UNKNOWN
        }
        
        var type: ContentType = .UNKNOWN
        
        switch extention.lowercased() {
        case let ext where String.imageExtensions.contains(ext):
            type = .IMAGE
        case let ext where String.excelExtensions.contains(ext):
            type = .EXCEL
        case let ext where String.powerpointExtensions.contains(ext):
            type = .POWERPOINT
        case let ext where String.wordExtensions.contains(ext):
            type = .WORD
        case let ext where String.pdfExtensions.contains(ext):
            type = .PDF
        case let ext where String.videoExtensions.contains(ext):
            type = .VIDEO
        case let ext where String.audioExtension.contains(ext):
            type = .AUDIO
        case let ext where String.zipExtension.contains(ext):
            type = .ZIP
        default:
            type = .UNKNOWN
        }
        return type
    }
    
    var extention: String? {
        if let ext = self.components(separatedBy: ".").last, ext.count > 0 {
            return ext
        }
        return nil
    }
}
