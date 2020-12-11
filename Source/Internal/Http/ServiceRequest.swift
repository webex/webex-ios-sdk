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
import Alamofire
import ObjectMapper
import SwiftyJSON

enum ServiceError {
    enum locus : Int {
        case requireModeratorPinOrGuest = 2423005
        case requireModeratorPinOrGuestPin = 2423006
        case requireModeratorKeyOrMeetingPassword = 2423016
        case requireModeratorKeyOrGuest = 2423017
        case requireMeetingPassword = 2423018
    }
}


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
    
    func homed(for device: Device?) -> ServiceRequest.Builder {
        return ServiceRequest.make(self.baseUrl(for: device))
    }

    var global: ServiceRequest.Builder {
        return ServiceRequest.make(self.baseUrl())
    }
    
    func baseUrl(for device: Device? = nil) -> String {
        switch self {
        case .region:
            return "https://ds.ciscospark.com/v1"
        case .u2c:
            #if INTEGRATIONTEST
            return "https://u2c-intb.ciscospark.com/u2c/api/v1"
            #else
            return "https://u2c.wbx2.com/u2c/api/v1"
            #endif
        case .wdm:
            #if INTEGRATIONTEST
            let `default` = ProcessInfo().environment["WDM_SERVER_ADDRESS"] == nil ? "https://wdm-intb.ciscospark.com/wdm/api/v1" : ProcessInfo().environment["WDM_SERVER_ADDRESS"]!
            #else
            let `default` = "https://wdm-a.wbx2.com/wdm/api/v1"
            #endif
            return self.baseUrl(device: device, default: `default`)
        case .hydra:
            #if INTEGRATIONTEST
            let `default` = ProcessInfo().environment["hydraServerAddress"] == nil ? "https://apialpha.ciscospark.com/v1" : ProcessInfo().environment["hydraServerAddress"]!
            #else
            let `default` = "https://api.ciscospark.com/v1"
            #endif
            return self.baseUrl(device: device, default: `default`)
        case .kms:
            #if INTEGRATIONTEST
            let `default` = "https://encryption-intb.ciscospark.com/encryption/api/v1"
            #else
            let `default` = "https://encryption-a.wbx2.com/encryption/api/v1"
            #endif
            return self.baseUrl(device: device, default: `default`)
        case .conv:
            #if INTEGRATIONTEST
            let `default` = "https://conversation-intb.ciscospark.com/conversation/api/v1"
            #else
            let `default` = "https://conv-a.wbx2.com/conversation/api/v1"
            #endif
            return self.baseUrl(device: device, default: `default`)
        case .locus:
            return self.baseUrl(device: device, default: "https://locus-a.wbx2.com/locus/api/v1")
        case .metrics:
            return self.baseUrl(device: device, default: "https://metrics-a.wbx2.com/metrics/api/v1")
        case .calliopeDiscovery:
            return self.baseUrl(device: device, default: "https://calliope-a.wbx2.com/calliope/api/discovery/v1")
        }
    }
    
    private func baseUrl(device: Device?, default: String) -> String {
        return device?[service: self.rawValue] ?? `default`
    }
}

let emptyResponseCodes:Set<Int> = [200, 202, 204, 205]
class ServiceRequest : RequestRetrier, RequestAdapter {

    static func make(_ url: String) -> ServiceRequest.Builder {
        return ServiceRequest.Builder(url: url)
    }
    
    private let tokenPrefix: String = "Bearer "
    private var pendingTimeCount : Int = 0
    private let url: URL
    private let headers: [String: String]
    private let method: Alamofire.HTTPMethod
    private let body: RequestParameter?
    private let query: RequestParameter?
    private let form: Bool
    private let keyPath: String?
    private let queue: DispatchQueue?
    private let authenticator: Authenticator?
    private var accessToken: String? = nil
    private var newAccessToken: String? = nil
    private var refreshTokenCount = 0
    private let redirectHandler = WebexRedirectHandler()
    lazy var sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        return Session(configuration: configuration, redirectHandler: self.redirectHandler)
    }()
    
    
    private init(authenticator: Authenticator? = nil, url: URL, headers: [String: String], method: Alamofire.HTTPMethod, body: RequestParameter?, query: RequestParameter?, form: Bool?, keyPath: String?, queue: DispatchQueue?) {
        self.authenticator = authenticator
        self.url = url
        self.headers = headers
        self.method = method
        self.body = body
        self.query = query
        self.keyPath = keyPath
        self.queue = queue
        if let form = form {
            self.form = form
        }
        else {
            self.form = self.headers["Content-Type"]?.contains("x-www-form-urlencoded") ?? false
        }
    }
    
    class Builder {
        
        private var authenticator: Authenticator?
        private var headers: [String: String]
        private var method: Alamofire.HTTPMethod
        private var baseUrl: URL
        private var path: String
        private var body: RequestParameter?
        private var query: RequestParameter?
        private var form: Bool?
        private var keyPath: String?
        private var queue: DispatchQueue?
        
        fileprivate init(url: String) {
            self.headers = ["Content-Type": "application/json;charset=UTF-8",
                            "User-Agent": UserAgent.string]
            if url.isTrustedDomain() {
                self.headers["TrackingID"] = TrackingId.generator.next
                self.headers["Webex-User-Agent"] = UserAgent.string
            }
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
                    form: self.form,
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

        func body(_ body: [String: Any?]) -> Builder {
            self.body = RequestParameter(body)
            return self
        }

        func query(_ query: [String: Any?]) -> Builder {
            self.query = RequestParameter(query)
            return self
        }

        func form(_ form: Bool) -> Builder {
            self.form = form
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
        makeRequest() { request in
            request.responseJSON(queue: tempQueue ?? .main) { (response) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<T>
                switch response.result {
                case .success(let value):
                    let objectJson: Any?
                    if let keyPath = tempKeyPath , keyPath.isEmpty == false {
                        objectJson = (value as AnyObject?)?.value(forKeyPath: keyPath)
                    }else {
                        objectJson = value
                    }
                    if let parsedObject = Mapper<T>(shouldIncludeNilValues: false).map(JSONObject: objectJson) {
                        result = .success(parsedObject)
                    }else {
                        result = .failure(WebexError.serviceFailed(reason: "Response Serialization Failed"))
                    }
                case .failure(let error):
                    var webexError:Error = error
                    if let _ = response.response, let data = response.data {
                        webexError = WebexError.requestErrorWith(data: data)
                    }
                    result = .failure(webexError)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseArray<T: BaseMappable>(_ completionHandler: @escaping (ServiceResponse<[T]>) -> Void) {
        let tempQueue = self.queue
        let tempKeyPath = self.keyPath
        makeRequest() { request in
            request.responseJSON(queue: tempQueue ?? .main) { (response) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<[T]>
                switch response.result {
                case .success(let value):
                    let objectJson: Any?
                    if let keyPath = tempKeyPath , keyPath.isEmpty == false {
                        objectJson = (value as AnyObject?)?.value(forKeyPath: keyPath)
                    }else {
                        objectJson = value
                    }
                    if let parsedObject = Mapper<T>(shouldIncludeNilValues: false).mapArray(JSONObject: objectJson) {
                        result = .success(parsedObject)
                    }else {
                        result = .failure(WebexError.serviceFailed(reason: "Response Serialization Failed"))
                    }
                case .failure(let error):
                    var webexError:Error = error
                    if let _ = response.response, let data = response.data {
                        webexError = WebexError.requestErrorWith(data: data)
                    }
                    result = .failure(webexError)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseJSON(_ completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let tempQueue = self.queue
        makeRequest() { request in
            request.responseJSON(queue: tempQueue ?? .main) { (response) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<Any>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(let error):
                    var webexError:Error = error
                    if let _ = response.response, let data = response.data {
                        webexError = WebexError.requestErrorWith(data: data)
                    }
                    result = .failure(webexError)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    func responseString(_ completionHandler: @escaping (ServiceResponse<String>) -> Void) {
        let tempQueue = self.queue
        makeRequest() { request in
            request.responseString(queue: tempQueue ?? .main, emptyResponseCodes: emptyResponseCodes) { (response) in
                SDKLogger.shared.verbose(response.debugDescription)
                var result: Result<String>
                switch response.result {
                case .success(let value):
                    result = .success(value)
                case .failure(let error):
                    var webexError:Error = error
                    if let _ = response.response, let data = response.data {
                        webexError = WebexError.requestErrorWith(data: data)
                    }
                    result = .failure(webexError)
                }
                completionHandler(ServiceResponse(response.response, result))
            }
        }
    }
    
    private func makeRequest(completionHandler: @escaping (Alamofire.DataRequest) -> Void) {
        let accessTokenCallback: (String?) -> Void = { accessToken in
            var headerDict = self.headers
            let tempTokenPrefix = self.tokenPrefix
            if let accessToken = accessToken {
                headerDict["Authorization"] = tempTokenPrefix + accessToken
            }
            
            let urlRequestConvertible: URLRequestConvertible
            do {
                var urlRequest = try URLRequest(url: self.url, method: self.method, headers: HTTPHeaders(headerDict))
                //disable http local cache data.
                urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
                if let body = self.body {
                    let parameterEncoding: ParameterEncoding = self.form ? URLEncoding.httpBody : JSONEncoding.default
                    urlRequest = try parameterEncoding.encode(urlRequest, with: body.value())
                }
                if let query = self.query {
                    urlRequest = try URLEncoding.queryString.encode(urlRequest, with: query.value())
                }
                urlRequestConvertible = urlRequest
            } catch {
                class ErrorRequestConvertible : URLRequestConvertible {
                    let error: Error
                    
                    init(_ error: Error) {
                        self.error = error
                    }
                    
                    func asURLRequest() throws -> URLRequest {
                        throw self.error
                    }
                }
                urlRequestConvertible = ErrorRequestConvertible(error)
            }
            
            let interceptor = Interceptor(adapter: Adapter(self.adapt(_:for:completion:)), retrier: Retrier(self.retry(_:for:dueTo:completion:)))
            let request = self.sessionManager.request(urlRequestConvertible, interceptor: interceptor).validate()
            SDKLogger.shared.verbose(request.description)
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
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        let tempTokenPrefix = self.tokenPrefix
        if let newToken = self.newAccessToken, let _ =  urlRequest.value(forHTTPHeaderField: "Authorization") {
            urlRequest.setValue(tempTokenPrefix + newToken, forHTTPHeaderField: "Authorization")
            self.refreshTokenCount += 1
        }
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 429 {
            if var retryAfter = response.allHeaderFields["Retry-After"] as? Int {
                if retryAfter > 3600 {
                    retryAfter = 3600
                }
                else if retryAfter == 0 {
                    retryAfter = 60
                }
                self.pendingTimeCount += retryAfter
                completion(.retryWithDelay(TimeInterval(retryAfter)))
            }
        }
        else if let authenticator = self.authenticator, let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            authenticator.refreshToken(completionHandler: { accessToken in
                if accessToken == nil {
                    self.newAccessToken = accessToken
                    completion(.doNotRetry)
                } else {
                    if self.refreshTokenCount >= 2 {// After Refreshed token twice, if still get 401 from server, returns error.
                        completion(.doNotRetry)
                    } else {
                        self.newAccessToken = accessToken
                        completion(.retry)
                    }
                }
            })
        } else {
            completion(.doNotRetry)
        }
    }
}

fileprivate extension WebexError {
    /// Converts the error data to NSError
    static func requestErrorWith(data: Data) -> Error {
        var failureReason = "Service request failed without error message"
        do {
            let json = try JSON(data: data)
            if let errorMessage = json["message"].string  {
                failureReason = errorMessage
            }
            if let code = json["errorCode"].int  {
                switch code {
                case ServiceError.locus.requireModeratorPinOrGuest.rawValue,
                     ServiceError.locus.requireModeratorPinOrGuestPin.rawValue,
                     ServiceError.locus.requireMeetingPassword.rawValue,
                     ServiceError.locus.requireModeratorKeyOrGuest.rawValue,
                     ServiceError.locus.requireModeratorKeyOrMeetingPassword.rawValue:
                    return WebexError.requireHostPinOrMeetingPassword(reason: failureReason)
                default:
                    return WebexError.serviceFailed(reason: failureReason)
                }
            }
        } catch {
            
        }
        return WebexError.serviceFailed(reason: failureReason)
    }
}

fileprivate struct RequestParameter {

    private var storage: [String: Any] = [:]

    init(_ parameters: [String: Any?] = [:]) {
        for (key, value) in parameters {
            guard let realValue = value else {
                continue
            }
            switch realValue {
            case let bool as Bool:
                storage.updateValue(String(bool), forKey: key)
            default:
                storage.updateValue(realValue, forKey: key)
            }
        }
    }

    func value() -> [String: Any] {
        return storage
    }
}

struct WebexRedirectHandler : RedirectHandler {
    
    func task(_ task: URLSessionTask, willBeRedirectedTo request: URLRequest, for response: HTTPURLResponse, completion: @escaping (URLRequest?) -> Void) {
        var redirectedRequest = request
        if let originalRequest = task.originalRequest, let headers = originalRequest.allHTTPHeaderFields, let authorizationHeaderValue = headers["Authorization"] {
            var mutableRequest = request
            mutableRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
            if let urlStr = mutableRequest.url?.absoluteString, !urlStr.isTrustedDomain() {
                mutableRequest.setValue(nil, forHTTPHeaderField: "TrackingID")
                mutableRequest.setValue(nil, forHTTPHeaderField: "Webex-User-Agent")
                mutableRequest.setValue(nil, forHTTPHeaderField: "Cisco-Request-ID")
            }
            redirectedRequest = mutableRequest
        }
        completion(redirectedRequest)
    }
}

