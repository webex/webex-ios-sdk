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

import UIKit
import Alamofire

class UploadFileOperations {
    
    private let queue = SerialQueue()
    
    private var operations: [UploadFileOperation]
    
    init(key: EncryptionKey, files: [LocalFile]) {
        self.operations = files.map { file in
            return UploadFileOperation(key: key, local: file)
        }
    }
    
    func run(client: MessageClientImpl, completionHandler: @escaping (Result<[RemoteFile]>) -> Void) {
        var sucess = [RemoteFile]()
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
    
    init(key: EncryptionKey, local: LocalFile) {
        self.local = local
        self.key = key
    }
    
    func run(client: MessageClientImpl, completionHandler: @escaping (Result<RemoteFile>) -> Void) {
        self.doUpload(client: client, path: self.local.path, size: self.local.size, progressStart: 0, progressHandler: self.local.progressHandler) { url, scr, error in
            if let url = url, let scr = scr {
                self.key.material(client: client) { material in
                    var file = RemoteFile(local: self.local, downloadUrl: url)
                    file.encrypt(key: material.data, scr: scr)
                    if let thumb = self.local.thumbnail {
                        self.doUpload(client: client, path: thumb.path, size: thumb.size, progressStart: 0.5, progressHandler: self.local.progressHandler) { url, scr, error in
                            if let url = url, let scr = scr {
                                var thumb = RemoteFile.Thumbnail(local: thumb, downloadUrl: url)
                                thumb.encrypt(key: material.data, scr: scr)
                                file.thumbnail = thumb
                            }
                            self.done = true
                            completionHandler(Result.success(file))
                        }
                    }
                    else {
                        self.done = true
                        completionHandler(Result.success(file))
                    }
                }
            }
            else {
                SDKLogger.shared.info("File Uoload Fail...")
                self.done = true
                completionHandler(Result.failure(error ?? WebexError.serviceFailed(code: -7000, reason: "upload error")))
            }
        }
    }
    
    func doUpload(client: MessageClientImpl, path: String, size: UInt64, progressStart: Double, progressHandler: ((Double) -> Void)?, completionHandler: @escaping (String?, SecureContentReference?, Error?) -> Void) {
        client.authenticator.accessToken { token in
            guard let token = token else {
                completionHandler(nil, nil, WebexError.noAuth)
                return
            }
            self.key.spaceUrl(authenticator: client.authenticator) { result in
                if let url = result.data {
                    let headers: HTTPHeaders  = ["Authorization": "Bearer " + token]
                    let parameters: Parameters = ["fileSize": size]
                    Alamofire.request(url + "/upload_sessions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response: DataResponse<Any>) in
                        if let dict = response.result.value as? [String : Any],
                            let uploadUrl = dict["uploadUrl"] as? String,
                            let finishUrl = dict["finishUploadUrl"] as? String,
                            let scr = try? SecureContentReference(error: ()),
                            let inputStream = try? SecureInputStream(stream: InputStream(fileAtPath: path), scr: scr) {
                            let uploadHeaders: HTTPHeaders = ["Content-Length": String(size)]
                            Alamofire.upload(inputStream, to: uploadUrl, method: .put, headers: uploadHeaders).uploadProgress(closure: { (progress) in
                                progressHandler?(progressStart + progress.fractionCompleted/2)
                            }).responseString { response in
                                if let _ = response.result.value {
                                    let finishHeaders: HTTPHeaders = ["Authorization": "Bearer " + token, "Content-Type": "application/json;charset=UTF-8"]
                                    let finishParameters: Parameters = ["size": size]
                                    Alamofire.request(finishUrl, method: .post, parameters: finishParameters, encoding: JSONEncoding.default, headers: finishHeaders).responseJSON { response in
                                        if let dict = response.result.value as? [String : Any], let downLoadUrl = dict["downloadUrl"] as? String, let url = URL(string: downLoadUrl) {
                                            scr.loc = url
                                            completionHandler(downLoadUrl, scr, nil)
                                        }
                                        else {
                                            completionHandler(nil, nil, response.error)
                                        }
                                    }
                                }
                                else {
                                    completionHandler(nil, nil, response.error)
                                }
                            }
                        }
                        else {
                            completionHandler(nil, nil, response.error)
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
