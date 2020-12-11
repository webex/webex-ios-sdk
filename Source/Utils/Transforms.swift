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

class UInt64Transform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> UInt64?{
        return (value as? NSNumber)?.uint64Value
    }
    
    func transformToJSON(_ value: UInt64?) -> String? {
        if let value = value {
            return String(value)
        }
        return nil
    }
}

class EmailTransform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> EmailAddress? {
        if let value = value as? String {
            return EmailAddress.fromString(value)
        } else {
            return nil
        }
    }
    
    func transformToJSON(_ value: EmailAddress?) -> String? {
        return value?.toString()
    }
}

class EmailsTransform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> [EmailAddress]? {
        guard let value = (value as? [String]) else {
            return nil
        }
        var emails: [EmailAddress] = []
        for emailString in value {
            if let emailAddress = EmailAddress.fromString(emailString) {
                emails.append(emailAddress)
            } else {
                SDKLogger.shared.warn("\(emailString) is not a properly formatted email address")
            }
        }
        return emails
    }
    
    func transformToJSON(_ value: [EmailAddress]?) ->  [String]? {
        guard let value = value else {
            return nil
        }
        var emails: [String] = []
        for email in value {
            emails.append(email.toString())
        }
        return emails
    }
}

class StringAndIntTransform: TransformType {
    
    func transformFromJSON(_ value: Any?) -> Int? {
        if let inputString = value as? String {
            return Int(inputString)
        } else if let inputInt = value as? Int {
            return inputInt
        }
        return nil
    }
    
    func transformToJSON(_ value: Int?) -> String? {
        guard let input = value else {
            return nil
        }
        return String(input)
    }
}

class StringAndBoolTransform: TransformType {
    typealias Object = Bool
    typealias JSON = String
    
    func transformFromJSON(_ value: Any?) -> Object? {
        if let inputString = value as? String {
            switch inputString.lowercased() {
            case "true": return true
            case "false": return false
            default: return nil
            }
        } else if let inputBool = value as? Bool {
            return inputBool
        }
        return nil
    }
    
    func transformToJSON(_ value: Object?) -> JSON? {
        guard let input = value else {
            return nil
        }
        return input ? "true" : "false"
    }
}
