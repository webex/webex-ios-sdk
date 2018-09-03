//
//  AuxiliaryVideo.swift
//  WebexSDKTests
//
//  Created by panzh on 2018/7/27.
//  Copyright © 2018 Cisco. All rights reserved.
//

import XCTest
@testable import WebexSDK

class AuxiliaryVideoTest: XCTestCase {
    
    private var fixture: WebexTestFixture! = WebexTestFixture.sharedInstance
    private static var remoteUsers:Array<TestUser> = []
    private var call:Call?
    private var phone: Phone!
    private var localView:MediaRenderView?
    private var remoteView:MediaRenderView?
    private var screenShareView:MediaRenderView?
    private var fakeCallClient:FakeCallClient?
    private var fakeWebSocketService:FakeWebSocketService?
    private var fakeDeviceService:FakeDeviceService?
    private var fakeConversationClient:FakeConversationClient?
    private var fakeWME:FakeWME?
    private var auxStreamObserver:TestObserver?
    private var remoteUser:TestUser? {
        get {
           return AuxiliaryVideoTest.remoteUsers.first
        }
    }
    private var otherUsers:[TestUser]? {
        get {
            return Array<TestUser>(AuxiliaryVideoTest.remoteUsers.dropFirst())
        }
    }
    // MARK: - life cycle
    override class func tearDown() {
        remoteUsers.removeAll()
    }
    
    override func setUp() {
        continueAfterFailure = false
        XCTAssertNotNil(fixture)
        let authenticator = fixture.webex.authenticator
        self.fakeDeviceService = FakeDeviceService(authenticator: authenticator)
        self.fakeCallClient = FakeCallClient(authenticator: authenticator)
        self.fakeCallClient?.selfUser = fixture.selfUser
        self.fakeWebSocketService = FakeWebSocketService(authenticator: authenticator)
        self.fakeConversationClient = FakeConversationClient(authenticator: authenticator)
        self.fakeWME = FakeWME()
        let metricsEngine = MetricsEngine(authenticator: authenticator, service: self.fakeDeviceService!)
        phone = Phone(authenticator: authenticator, devices: self.fakeDeviceService!, reachability: FakeReachabilityService(authenticator: authenticator, deviceService: self.fakeDeviceService!), client: self.fakeCallClient!, conversations: self.fakeConversationClient!, metrics: metricsEngine, prompter: H264LicensePrompter(metrics: metricsEngine), webSocket: self.fakeWebSocketService!)
        phone.disableVideoCodecActivation()
        
        XCTAssertNotNil(phone)
        
        XCTAssertTrue(registerPhone())
        localView = MediaRenderView()
        remoteView = MediaRenderView()
        screenShareView = MediaRenderView()
        auxStreamObserver = TestObserver()
        self.call = mockCall(isGroup: true)
        self.call?.multiStreamObserver = self.auxStreamObserver
    }
    
    override func tearDown() {
        self.call = nil
        XCTAssertTrue(deregisterPhone())
        localView = nil
        remoteView = nil
    }
    
    // MARK: - mock metod
    private func mockCall(isGroup:Bool) -> Call? {
        var tryCount = 0
        while AuxiliaryVideoTest.remoteUsers.count < maxAuxStreamNumber+3 && tryCount < 30 {
            if let user = self.fixture.createUser() {
                AuxiliaryVideoTest.remoteUsers.append(user)
            }
            tryCount = tryCount + 1
        }
        
        if let callee = self.remoteUser, self.otherUsers?.count ?? 0 >= maxAuxStreamNumber {
            let callModel = FakeCallModelHelper.dialCallModel(caller: self.fixture.selfUser, callee: callee, otherParticipantUsers: (self.otherUsers ?? []))
            let mediaSession = MediaSessionWrapper()
            mediaSession.setMediaSession(mediaSession: fakeWME!)
            
            mediaSession.prepare(option: MediaOption.audioVideoScreenShare(video: (local:self.localView!,remote:self.remoteView!), screenShare: self.screenShareView!), phone: self.phone)
            let call = Call(model: callModel, device: (self.fakeDeviceService?.device)!, media: mediaSession, direction: Call.Direction.outgoing, group: isGroup, uuid: nil)
            mediaSession.startMedia(call: call)
            return call
        }
        
        return nil
    }
    
    private func registerPhone() -> Bool {
        var success = false
        
        let expect = expectation(description: "Phone registration")
        phone.register() { error in
            success = (error == nil)
            expect.fulfill()
        }
        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error, "Phone registration timed out")
        }
        return success
    }
    
    private func deregisterPhone() -> Bool {
        guard let phone = phone else {
            return false
        }
        
        var success = false
        
        let expect = expectation(description: "Phone deregistration")
        phone.deregister() { error in
            success = (error == nil)
            expect.fulfill()
        }
        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error, "Phone deregistration timed out")
        }
        
        return success
    }
    
    class TestObserver: MultiStreamObserver {
        var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)?
        var auxStreamAvailable: (() -> MediaRenderView?)?
        var onAuxStreamUnavailable: (() -> MediaRenderView?)?
    }
    
    // MARK: - Test cases
    func testOpenAuxStreamSuccess() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            let renderView = MediaRenderView()
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                        case .success(let auxStream):
                            XCTAssertNotNil(auxStream)
                            expect.fulfill()
                        case .failure(_):
                            XCTAssertTrue(false)
                    }
                    XCTAssertEqual(view, renderView)
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                return renderView
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count:1+Call.activeSpeakerCount, call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testOpenMaximumAuxStream() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = maxAuxStreamNumber*2
            
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        XCTAssertEqual(view, auxStream.renderView)
                        expect.fulfill()
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                return MediaRenderView()
            }
            
            FakeWME.stubStreamsCountNotification(count: maxAuxStreamNumber+Call.activeSpeakerCount, call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAvailableCountMoreThanMaximumAuxStream() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = maxAuxStreamNumber
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                return nil
            }
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            FakeWME.stubStreamsCountNotification(count: maxAuxStreamNumber+Call.activeSpeakerCount+2, call: self.call!)
            
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAvailableCountIncrease() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = maxAuxStreamNumber
            var count = 1 + Call.activeSpeakerCount
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                if count <= self.otherUsers?.count ?? 0 {
                    count = count + 1
                    FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                }
                return nil
            }
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAvailableCountDecrease() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let availableExpect = expectation(description: "on available")
            availableExpect.expectedFulfillmentCount = maxAuxStreamNumber
            let unavailableExpect = expectation(description: "on unavailable")
            unavailableExpect.expectedFulfillmentCount = maxAuxStreamNumber
            let closedExpect = expectation(description: "on closed")
            closedExpect.expectedFulfillmentCount = maxAuxStreamNumber
            var count = maxAuxStreamNumber + Call.activeSpeakerCount
            self.auxStreamObserver?.auxStreamAvailable = {
                availableExpect.fulfill()
                return MediaRenderView()
            }
            
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(_, let result):
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        if maxAuxStreamNumber == self.call?.auxStreams.count ?? 0 {
                            count = count - 1
                            FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                        }
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamClosedEvent(_, let error):
                    XCTAssertNil(error)
                    if count > Call.activeSpeakerCount {
                        count = count - 1
                        FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                    }
                    closedExpect.fulfill()
                default:
                    break
                }
            }
            
            self.auxStreamObserver?.onAuxStreamUnavailable = {
                unavailableExpect.fulfill()
                return nil
            }
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAvailableCountDecreaseAndUserRelease() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let availableExpect = expectation(description: "on available")
            availableExpect.expectedFulfillmentCount = maxAuxStreamNumber
            let unavailableExpect = expectation(description: "on unavailable")
            unavailableExpect.expectedFulfillmentCount = maxAuxStreamNumber
            let closedExpect = expectation(description: "on closed")
            closedExpect.expectedFulfillmentCount = 2
            var count = maxAuxStreamNumber + Call.activeSpeakerCount
            var renderViewArray = Array<MediaRenderView>()
            self.auxStreamObserver?.auxStreamAvailable = {
                availableExpect.fulfill()
                
                if renderViewArray.count >= 2 {
                    return nil
                } else {
                    renderViewArray.append(MediaRenderView())
                    return renderViewArray.last
                }
            }
            
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(_, let result):
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        if 2 == self.call?.auxStreams.count ?? 0 {
                            count = count - 1
                            FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                        }
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamClosedEvent(_, let error):
                    XCTAssertNil(error)
                    if count > Call.activeSpeakerCount {
                        count = count - 1
                        FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                    }
                    closedExpect.fulfill()
                default:
                    break
                }
            }
            
            self.auxStreamObserver?.onAuxStreamUnavailable = {
                unavailableExpect.fulfill()
                if let renderView = renderViewArray.last {
                    renderViewArray.removeLast()
                    return renderView
                }
                if count > Call.activeSpeakerCount {
                    count = count - 1
                    FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
                }
                return nil
            }
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            FakeWME.stubStreamsCountNotification(count: count, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testExceededAuxStream() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = maxAuxStreamNumber * 2
            let expectFail = expectation(description: "open AuxStream fail")
            expectFail.expectedFulfillmentCount = 1
            
            var first = true
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        XCTAssertEqual(view, auxStream.renderView)
                        expect.fulfill()
                        if first && self.call?.availableAuxStreamCount ?? 0 >= 4 {
                            first = false
                            self.call?.openAuxStream(view: MediaRenderView())
                        }
                    case .failure(let error):
                        XCTAssertNotNil(view)
                        XCTAssertNotNil(error)
                        expectFail.fulfill()
                    }
                    
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                
                return MediaRenderView()
            }
            
            FakeWME.stubStreamsCountNotification(count: maxAuxStreamNumber + Call.activeSpeakerCount, call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testOpenAuxStreamFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                    case .success(_):
                        XCTAssertTrue(false)
                    case .failure(let error):
                        XCTAssertNotNil(view)
                        XCTAssertNotNil(error)
                        expect.fulfill()
                    }
                    
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                self.fakeWME?.stubOpenFailed = true
                return MediaRenderView()
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testCloseAuxStreamSuccess() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            let renderView = MediaRenderView()
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        XCTAssertEqual(renderView, view)
                        XCTAssertEqual(view, auxStream.renderView)
                        expect.fulfill()
                        self.call?.closeAuxStream(view: renderView)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamClosedEvent(let view, let error):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNil(error)
                    expect.fulfill()
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            
            
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testCloseAuxStreamFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 3
            
            let renderView = MediaRenderView()
            var first = true
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view,let result):
                    switch result {
                    case .success(let auxStream):
                        XCTAssertNotNil(auxStream)
                        XCTAssertEqual(renderView, view)
                        XCTAssertEqual(view, auxStream.renderView)
                        expect.fulfill()
                        self.call?.closeAuxStream(view: renderView)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamClosedEvent(let view, let error):
                    if first {
                        XCTAssertEqual(view, renderView)
                        XCTAssertNil(error)
                        expect.fulfill()
                        first = false
                        self.call?.closeAuxStream(view: renderView)
                    } else {
                        XCTAssertEqual(view, renderView)
                        XCTAssertNotNil(error)
                        expect.fulfill()
                    }
                    
                    break
                default:
                    break
                }
                
            }
            
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testActiveSpeakerChangedEvent() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .activeSpeakerChangedEvent(let from,let to):
                    XCTAssertNil(from)
                    XCTAssertNotNil(to)
                    XCTAssertTrue(to?.personId == user.personId)
                    XCTAssertTrue(self.call?.activeSpeaker?.id == to?.id)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubActiveSpeakerChangeNotification(csi: user.csi,call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testActiveSpeakerChangedToNobody() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .activeSpeakerChangedEvent(let from,let to):
                    if self.call?.activeSpeaker == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertTrue(from?.personId == user.personId)
                        XCTAssertNil(self.call?.activeSpeaker)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(to?.personId == user.personId)
                        XCTAssertTrue(self.call?.activeSpeaker?.id == to?.id)
                        FakeWME.stubActiveSpeakerChangeNotification(csi: [],call: self.call!)
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubActiveSpeakerChangeNotification(csi: user.csi,call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testActiveSpeakerChangedToNobodyByLocus() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .activeSpeakerChangedEvent(let from,let to):
                    if self.call?.activeSpeaker == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertTrue(from?.personId == user.personId)
                        XCTAssertNil(self.call?.activeSpeaker)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(to?.personId == user.personId)
                        XCTAssertTrue(self.call?.activeSpeaker?.id == to?.id)
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubActiveSpeakerChangeNotification(csi: user.csi,call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testActiveSpeakerChangedToNobodyByLocusAndMedia() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .activeSpeakerChangedEvent(let from,let to):
                    if self.call?.activeSpeaker == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertTrue(from?.personId == user.personId)
                        XCTAssertNil(self.call?.activeSpeaker)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(to?.personId == user.personId)
                        XCTAssertTrue(self.call?.activeSpeaker?.id == to?.id)
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                        FakeWME.stubActiveSpeakerChangeNotification(csi: [],call: self.call!)
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubActiveSpeakerChangeNotification(csi: user.csi,call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamPersonChangedEvent() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: user.csi)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamPersonChangedEvent(let aux, let from, let to):
                    XCTAssertNil(from)
                    XCTAssertNotNil(to)
                    XCTAssertEqual(aux.renderView, auxStream?.renderView)
                    XCTAssertTrue(auxStream?.person?.id == to?.id)
                    XCTAssertTrue(auxStream?.person?.id == aux.person?.id)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamPersonChangedToNobody() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 3
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: user.csi)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamPersonChangedEvent(let aux, let from, let to):
                    if aux.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                        XCTAssertTrue(auxStream?.person?.id == to?.id)
                        XCTAssertTrue(auxStream?.person?.id == aux.person?.id)
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: [])
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamPersonChangedToNobodyByLocus() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 3
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: user.csi)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamPersonChangedEvent(let aux, let from, let to):
                    if aux.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                        XCTAssertTrue(auxStream?.person?.id == to?.id)
                        XCTAssertTrue(auxStream?.person?.id == aux.person?.id)
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamPersonChangedToNobodyByLocusAndMedia() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 3
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: user.csi)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                    break
                case .auxStreamPersonChangedEvent(let aux, let from, let to):
                    if aux.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                        XCTAssertTrue(auxStream?.person?.id == to?.id)
                        XCTAssertTrue(auxStream?.person?.id == aux.person?.id)
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream!,From: nil,To: nil), call: self.call!,csi: [])
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAuxStreamSendingVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        self.fakeWME?.stubRemoteAuxMuted = false
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamSendingVideoEvent(aux), call: self.call!)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                case .auxStreamSendingVideoEvent(let aux):
                    XCTAssertEqual(aux.renderView, auxStream?.renderView)
                    XCTAssertTrue(aux.isSendingVideo)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testRemoteMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 3
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        self.fakeWME?.stubRemoteAuxMuted = false
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamSendingVideoEvent(aux), call: self.call!)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                case .auxStreamSendingVideoEvent(let aux):
                    if aux.isSendingVideo {
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                        self.fakeWME?.stubRemoteAuxMuted = true
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamSendingVideoEvent(aux), call: self.call!)
                    } else {
                        XCTAssertEqual(aux.renderView, auxStream?.renderView)
                        XCTAssertTrue(aux.isSendingVideo == false)
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAuxStreamSizeChanged() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let size = CGSize(width: 200, height: 300)
            
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            let renderView = MediaRenderView()
            var auxStream: AuxStream?
            self.auxStreamObserver?.auxStreamAvailable = {
                return renderView
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(let aux):
                        auxStream = aux
                        XCTAssertEqual(renderView, aux.renderView)
                        expect.fulfill()
                        self.fakeWME?.stubAuxSize = size
                        FakeWME.stubAuxStreamEvent(eventType: AuxStreamChangeEvent.auxStreamSizeChangedEvent(aux), call: self.call!)
                    case .failure(_):
                        XCTAssertTrue(false)
                    }
                case .auxStreamSizeChangedEvent(let aux):
                    XCTAssertNotNil(aux)
                    XCTAssertEqual(aux.auxStreamSize.height, Int32(size.height))
                    XCTAssertEqual(aux.auxStreamSize.width, Int32(size.width))
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testopenForOneOnOneCall() {
        self.call = mockCall(isGroup: false)
        self.call?.multiStreamObserver = self.auxStreamObserver
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            let renderView = MediaRenderView()
            self.auxStreamObserver?.auxStreamAvailable = {
                XCTAssertTrue(false)
                return nil
            }
            self.auxStreamObserver?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamOpenedEvent(let view, let result):
                    XCTAssertEqual(view, renderView)
                    XCTAssertNotNil(result)
                    switch result {
                    case .success(_):
                        XCTAssertTrue(false)
                        break
                    case .failure(let error):
                        XCTAssertNotNil(error)
                        expect.fulfill()
                        break
                    }
                    break
                default:
                    break
                }
            }
            self.call?.openAuxStream(view: renderView)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamCountChangeByLocus() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                return nil
            }
            FakeWME.stubStreamsCountNotification(count: 3 + Call.activeSpeakerCount, call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamCountChangeByLocus2() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user2))
                return nil
            }
            
            self.auxStreamObserver?.onAuxStreamUnavailable = {
                expect.fulfill()
                return nil
            }
            
            FakeWME.stubStreamsCountNotification(count: 3 + Call.activeSpeakerCount, call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
    
    func testAuxStreamCountChangeByMedia() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            
            self.auxStreamObserver?.auxStreamAvailable = {
                expect.fulfill()
                FakeWME.stubStreamsCountNotification(count: 2 + Call.activeSpeakerCount, call: self.call!)
                return nil
            }
            
            self.auxStreamObserver?.onAuxStreamUnavailable = {
                expect.fulfill()
                return nil
            }
            
            FakeWME.stubStreamsCountNotification(count: 1 + Call.activeSpeakerCount, call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "openAuxStream time out")
            }
        }
    }
}
