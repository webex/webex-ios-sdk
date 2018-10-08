// Copyright 2016-2018 Cisco Systems Inc
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
import Alamofire
import SwiftyJSON

class MessageClientImpl {
    
    class MSGError {
        static let spaceFetchFail = WebexError.serviceFailed(code: -7000, reason: "Space Fetch Fail")
        static let clientInfoFetchFail = WebexError.serviceFailed(code: -7000, reason: "Client Info Fetch Fail")
        static let ephemaralKeyFetchFail = WebexError.serviceFailed(code: -7000, reason: "EphemaralKey Fetch Fail")
        static let kmsInfoFetchFail = WebexError.serviceFailed(code: -7000, reason: "KMS Info Fetch Fail")
        static let keyMaterialFetchFail = WebexError.serviceFailed(code: -7000, reason: "Key Info Fetch Fail")
        static let encryptionUrlFetchFail = WebexError.serviceFailed(code: -7000, reason: "Encryption Info Fetch Fail")
        static let spaceUrlFetchFail = WebexError.serviceFailed(code: -7000, reason: "Space Info Fetch Fail")
        static let emptyTextError = WebexError.serviceFailed(code: -7000, reason: "Expected Text Not Found")
        static let downloadError = WebexError.serviceFailed(code: -7000, reason: "Expected File Not Found")
        static let timeOut = WebexError.serviceFailed(code: -7000, reason: "Timeout")
    }
    
    private enum ObjectType : String {
        case activity
        case comment
        case content
        case conversation
    }
    
    private static let kmsMsgServerUrl = URL(string: ServiceRequest.kmsServerAddress + "/kms/messages")!
    
    var onEvent: ((MessageEvent) -> Void)?
    
    let authenticator: Authenticator
    var deviceUrl : URL
    
    private let queue = SerialQueue()
    
    private var uuid: String = UUID().uuidString
    private var userId : String?
    private var kmsCluster: String?
    private var rsaPublicKey: String?
    private var ephemeralKey: String?
    private var keySerialization: String?
    
    private var ephemeralKeyRequest: (KmsEphemeralKeyRequest, (Error?) -> Void)?
    private var keyMaterialCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [String: [(Result<(String, String)>) -> Void]]()
    private var keysCompletionHandlers: [String: [(Result<(String, String)>) -> Void]] = [String: [(Result<(String, String)>) -> Void]]()
    private var encryptionKeys: [String: EncryptionKey] = [String: EncryptionKey]()
    private var spaces: [String: String] = [String: String]()
    private typealias KeyHandler = (Result<(String, String)>) -> Void
    
    init(authenticator: Authenticator, deviceUrl: URL) {
        self.authenticator = authenticator
        self.deviceUrl = deviceUrl
    }
    
    func list(spaceId: String,
              mentionedPeople: Mention? = nil,
              before: Before? = nil,
              max: Int,
              queue: DispatchQueue? = nil,
              completionHandler: @escaping (ServiceResponse<[Message]>) -> Void) {
        
        if max == 0 {
            (queue ?? DispatchQueue.main).async {
                completionHandler(ServiceResponse(nil, Result.success([])))
            }
            return
        }
        
        if let before = before {
            switch before {
            case .message(let messageId):
                self.get(messageId: messageId, decrypt: false, queue: queue) { response in
                    if let error = response.result.error {
                        completionHandler(ServiceResponse(response.response, Result.failure(error)))
                    }
                    else {
                        self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: response.result.data?.created, max:max, result: [], completionHandler: completionHandler)
                    }
                }
            case .date(let date):
                listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: date, max:max, result: [], completionHandler: completionHandler)
            }
        }
        else {
            listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: nil, max:max, result: [], completionHandler: completionHandler)
        }
    }
    
    private func listBefore(spaceId: String, mentionedPeople: Mention? = nil, date: Date?, max: Int, result: [ActivityModel], queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Message]>) -> Void) {
        let dateKey = mentionedPeople == nil ? "maxDate" : "sinceDate"
        let request = self.messageServiceBuilder.path(mentionedPeople == nil ? "activities" : "mentions")
            .keyPath("items")
            .method(.get)
            .query(RequestParameter(["conversationId": spaceId.locusFormat, "limit": max, dateKey: (date ?? Date()).iso8601String]))
            .queue(queue)
            .build()
        request.responseArray { (response: ServiceResponse<[ActivityModel]>) in
            switch response.result {
            case .success:
                guard let responseValue = response.result.data else { return }
                let result = result + responseValue.filter({$0.kind == ActivityModel.Kind.post || $0.kind == ActivityModel.Kind.share})
                if result.count >= max || responseValue.count < max {
                    let key = self.encryptionKey(spaceId: spaceId)
                    key.material(client: self) { material in
                        if let material = material.data {
                            let messages = result.prefix(max).map { $0.decrypt(key: material) }.map { Message(activity: $0) }
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.success(messages)))
                            }
                        }
                        else {
                            (queue ?? DispatchQueue.main).async {
                                completionHandler(ServiceResponse(response.response, Result.failure(material.error ?? MSGError.keyMaterialFetchFail)))
                            }
                        }
                    }
                }
                else {
                    self.listBefore(spaceId:spaceId, mentionedPeople: mentionedPeople, date: responseValue.last?.created, max:max, result: result, completionHandler: completionHandler)
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }
    
    func get(messageId: String, decrypt: Bool, queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        let request = self.messageServiceBuilder.path("activities")
            .method(.get)
            .path(messageId.locusFormat)
            .queue(queue)
            .build()
        request.responseObject { (response : ServiceResponse<ActivityModel>) in
            switch response.result {
            case .success(let activity):
                if let spaceId = activity.spaceId, decrypt {
                    let key = self.encryptionKey(spaceId: spaceId)
                    key.material(client: self) { material in
                        (queue ?? DispatchQueue.main).async {
                            completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity.decrypt(key: material.data)))))
                        }
                    }
                }
                else {
                    completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity))))
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }
    
    func post(person: String,
              text: String? = nil,
              files: [LocalFile]? = nil,
              queue: DispatchQueue? = nil,
              completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        self.lookupSpace(person: person, queue: queue) { result in
            if let spaceId = result.data {
                self.post(spaceId: spaceId, text: text, files: files, queue: queue, completionHandler: completionHandler)
            }
            else {
                completionHandler(ServiceResponse(nil, Result.failure(result.error ?? MSGError.spaceFetchFail)))
            }
        }
    }
    
    func post(spaceId: String,
              text: String? = nil,
              mentions: [Mention]? = nil,
              files: [LocalFile]? = nil,
              queue: DispatchQueue? = nil,
              completionHandler: @escaping (ServiceResponse<Message>) -> Void) {
        var object = [String: Any]()
        object["objectType"] = ObjectType.comment.rawValue
        object["displayName"] = text
        object["content"] = text
        var mentionedGroup = [[String: String]]()
        var mentionedPeople = [[String: String]]()
        mentions?.forEach { mention in
            switch mention {
            case .all:
                mentionedGroup.append(["objectType": "groupMention", "groupType": "all"])
            case .person(let person):
                mentionedPeople.append(["objectType": "person", "id": person.locusFormat])
            }
        }
        object["mentions"] = ["items" : mentionedPeople]
        object["groupMentions"] = ["items" : mentionedGroup]
        
        var verb = ActivityModel.Kind.post
        let key = self.encryptionKey(spaceId: spaceId)
        key.material(client: self) { material in
            if let material = material.data, let encrypt = text?.encrypt(key: material) {
                object["displayName"] = encrypt
                object["content"] = encrypt
            }
            let opeations = UploadFileOperations(key: key, files: files ?? [LocalFile]())
            opeations.run(client: self) { result in
                if let files = result.data, files.count > 0 {
                    object["objectType"] = ObjectType.content.rawValue
                    object["contentCategory"] = "documents"
                    object["files"] = ["items": files.toJSON()]
                    verb = ActivityModel.Kind.share
                }
                let target: [String: Any] = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                key.encryptionUrl(client: self) { encryptionUrl in
                    postMessageRequest(encryptionUrl: encryptionUrl, material: material,target: target)
                }
            }
        }
        
        func postMessageRequest(encryptionUrl: Result<String?>, material: Result<String>, target: [String: Any]){
            if let url = encryptionUrl.data {
                let body = RequestParameter(["verb": verb.rawValue, "encryptionKeyUrl": url, "object": object, "target": target, "clientTempId": "\(self.uuid):\(UUID().uuidString)", "kmsMessage": self.keySerialization ?? nil])
                let request = self.messageServiceBuilder.path("activities")
                    .method(.post)
                    .body(body)
                    .queue(queue)
                    .build()
                request.responseObject { (response: ServiceResponse<ActivityModel>) in
                    switch response.result{
                    case .success(let activity):
                        completionHandler(ServiceResponse(response.response, Result.success(Message(activity: activity.decrypt(key: material.data)))))
                    case .failure(let error):
                        completionHandler(ServiceResponse(response.response, Result.failure(error)))
                    }
                }
            }
            else {
                (queue ?? DispatchQueue.main).async {
                    completionHandler(ServiceResponse(nil, Result.failure(encryptionUrl.error ?? MSGError.encryptionUrlFetchFail)))
                }
            }
        }
    }
    
    func delete(messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = self.messageServiceBuilder.path("activities")
            .method(.get)
            .path(messageId.locusFormat)
            .queue(queue)
            .build()
        request.responseObject { (response : ServiceResponse<ActivityModel>) in
            switch response.result {
            case .success(let activity):
                if let spaceId = activity.spaceId {
                    let object: [String: Any] = ["id": messageId.locusFormat, "objectType": ObjectType.activity.rawValue]
                    let target: [String: Any] = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                    let body = RequestParameter(["verb": ActivityModel.Kind.delete.rawValue, "object": object, "target": target])
                    let request = self.messageServiceBuilder.path("activities")
                        .method(.post)
                        .body(body)
                        .queue(queue)
                        .build()
                    request.responseJSON(completionHandler)
                }
                else {
                    (queue ?? DispatchQueue.main).async {
                        completionHandler(ServiceResponse(response.response, Result.failure(response.result.error ?? MSGError.spaceFetchFail)))
                    }
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
                break
            }
        }
    }
    
    func downloadFile(_ file: RemoteFile, to: URL? = nil, queue: DispatchQueue? = nil, progressHandler: ((Double)->Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        if let source = file.url {
            let operation = DownloadFileOperation(authenticator: self.authenticator,
                                                  uuid: self.uuid,
                                                  source: source,
                                                  displayName: file.displayName,
                                                  secureContentRef: file.secureContentRef,
                                                  thnumnail: false,
                                                  target: to,
                                                  queue: queue,
                                                  progressHandler: progressHandler,
                                                  completionHandler: completionHandler)
            operation.run()
        }
        else {
            completionHandler(Result.failure(MSGError.downloadError))
        }
    }
    
    func downloadThumbnail(for file: RemoteFile, to: URL? = nil,  queue: DispatchQueue? = nil, progressHandler: ((Double)->Void)? = nil, completionHandler: @escaping (Result<URL>) -> Void) {
        if let source = file.thumbnail?.url {
            let operation = DownloadFileOperation(authenticator: self.authenticator,
                                                  uuid: self.uuid,
                                                  source: source,
                                                  displayName: file.displayName,
                                                  secureContentRef: file.thumbnail?.secureContentRef,
                                                  thnumnail: true,
                                                  target: to,
                                                  queue: queue,
                                                  progressHandler: progressHandler,
                                                  completionHandler: completionHandler)
            operation.run()
        }
        else {
            completionHandler(Result.failure(MSGError.downloadError))
        }
    }
    
    // MARK: Encryption Feature Functions
    func handle(activity: ActivityModel) {
        guard let spaceId = activity.spaceId else {
            SDKLogger.shared.error("Not a space message \(activity.id ?? (activity.toJSONString() ?? ""))")
            return
        }
        if let clientTempId = activity.clientTempId, clientTempId.starts(with: self.uuid) {
            return
        }
        let key = self.encryptionKey(spaceId: spaceId)
        if let encryptionUrl = activity.encryptionKeyUrl {
            key.tryRefresh(encryptionUrl: encryptionUrl)
        }
        key.material(client: self) { material in
            var decryption = activity.decrypt(key: material.data)
            guard let kind = decryption.kind else {
                SDKLogger.shared.error("Not a valid message \(activity.id ?? (activity.toJSONString() ?? ""))")
                return
            }
            DispatchQueue.main.async {
                switch kind {
                case .post, .share:
                    decryption.toPersonId = self.userId?.hydraFormat(for: .people)
                    self.onEvent?(MessageEvent.messageReceived(Message(activity: decryption)))
                case .delete:
                    self.onEvent?(MessageEvent.messageDeleted(decryption.id ?? "illegal id"))
                default:
                    SDKLogger.shared.error("Not a valid message \(activity.id ?? (activity.toJSONString() ?? ""))")
                }
            }
        }
    }
    
    func handle(kms: KmsMessageModel) {
        if let response = kms.kmsMessages?.first {
            if let request = self.ephemeralKeyRequest {
                handleEphemeralKeyRequest(request: request, response: response)
            }
            else {
                handleSpaceKeyMaterialRequest(response: response)
            }
        }
    }
    
    private func handleEphemeralKeyRequest(request: (KmsEphemeralKeyRequest, (Error?) -> Void), response: String) {
        if let key = try? KmsEphemeralKeyResponse(responseMessage: response, request: request.0).jwkEphemeralKey {
            self.ephemeralKey = key
            request.1(nil)
        }
        else {
            request.1(MSGError.ephemaralKeyFetchFail)
        }
        self.ephemeralKeyRequest = nil
    }
    
    private func handleSpaceKeyMaterialRequest(response: String) {
        if let key = self.ephemeralKey, let data = try? CjoseWrapper.content(fromCiphertext: response, key: key), let json = try? JSON(data: data) {
            if let key = json["key"].object as? [String:Any] {
                if let jwk = key["jwk"], let uri = key["uri"], let keyMaterial = JSON(jwk).rawString(), let keyUri = JSON(uri).rawString() {
                    if var handlers = self.keyMaterialCompletionHandlers[keyUri], handlers.count > 0 {
                        let handler = handlers.removeFirst()
                        self.keyMaterialCompletionHandlers[keyUri] = handlers
                        handler(Result.success((keyUri, keyMaterial)))
                    }
                    if let handlers = self.keyMaterialCompletionHandlers[keyUri], handlers.count == 0 {
                        self.keyMaterialCompletionHandlers[keyUri] = nil
                    }
                }
            }
            else if let dict = (json["keys"].object as? [[String : Any]])?.first {
                if let key = try? KmsKey(from: dict), let spaceId = self.keysCompletionHandlers.keys.first ,let handlers = self.keysCompletionHandlers.popFirst()?.value  {
                    self.updateConversationWithKey(key: key, spaceId: spaceId, handlers: handlers)
                }
            }
        }
    }
    
    func requestSpaceEncryptionURL(spaceId: String, completionHandler: @escaping (Result<String?>) -> Void) {
        self.prepareEncryptionKey { error in
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }
            
            func handleResourceObjectUrl(dict: [String: Any]) {
                if let paticipients = dict["participants"] as? [String: Any], let participantsArray = paticipients["items"] as? [[String: Any]]{
                    participantsArray.forEach{ pdict in
                        if let userId = pdict["entryUUID"] as? String{
                            if !self.encryptionKey(spaceId: spaceId).spaceUserIds.contains(userId){
                                self.encryptionKey(spaceId: spaceId).spaceUserIds.append(userId)
                            }
                        }
                    }
                }
                completionHandler(Result.success(nil))
            }
            
            let request = self.messageServiceBuilder.path("conversations/" + spaceId.locusFormat)
                .query(RequestParameter(["includeActivities": false, "includeParticipants": true]))
                .method(.get)
                .build()
            request.responseJSON { (response: ServiceResponse<Any>) in
                if let dict = response.result.data as? [String: Any] {
                    if let spaceEncryptionUrl = (dict["encryptionKeyUrl"] ?? dict["defaultActivityEncryptionKeyUrl"]) as? String{
                        completionHandler(Result.success(spaceEncryptionUrl))
                    }else if let _ = dict["kmsResourceObjectUrl"] {
                        handleResourceObjectUrl(dict: dict)
                    }
                }
                else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.encryptionUrlFetchFail))
                }
            }
        }
    }
    
    func requestSpaceKeyMaterial(spaceId: String, encryptionUrl: String?, completionHandler: @escaping (Result<(String, String)>) -> Void) {
        self.prepareEncryptionKey { error in
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }
            self.authenticator.accessToken { token in
                guard let token = token else {
                    completionHandler(Result.failure(WebexError.noAuth))
                    return
                }
                guard let userId = self.userId, let ephemeralKey = self.ephemeralKey else {
                    completionHandler(Result.failure(MSGError.ephemaralKeyFetchFail))
                    return
                }
                self.processSpaceKeyMaterialRequest(spaceId: spaceId, encryptionUrl: encryptionUrl, token: token, userId: userId, ephemeralKey: ephemeralKey, completionHandler: completionHandler)
            }
        }
    }
    
    private func processSpaceKeyMaterialRequest(spaceId: String, encryptionUrl: String?, token: String, userId: String, ephemeralKey: String?, completionHandler: @escaping (Result<(String, String)>) -> Void){
        let header: [String: String]  = ["Cisco-Request-ID": self.uuid, "Authorization": "Bearer " + token]
        var parameters: [String: Any]?
        var failed: () -> Void
        if let encryptionUrl = encryptionUrl {
            if let request = try? KmsRequest(requestId: self.uuid, clientId: self.deviceUrl.absoluteString, userId: userId, bearer: token, method: "retrieve", uri: encryptionUrl),
                let serialize = request.serialize(),
                let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                self.keySerialization = chiperText
                parameters = ["kmsMessages": [chiperText], "destination": "unused" ] as [String : Any]
                var handlers: [(Result<(String, String)>) -> Void] = self.keyMaterialCompletionHandlers[encryptionUrl] ?? []
                handlers.append(completionHandler)
                self.keyMaterialCompletionHandlers[encryptionUrl] = handlers
            }
            failed = {
                self.keyMaterialCompletionHandlers[encryptionUrl]?.forEach { $0(Result.failure(MSGError.keyMaterialFetchFail)) }
                self.keyMaterialCompletionHandlers[encryptionUrl] = nil
            }
        }
        else {
            if let request = try? KmsRequest(requestId: self.uuid, clientId: self.deviceUrl.absoluteString, userId: userId, bearer: token, method: "create", uri: "/keys") {
                request.additionalAttributes = ["count": 1]
                if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: ephemeralKey) {
                    self.keySerialization = chiperText
                    parameters = ["kmsMessages": [chiperText], "destination": "unused" ] as [String: Any]
                    var handlers: [(Result<(String, String)>) -> Void] = self.keysCompletionHandlers[spaceId] ?? []
                    handlers.append(completionHandler)
                    self.keysCompletionHandlers[spaceId] = handlers
                }
            }
            failed = {
                self.keysCompletionHandlers[spaceId]?.forEach { $0(Result.failure(MSGError.keyMaterialFetchFail)) }
                self.keysCompletionHandlers[spaceId] = nil
            }
        }
        if let parameters = parameters, parameters.count >= 2 {
            Alamofire.request(MessageClientImpl.kmsMsgServerUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header).responseString { (response) in
                SDKLogger.shared.debug("RequestKMS Material Response ============  \(response)")
                if response.result.isFailure {
                    failed()
                }
            }
        }
        else {
            failed()
        }
    }
    
    private func prepareEncryptionKey(completionHandler: @escaping (Error?) -> Void) {
        func validateResult(_ error: Error?) -> Bool {
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                self.queue.yield()
                return false
            }
            return true
        }
        
        func processResult() {
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
        
        func validateKeyRequest(error: Error?) {
            if validateResult(error) {
                self.requestEphemeralKey { error in
                    if validateResult(error) {
                        self.queue.yield()
                        processResult()
                    }
                }
            }
        }
        self.queue.sync {
            self.requestUserId { error in
                if validateResult(error) {
                    self.requestClusterAndRSAPubKey { error in
                        validateKeyRequest(error: error)
                    }
                }
            }
        }
    }
    
    private func requestUserId(completionHandler: @escaping (Error?) -> Void) {
        if self.userId != nil {
            completionHandler(nil)
            return
        }
        let request = self.messageServiceBuilder.path("users")
            .method(.get)
            .build()
        request.responseJSON { (response: ServiceResponse<Any>) in
            if let usersDict = response.result.data as? [String: Any], let userId = usersDict["id"] as? String {
                self.userId = userId
                completionHandler(nil)
            }
            else {
                completionHandler(MSGError.clientInfoFetchFail)
            }
        }
    }
    
    private func requestClusterAndRSAPubKey(completionHandler: @escaping (Error?) -> Void) {
        if self.kmsCluster != nil && self.rsaPublicKey != nil {
            completionHandler(nil)
            return
        }
        let request =  ServiceRequest.Builder(self.authenticator).baseUrl(ServiceRequest.kmsServerAddress).path("kms")
            .method(.get)
            .build()
        request.responseJSON { (response: ServiceResponse<Any>) in
            if let kmsDict = response.result.data as? [String: Any], let kmsCluster = kmsDict["kmsCluster"] as? String, let rsaPublicKey = kmsDict["rsaPublicKey"] as? String {
                self.kmsCluster = kmsCluster
                self.rsaPublicKey = rsaPublicKey
                completionHandler(nil)
            }
            else {
                completionHandler(MSGError.clientInfoFetchFail)
            }
        }
    }
    
    private func requestEphemeralKey(completionHandler: @escaping (Error?) -> Void) {
        if self.ephemeralKey != nil {
            completionHandler(nil)
            return
        }
        self.authenticator.accessToken { token in
            guard let token = token else {
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            if (self.ephemeralKeyRequest != nil) {
                SDKLogger.shared.debug("Request EphemeralKey duplicated")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            guard let userId = self.userId, let cluster = self.kmsCluster, let clusterURI = URL(string: cluster), let rsaPubKey = self.rsaPublicKey else {
                SDKLogger.shared.debug("Request EphemeralKey failed")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            let ecdhe = clusterURI.appendingPathComponent("ecdhe").absoluteString
            guard let request = try? KmsEphemeralKeyRequest(requestId: self.uuid, clientId: self.deviceUrl.absoluteString , userId: userId, bearer: token , method: "create", uri: ecdhe, kmsStaticKey: rsaPubKey), let message = request.message else {
                SDKLogger.shared.debug("Request EphemeralKey failed, illegal ephemeral key request")
                completionHandler(MSGError.ephemaralKeyFetchFail)
                return
            }
            self.ephemeralKeyRequest = (request, completionHandler)
            let parameters: [String: String] = ["kmsMessages": message, "destination": cluster]
            let header: [String: String]  = ["Cisco-Request-ID": self.uuid, "Authorization" : "Bearer " + token]
            Alamofire.request(MessageClientImpl.kmsMsgServerUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header).responseString { response in
                SDKLogger.shared.debug("Request EphemeralKey Response ============ \(response)")
                if response.result.isFailure {
                    self.ephemeralKeyRequest = nil
                    completionHandler(MSGError.ephemaralKeyFetchFail)
                }
            }
        }
    }
    
    private func updateConversationWithKey(key: KmsKey, spaceId: String, handlers: [KeyHandler]) {
        self.authenticator.accessToken{ token in
            let spaceUserIds = self.encryptionKey(spaceId: spaceId).spaceUserIds
            if let request = try? KmsRequest(requestId: self.uuid, clientId: self.deviceUrl.absoluteString, userId: self.userId, bearer: token, method: "create", uri: "/resources") {
                request.additionalAttributes = ["keyUris":[key.uri],"userIds": spaceUserIds]
                if let serialize = request.serialize(), let chiperText = try? CjoseWrapper.ciphertext(fromContent: serialize.data(using: .utf8), key: self.ephemeralKey) {
                    var object = [String: Any]()
                    object["objectType"] = ObjectType.conversation.rawValue
                    object["defaultActivityEncryptionKeyUrl"] = key.uri
                    let target: [String: Any] = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
                    let verb = ActivityModel.Kind.updateKey
                    let body = RequestParameter(["objectType":"activity",
                                                 "verb": verb.rawValue,
                                                 "object": object,
                                                 "target": target,
                                                 "kmsMessage":chiperText])
                    let request = self.messageServiceBuilder.path("activities")
                        .method(.post)
                        .body(body)
                        .build()
                    request.responseJSON { (response: ServiceResponse<Any>) in
                        switch response.result {
                        case .success(_):
                            handlers.forEach { $0(Result.success((key.uri, key.jwk))) }
                        case .failure(let error):
                            handlers.forEach { $0(Result.failure(error)) }
                            break
                        }
                    }
                }
            }
        }
    }
    
    private var messageServiceBuilder: ServiceRequest.Builder {
        return ServiceRequest.Builder(self.authenticator).baseUrl(ServiceRequest.conversationServerAddress)
    }
    
    private func encryptionKey(spaceId: String) -> EncryptionKey {
        var key = self.encryptionKeys[spaceId]
        if key == nil {
            key = EncryptionKey(spaceId: spaceId)
            self.encryptionKeys[spaceId] = key
        }
        return key!
    }
    
    private func lookupSpace(person: String, queue: DispatchQueue?, completionHandler: @escaping (Result<String>) -> Void) {
        if let spaceId = self.spaces[person] {
            (queue ?? DispatchQueue.main).async {
                completionHandler(Result.success(spaceId))
            }
        }
        else {
            let request = self.messageServiceBuilder.path("conversations/user/" + person.locusFormat)
                .method(.put)
                .query(RequestParameter(["activitiesLimit": 0, "compact": true]))
                .queue(queue)
                .build()
            request.responseObject { (response: ServiceResponse<Space>) in
                if let space = response.result.data?.id {
                    let spaceId = space.hydraFormat(for: .room)
                    self.spaces[person] = spaceId
                    completionHandler(Result.success(spaceId))
                }
                else {
                    completionHandler(Result.failure(response.result.error ?? MSGError.spaceFetchFail))
                }
            }
        }
    }
}

extension Date {
    
    var iso8601String: String {
        return Timestamp.iSO8601FullFormatterInUTC.string(from: self.addingTimeInterval(-0.1))
    }
    
    static func fromISO860(_ string: String) -> Date? {
        return  Timestamp.iSO8601FullFormatterInUTC.date(from:string)
    }
}
