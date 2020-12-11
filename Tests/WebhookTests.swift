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
import XCTest
@testable import WebexSDK

class WebhookTests: XCTestCase {
    private var fixture: WebexTestFixture! = WebexTestFixture.sharedInstance
    private var webhooks: WebhookClient!
    private var spaceId: String!
    private var webhook: Webhook!
    private var webhookId: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCTAssertNotNil(fixture)
        let space = fixture.createSpace(testCase: self, title: "space_for_test")
        spaceId = space?.id
        XCTAssertNotNil(spaceId)
        webhooks = fixture.webex.webhooks
        webhook = createWebhook()
        XCTAssertNotNil(webhook)
        webhookId = webhook.id
        XCTAssertNotNil(webhookId)
    }

    override func tearDown() {
        if let spaceId = spaceId {
            fixture.deleteSpace(testCase: self, spaceId: spaceId)
        }
        if let webhook = webhook, let id = webhook.id {
            deleteWebhook(id: id)
        }
        super.tearDown()
    }
    
    override static func tearDown() {
        Thread.sleep(forTimeInterval: Config.TestcaseInterval)
        super.tearDown()
    }
    
    func testWhenCreateWebhookThenItExistsAndHasAnId() {
        // Tests that basic setup and teardown work without issue.
    }
    
//    func testCreateFilterWebhookThenItExistsAndHasAnId() {
//        let filterWebhook = createFilterWebhook()
//        XCTAssertNotNil(filterWebhook)
//
//        let webhooks = listWebhooks()
//        XCTAssertEqual(webhooks?.count, 2)
//        deleteWebhook(id: filterWebhook!.id!)
//        let webhooks1 = listWebhooks()
//        XCTAssertEqual(webhooks1?.count, 1)
//    }
    
    func testWhenThereIsOneWebhookThenTheListFunctionReturnsOneWebhook() {
        let webhooks = listWebhooks()
        XCTAssertEqual(webhooks?.count, 1)
    }
    
    func testWhenGetWebhookByIDThenReturnedWebhookHasSameID() {
        let gottenWebhook = getWebhook(id: webhookId)
        XCTAssertEqual(gottenWebhook?.id, webhookId)
    }
    
    func testWhenWebhookNameIsUpdatedThenReturnedInfoMatches() {
        let updatedName = "updated_test_webhook"
        let updatedTargetUrl = "https://example.com/updated_test_webhook"
        let updated = updateWebhook(id: webhookId, name: updatedName, targetUrl: updatedTargetUrl)
        XCTAssertEqual(updated?.name, updatedName)
        XCTAssertEqual(updated?.targetUrl, updatedTargetUrl)
    }
    
    func testWhenWebhookIsDeletedThenItCannotBeUpdated() {
        deleteWebhook(id: webhookId)
        let updatedName = "updated_test_webhook"
        let updatedTargetUrl = "https://example.com/updated_test_webhook"
        let updated = updateWebhook(id: webhookId, name: updatedName, targetUrl: updatedTargetUrl)
        XCTAssertNil(updated)
        
    }
    
    func testWhenWebhookIsDeletedThenItCannotBeGotten() {
        deleteWebhook(id: webhookId)
        XCTAssertNil(getWebhook(id: webhookId))
    }
    
    func testWhenWebhookIsDeletedThenItCannotBeListed() {
        deleteWebhook(id: webhookId)
        let webHooks = listWebhooks()
        XCTAssertEqual(webHooks?.count, 0)
    }
    
//    func testCreateSameWebhookThenDeleteIt() {
//        let webhook1 = createWebhook()
//        XCTAssertNotNil(webhook1)
//
//        let webhooks = listWebhooks()
//        XCTAssertEqual(webhooks?.count, 2)
//        deleteWebhook(id: webhook1!.id!)
//        let webhooks1 = listWebhooks()
//        XCTAssertEqual(webhooks1?.count, 1)
//        XCTAssertEqual(webhooks1?.filter(){$0.id == webhook1!.id!}.count, 0)
//
//    }
    
    
    private func createWebhook() -> Webhook? {
        let request = { (completionHandler: @escaping (ServiceResponse<Webhook>) -> Void) in
            self.webhooks.create(name: "test_webhook", targetUrl: "https://example.com/test_webhook", resource: "messages", event: "created", filter: nil, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func createFilterWebhook() -> Webhook? {
        let request = { (completionHandler: @escaping (ServiceResponse<Webhook>) -> Void) in
            self.webhooks.create(name: "test_webhook", targetUrl: "https://example.com/test_webhook", resource: "messages", event: "created", filter: "roomId=" + self.spaceId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func deleteWebhook(id: String) {
        let request = { (completionHandler: @escaping (ServiceResponse<Any>) -> Void) in
            self.webhooks.delete(webhookId: id, completionHandler: completionHandler)
        }
        _ = fixture.getResponse(testCase: self, request: request)
    }
    
    private func listWebhooks() -> [Webhook]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Webhook]>) -> Void) in
            self.webhooks.list(completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func getWebhook(id: String) -> Webhook? {
        let request = { (completionHandler: @escaping (ServiceResponse<Webhook>) -> Void) in
            self.webhooks.get(webhookId: id, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func updateWebhook(id: String, name: String, targetUrl: String) -> Webhook? {
        let request = { (completionHandler: @escaping (ServiceResponse<Webhook>) -> Void) in
            self.webhooks.update(webhookId: id, name: name, targetUrl: targetUrl, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
}
