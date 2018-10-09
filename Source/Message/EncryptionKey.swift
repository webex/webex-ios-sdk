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

class EncryptionKey {
    
    let spaceId: String // locus format
    var spaceUserIds: [String] = []
    
    private var encryptionUrl: String?
    private var material: String?
    private var spaceUrl: String?
    
    init(spaceId: String) {
        self.spaceId = spaceId
    }
    
    func tryRefresh(encryptionUrl: String) {
        if self.encryptionUrl != encryptionUrl {
            self.encryptionUrl = encryptionUrl
            self.material = nil
        }
    }
    
    func material(client: MessageClientImpl, completionHandler: @escaping (SResult<String>) -> Void) {
        if let marterial = self.material {
            completionHandler(SResult.success(marterial))
        }
        else {
            self.encryptionUrl(client: client) { response in
                if let error = response.error {
                    completionHandler(SResult<String>.failure(error))
                }
                else {
                    let encrptionUrl = response.data as? String
                    client.requestSpaceKeyMaterial(spaceId: self.spaceId, encryptionUrl: encrptionUrl) { result in
                        switch result {
                        case .success(let data):
                            self.encryptionUrl = data.0
                            self.material = data.1
                            completionHandler(SResult<String>.success(data.1))
                        case .failure(let error):
                            completionHandler(SResult<String>.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func encryptionUrl(client: MessageClientImpl, completionHandler: @escaping (SResult<String?>) -> Void) {
        if let url = self.encryptionUrl {
            completionHandler(SResult.success(url))
        }
        else {
            client.requestSpaceEncryptionURL(spaceId: self.spaceId) { result in
                self.encryptionUrl = result.data as? String
                completionHandler(result)
            }
        }
    }
    
    func spaceUrl(authenticator: Authenticator, completionHandler: @escaping (SResult<String>) -> Void) {
        if let url = self.spaceUrl {
            completionHandler(SResult.success(url))
        }
        else {
            let request = ServiceRequest.Builder(authenticator).baseUrl(ServiceRequest.conversationServerAddress)
                .path("conversations/" + self.spaceId.locusFormat + "/space")
                .method(.put)
                .build()
            request.responseJSON { (response: ServiceResponse<Any>) in
                if let dict = response.result.data as? [String: Any], let url = dict["spaceUrl"] as? String {
                    self.spaceUrl = url
                    completionHandler(SResult.success(url))
                }
                else {
                    completionHandler(SResult.failure(response.result.error ?? MessageClientImpl.MSGError.spaceUrlFetchFail))
                }
            }
        }
    }
}
