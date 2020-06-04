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
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SwiftyJSON

enum Service: String {
    case hydra
    case region
    case u2c
    case wdm
    case kms = "encryption"
    case locus
    case conv = "conversation"
    case metrics
    case calliopeDiscovery
    
    func homed(for device: Device?, with hosts: ServiceHostModel? = nil) -> ServiceRequest.Builder {
        return ServiceRequest.Builder(url: self.baseUrl(for: device, with: hosts))
    }
    
    func specific(url: String) -> ServiceRequest.Builder {
        return ServiceRequest.Builder(url: url)
    }
    
    var global: ServiceRequest.Builder {
        return self.homed(for: nil)
    }
    
    private func baseUrl(for device: Device? = nil, with hosts: ServiceHostModel? = nil) -> String {
        switch self {
        case .region:
            return "https://ds.ciscospark.com/v1"
        case .u2c:
            return "https://u2c.wbx2.com/u2c/api/v1"
        case .wdm:
            #if INTEGRATIONTEST
            let `default` = ProcessInfo().environment["WDM_SERVER_ADDRESS"] == nil ? "https://wdm-intb.ciscospark.com/wdm/api/v1" : ProcessInfo().environment["WDM_SERVER_ADDRESS"]!
            #else
            let `default` = "https://wdm-a.wbx2.com/wdm/api/v1"
            #endif
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .hydra:
            #if INTEGRATIONTEST
            let `default` = ProcessInfo().environment["hydraServerAddress"] == nil ? "https://apialpha.ciscospark.com/v1" : ProcessInfo().environment["hydraServerAddress"]!
            #else
            let `default` = "https://api.ciscospark.com/v1"
            #endif
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .kms:
            #if INTEGRATIONTEST
            let `default` = "https://encryption-intb.ciscospark.com/encryption/api/v1"
            #else
            let `default` = "https://encryption-a.wbx2.com/encryption/api/v1"
            #endif
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .conv:
            #if INTEGRATIONTEST
            let `default` = "https://conversation-intb.ciscospark.com/conversation/api/v1"
            #else
            let `default` = "https://conv-a.wbx2.com/conversation/api/v1"
            #endif
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .locus:
            let `default` = "https://locus-a.wbx2.com/locus/api/v1"
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .metrics:
            let `default` = "https://metrics-a.wbx2.com/metrics/api/v1"
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        case .calliopeDiscovery:
            let `default` = "https://calliope-a.wbx2.com/calliope/api/discovery/v1"
            return self.dynamicUrl(device: device, hosts: hosts, default: `default`)
        }
    }
    
    private func dynamicUrl(device: Device?, hosts: ServiceHostModel?, default: String) -> String {
        var ret: String? = nil
        if let device = device, let url = device[service: self.rawValue] {
            ret = url
        }
        if ret == nil, let hosts = hosts, let url = hosts.serviceLinks?[self.rawValue] {
            ret = url
        }
        return ret ?? `default`
    }
}

class ServiceRequest : RequestRetrier, RequestAdapter {
    
    private let tokenPrefix: String = "Bearer "
    private var pendingTimeCount : Int = 0
    private let url: URL
    private let headers: [String: String]
    private let method: Alamofire.HTTPMethod
    private let body: RequestParameter?
    private let query: RequestParameter?
    private let keyPath: String?
    private let queue: DispatchQueue?
    private let authenticator: Authenticator?
    private var newAccessToken: String? = nil
    private var refreshTokenCount = 0
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()
    
    private init(authenticator: Authenticator? = nil, url: URL, headers: [String: String], method: Alamofire.HTTPMethod, body: RequestParameter?, query: RequestParameter?, keyPath: String?, queue: DispatchQueue?) {
        self.authenticator = authenticator
        self.url = url
        self.headers = headers
        self.method = method
        self.body = body
        self.query = query
        self.keyPath = keyPath
        self.queue = queue
    }
    
    class Builder {
        
        private var authenticator: Authenticator?
        private var headers: [String: String]
        private var method: Alamofire.HTTPMethod
        private var baseUrl: URL
        private var path: String
        private var body: RequestParameter?
        private var query: RequestParameter?
        private var keyPath: String?
        private var queue: DispatchQueue?
        
        fileprivate init(url: String) {
            self.headers = ["Content-Type": "application/json",
                            "TrackingID": TrackingId.generator.next,
                            "User-Agent": UserAgent.string,
                            "Webex-User-Agent": UserAgent.string]
            self.baseUrl = URL(string: url)!
            self.method = .get
            self.path = ""
        }
        
        var url: URL {
            return self.baseUrl.appendingPathComponent(self.path)
        }
        
        func build() -> ServiceRequest {
            return ServiceRequest(authenticator: self.authenticator,
                                  url: self.baseUrl.appendingPathComponent(self.path),
                                  headers: self.headers,
                                  method: self.method,
                                  body: self.body,
                                  query: self.query,
                                  keyPath: self.keyPath,
                                  queue: self.queue)
        }
        
        func authenticator(_ authenticator: Authenticator) -> Builder {
            self.authenticator = authenticator
            return self
        }
        
        func method(_ method: Alamofire.HTTPMethod) -> Builder {
            self.method = method
            return self
        }
        
        func headers(_ headers: [String: String]) -> Builder {
            self.headers.unionInPlace(headers)
            return self
        }
        
        func baseUrl(_ baseUrl: String) -> Builder {
            self.baseUrl = URL(string: baseUrl)!
            return self
        }
        
        func baseUrl(_ baseUrl: URL) -> Builder {
            self.baseUrl = baseUrl
            return self
        }
        
        func path(_ path: String) -> Builder {
            self.path += "/" + path
            return self
        }
        
        func body(_ body: RequestParameter) -> Builder {
            self.body = body
            return self
        }
        
        func body(_ body: [String: Any?]) -> Builder {
            self.body = RequestParameter(body)
            return self
        }
        
        func query(_ query: RequestParameter) -> Builder {
            self.query = query
            return self
        }
        
        func query(_ query: [String: Any?]) -> Builder {
            self.query = RequestParameter(query)
            return self
        }
        
        func keyPath(_ keyPath: String) -> Builder {
            self.keyPath = keyPath
            return self
        }
        
        func queue(_ queue: DispatchQueue?) -> Builder {
            self.queue = queue
            return self
        }
    }
    
    func responseObject<T: BaseMappable>(_ completionHandler: @escaping (ServiceResponse<T>) -> Void) {
        let tempQueue = self.queue
        let tempKeyPath = self.keyPath
        createAlamofireRequest() { request in
            request.responseObject(queue: tempQueue, keyPath: tempKeyPath) { (response: DataResponse<T>) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<T>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(var error):
                    if response.response != nil {
                        if let data = response.data {
                            error = WebexError.requestErrorWith(data: data)
                        }
                    }
                    result = .failure(error)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseArray<T: BaseMappable>(_ completionHandler: @escaping (ServiceResponse<[T]>) -> Void) {
        let tempQueue = self.queue
        let tempKeyPath = self.keyPath
        createAlamofireRequest() { request in
            request.responseArray(queue: tempQueue, keyPath: tempKeyPath) { (response: DataResponse<[T]>) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<[T]>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(var error):
                    if response.response != nil {
                        if let data = response.data {
                            error = WebexError.requestErrorWith(data: data)
                        }
                    }
                    result = .failure(error)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseJSON(_ completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let tempQueue = self.queue
        createAlamofireRequest() { request in
            request.responseJSON(queue: tempQueue) { (response: DataResponse<Any>) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<Any>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(var error):
                    if response.response != nil {
                        if let data = response.data {
                            error = WebexError.requestErrorWith(data: data)
                        }
                    }
                    result = .failure(error)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseString(_ completionHandler: @escaping (ServiceResponse<String>) -> Void) {
        let tempQueue = self.queue
        createAlamofireRequest() { request in
            request.responseString(queue: tempQueue) { (response: DataResponse<String>) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<String>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(var error):
                    if response.response != nil {
                        if let data = response.data {
                            error = WebexError.requestErrorWith(data: data)
                        }
                    }
                    result = .failure(error)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    private func createAlamofireRequest(completionHandler: @escaping (Alamofire.DataRequest) -> Void) {
        let accessTokenCallback: (String?) -> Void = { accessToken in
            var headerDict = self.headers
            let tempTokenPrefix = self.tokenPrefix
            if let accessToken = accessToken {
                headerDict["Authorization"] = tempTokenPrefix + accessToken
            }
            
            let urlRequestConvertible: URLRequestConvertible
            do {
                var urlRequest = try URLRequest(url: self.url, method: self.method, headers: headerDict)
                //disable http local cache data.
                urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
                if let body = self.body {
                    urlRequest = try JSONEncoding.default.encode(urlRequest, with: body.value())
                }
                if let query = self.query {
                    urlRequest = try URLEncoding.default.encode(urlRequest, with: query.value())
                }
                urlRequestConvertible = urlRequest
            } catch {
                class ErrorRequestConvertible : URLRequestConvertible {
                    private let error: Error
                    
                    init(_ error: Error) {
                        self.error = error
                    }
                    
                    func asURLRequest() throws -> URLRequest {
                        throw self.error
                    }
                }
                urlRequestConvertible = ErrorRequestConvertible(error)
            }
            self.sessionManager.retrier = self
            self.sessionManager.adapter = self
            self.sessionManager.delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
                var finalRequest = request
                if let accessToken = accessToken {
                    finalRequest.setValue(tempTokenPrefix + accessToken, forHTTPHeaderField: "Authorization")
                }
                return finalRequest
            }
            let request = self.sessionManager.request(urlRequestConvertible).validate()
            SDKLogger.shared.verbose(request.debugDescription)
            completionHandler(request)
        }
        
        if let authenticator = authenticator {
            authenticator.accessToken { accessToken in
                accessTokenCallback(accessToken)
            }
        } else {
            accessTokenCallback(nil)
        }
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        let tempTokenPrefix = self.tokenPrefix
        if let newToken = self.newAccessToken, let _ =  urlRequest.value(forHTTPHeaderField: "Authorization") {
            urlRequest.setValue(tempTokenPrefix + newToken, forHTTPHeaderField: "Authorization")
            self.refreshTokenCount += 1
        }
        return urlRequest
    }
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 429 {
            if var retryAfter = response.allHeaderFields["Retry-After"] as? Int {
                if retryAfter > 3600 {
                    retryAfter = 3600
                } else if retryAfter == 0 {
                    retryAfter = 60
                }
                self.pendingTimeCount += retryAfter
                completion(true, TimeInterval(retryAfter))
            }
        } else if let authenticator = self.authenticator, let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            authenticator.refreshToken(completionHandler: { accessToken in
                if accessToken == nil {
                    self.newAccessToken = accessToken
                    completion(false, 0.0)
                } else {
                    if self.refreshTokenCount >= 2 {// After Refreshed token twice, if still get 401 from server, returns error.
                        completion(false, 0.0)
                    } else {
                        self.newAccessToken = accessToken
                        completion(true, 0.0)
                    }
                }
            })
        } else {
            completion(false, 0.0)
        }
    }
}

extension WebexError {
    /// Converts the error data to NSError
    static func requestErrorWith(data: Data) -> Error {
        var failureReason = "Service request failed without error message"
        do {
            if let errorMessage = try JSON(data: data)["message"].string  {
                failureReason = errorMessage
            }
        } catch {
            
        }
        return WebexError.serviceFailed(code: -7000, reason: failureReason)
    }
}

