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

import UIKit
import Alamofire
import ObjectMapper

class UploadFileOperations {
    
    private let queue = SerialQueue()
    
    private var operations: [UploadFileOperation]
    
    init(key: EncryptionKey, files: [LocalFile]) {
        self.operations = files.map { file in
            return UploadFileOperation(key: key, local: file)
        }
    }
    
    func run(client: MessageClient, completionHandler: @escaping (Result<[FileModel]>) -> Void) {
        var sucess = [FileModel]()
        self.operations.forEach { operation in
            if !operation.done {
                self.queue.sync {
                    operation.run(client: client) { result in
                        if let file = result.data {
                            sucess.append(file)
                        }
                        self.queue.yield()
                    }
                }
            }
        }
        self.queue.sync {
            completionHandler(Result.success(sucess))
        }
    }
}

class UploadFileOperation {
    
    let local: LocalFile
    private let key: EncryptionKey
    private(set) var done: Bool = false
    lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        return Session(configuration: configuration, redirectHandler: WebexRedirectHandler())
    }()
    
    init(key: EncryptionKey, local: LocalFile) {
        self.local = local
        self.key = key
    }

    func run(client: MessageClient, completionHandler: @escaping (Result<FileModel>) -> Void) {
        self.doUpload(client: client, path: self.local.path, size: self.local.size, progressStart: 0, progressHandler: self.local.progressHandler) { fileUrl, fileScr, error in
            if let fileUrl = fileUrl, let fileScr = fileScr, let fileModel = Mapper<FileModel>().map(JSON: ["objectType": ObjectType.file.rawValue, "displayName": self.local.name, "mimeType": self.local.mime, "fileSize": self.local.size, "url": fileUrl]) {
                fileModel.scrObject = fileScr
                if let thumb = self.local.thumbnail {
                    self.doUpload(client: client, path: thumb.path, size: thumb.size, progressStart: 0.5, progressHandler: self.local.progressHandler) { thumbUrl, thumbScr, error in
                        if let thumbUrl = thumbUrl, let imageModel = Mapper<ImageModel>().map(JSON: ["width": thumb.width, "height": thumb.height, "mimeType": thumb.mime, "url": thumbUrl]), let thumbScr = thumbScr {
                            imageModel.scrObject = thumbScr
                            fileModel.image = imageModel
                        }
                        self.done = true
                        self.key.material(client: client) { material in
                            fileModel.encrypt(key: material.data)
                            completionHandler(Result.success(fileModel))
                        }
                    }
                }
                else {
                    self.done = true
                    self.key.material(client: client) { material in
                        fileModel.encrypt(key: material.data)
                        completionHandler(Result.success(fileModel))
                    }
                }
            }
            else {
                self.done = true
                (error ?? WebexError.serviceFailed(reason: "upload error")).report(resultCallback: completionHandler)
            }
        }
    }

    private func doUpload(client: MessageClient, path: String, size: UInt64, progressStart: Double, progressHandler: ((Double) -> Void)?, completionHandler: @escaping (String?, SecureContentReference?, Error?) -> Void) {
        client.authenticator.accessToken { token in
            guard let token = token else {
                completionHandler(nil, nil, WebexError.noAuth)
                return
            }
            self.key.spaceUrl(client: client) { result in
                if let url = result.data {
                    let headers: HTTPHeaders = ["Authorization": "Bearer " + token, "Content-Type": "application/json;charset=UTF-8", "TrackingID": TrackingId.generator.next, "User-Agent": UserAgent.string, "Webex-User-Agent": UserAgent.string]
                    self.session.request(url + "/upload_sessions", method: .post, parameters: ["uploadProtocol":"content-length"], encoding: JSONEncoding.default, headers: headers).responseJSON { (prepareResponse) in
                        SDKLogger.shared.verbose(prepareResponse.debugDescription)
                        if let dict = prepareResponse.value as? [String : Any], let uploadUrl = dict["uploadUrl"] as? String, let finishUrl = dict["finishUploadUrl"] as? String,
                           let scr = try? SecureContentReference(error: ()),
                           let inputStream = try? SecureInputStream(stream: InputStream(fileAtPath: path), scr: scr) {
                            SDKLogger.shared.debug("Uploading file \(path), \(size)")
                            self.session.upload(inputStream, to: uploadUrl, method: .put, headers: ["Content-Length": String(size)]).uploadProgress(closure: { (progress) in
                                progressHandler?(progressStart + progress.fractionCompleted/2)
                            }).responseString(emptyResponseCodes: emptyResponseCodes) { uploadResponse in
                                SDKLogger.shared.verbose(uploadResponse.debugDescription)
                                if let _ = uploadResponse.value {
                                    let headers: HTTPHeaders = ["Authorization": "Bearer " + token, "Content-Type": "application/json;charset=UTF-8", "TrackingID": TrackingId.generator.next, "User-Agent": UserAgent.string, "Webex-User-Agent": UserAgent.string]
                                    self.session.request(finishUrl, method: .post, parameters: ["size": size], encoding: JSONEncoding.default, headers: headers).responseJSON { finishResponse in
                                        SDKLogger.shared.verbose(finishResponse.debugDescription)
                                        if let dict = finishResponse.value as? [String : Any], let downLoadUrl = dict["downloadUrl"] as? String, let url = URL(string: downLoadUrl) {
                                            scr.loc = url
                                            completionHandler(downLoadUrl, scr, nil)
                                        }
                                        else {
                                            completionHandler(nil, nil, finishResponse.error)
                                        }
                                    }
                                }
                                else {
                                    completionHandler(nil, nil, uploadResponse.error)
                                }
                            }
                        }
                        else {
                            completionHandler(nil, nil, prepareResponse.error)
                        }
                    }
                }
                else {
                    completionHandler(nil, nil, result.error)
                }
            }
        }
    }
}
