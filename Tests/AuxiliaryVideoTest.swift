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
        while AuxiliaryVideoTest.remoteUsers.count < MAX_AUX_STREAM_NUMBER+2 && tryCount < 30 {
            if let user = self.fixture.createUser() {
                AuxiliaryVideoTest.remoteUsers.append(user)
            }
            tryCount = tryCount + 1
        }
        
        if let callee = self.remoteUser, self.otherUsers?.count ?? 0 >= MAX_AUX_STREAM_NUMBER {
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
    func testSubscribeAuxStreamSuccess() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.multiStreamObserver = self.auxStreamObserver
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
            FakeWME.stubStreamsCountNotification(count:2, call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    /*
    func testSubscribeMaximumAuxStream() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = MAX_AUX_STREAM_NUMBER
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeAuxStream(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let auxStream):
                                XCTAssertNotNil(auxStream)
                            case .failure(_):
                                XCTAssertTrue(false)
                            }
                            expect.fulfill()
                        }
                    }
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(MAX_AUX_STREAM_NUMBER), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testExceededAuxStream() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = MAX_AUX_STREAM_NUMBER
            let expectFail = expectation(description: "subscribe AuxStream fail")
            expectFail.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeAuxStream(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let auxStream):
                                XCTAssertNotNil(auxStream)
                                expect.fulfill()
                            case .failure(let error):
                                XCTAssertNotNil(error)
                                expectFail.fulfill()
                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(MAX_AUX_STREAM_NUMBER + 1), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testSubscribeAuxStreamFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    for _ in 0..<count {
                        self.fakeWME?.stubSubscribeFailed = true
                        self.call?.subscribeAuxStream(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let auxStream):
                                XCTAssertNotNil(auxStream)
                            case .failure(let error):
                                XCTAssertNotNil(error)
                                expect.fulfill()
                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(1), call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testUnSubscribeAuxStreamSuccess() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeAuxStream(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let auxStream):
                                XCTAssertNotNil(auxStream)
                                self.call?.unsubscribeAuxStream(auxStream: auxStream) {
                                    error in
                                    XCTAssertNil(error)
                                    expect.fulfill()
                                }
                            case .failure(_):
                                XCTAssertTrue(false)
                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(2), call: self.call!)
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testUnSubscribeAuxStreamFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeAuxStream(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let auxStream):
                                XCTAssertNotNil(auxStream)
                                self.call?.unsubscribeAuxStream(auxStream: auxStream) {
                                    error in
                                    XCTAssertNil(error)
                                    self.call?.unsubscribeAuxStream(auxStream: auxStream) {
                                        error in
                                        XCTAssertNotNil(error)
                                        expect.fulfill()
                                    }
                                    expect.fulfill()
                                }
                            case .failure(_):
                                XCTAssertTrue(false)
                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(1), call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
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
                XCTAssertNil(error, "subscribeAuxStream time out")
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
                XCTAssertNil(error, "subscribeAuxStream time out")
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
                XCTAssertNil(error, "subscribeAuxStream time out")
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
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    
    func testAuxStreamPersonChangedEvent() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamPersonChangedEvent(let auxStream,let from,let to):
                    XCTAssertNil(from)
                    XCTAssertNotNil(to)
                    XCTAssertTrue(auxVideo?.person?.id == to?.id)
                    XCTAssertTrue(auxVideo?.person?.id == auxStream.person?.id)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamPersonChangedToNobody() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamPersonChangedEvent(let auxStream,let from,let to):
                    if auxStream.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == auxStream.person?.id)
                        FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: [])
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamPersonChangedToNobodyByLocus() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamPersonChangedEvent(let auxStream,let from,let to):
                    if auxStream.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == auxStream.person?.id)
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamPersonChangedToNobodyByLocusAndMedia() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamPersonChangedEvent(let auxStream,let from,let to):
                    if auxStream.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == auxStream.person?.id)
                        FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamPersonChangedEvent(auxStream,From: nil,To: nil), call: self.call!,csi: [])
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user))
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testRemoteAuxSendingVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    self.fakeWME?.stubRemoteAuxMuted = false
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(auxStream.isSendingVideo)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testRemoteMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    self.fakeWME?.stubRemoteAuxMuted = true
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(!auxStream.isSendingVideo)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    self.fakeWME?.stubLocalAuxMuted = true
                    auxStream.isReceivingVideo = false
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.receivingAuxVideoEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .receivingAuxVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(auxStream.isReceivingVideo == false)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testUnMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    self.fakeWME?.stubLocalAuxMuted = false
                    auxStream.isReceivingVideo = true
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.receivingAuxVideoEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .receivingAuxVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(auxStream.isReceivingVideo == true)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamSizeChanged() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            let size: CGSize = CGSize(width: 300, height: 200)
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    self.fakeWME?.stubAuxSize = size
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.auxStreamSizeChangedEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .auxStreamSizeChangedEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(Int(auxStream.auxStreamSize.width) == Int(size.width))
                    XCTAssertTrue(Int(auxStream.auxStreamSize.height) == Int(size.height))
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAddAuxStreamView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            let newRenderView: MediaRenderView = MediaRenderView()
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    auxStream.addRenderView(view: newRenderView)
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(auxStream.containRenderView(view: newRenderView))
                    XCTAssertTrue(auxStream.renderViews.count == 2)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testRemoveAuxStreamView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: AuxStream?
            let newRenderView: MediaRenderView = MediaRenderView()
            let newRenderView1: MediaRenderView = MediaRenderView()
            var readyToAdd: Bool = false
            self.call?.subscribeAuxStream(view: newRenderView) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    auxStream.removeRenderView(view: newRenderView)
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                    
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let auxStream):
                    if readyToAdd == false {
                        XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                        XCTAssertFalse(auxStream.containRenderView(view: newRenderView))
                        XCTAssertTrue(auxStream.renderViews.count == 0)
                        expect.fulfill()
                        readyToAdd = true
                        auxStream.addRenderView(view: newRenderView1)
                        FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                    } else {
                        XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                        XCTAssertTrue(auxStream.containRenderView(view: newRenderView1))
                        XCTAssertTrue(auxStream.renderViews.count == 1)
                        expect.fulfill()
                    }
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testUpdateAuxStreamView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: AuxStream?
            let newRenderView: MediaRenderView = MediaRenderView()
            let newRenderView1: MediaRenderView = MediaRenderView()
            self.call?.subscribeAuxStream(view: newRenderView) {
                result in
                switch result {
                case .success(let auxStream):
                    XCTAssertNotNil(auxStream)
                    auxVideo = auxStream
                    auxStream.updateRenderView(view: newRenderView)
                    auxStream.updateRenderView(view: newRenderView1)
                    auxStream.addRenderView(view: newRenderView1)
                    FakeWME.stubAuxStreamEvent(eventType: Call.AuxStreamChangeEvent.remoteAuxSendingVideoEvent(auxStream), call: self.call!)
                    
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onAuxStreamChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let auxStream):
                    XCTAssertTrue(auxVideo?.vid == auxStream.vid)
                    XCTAssertTrue(auxStream.containRenderView(view: newRenderView))
                    XCTAssertTrue(auxStream.containRenderView(view: newRenderView1))
                    XCTAssertTrue(auxStream.renderViews.count == 2)
                    auxStream.updateRenderView(view: newRenderView)
                    auxStream.updateRenderView(view: newRenderView1)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testSubscribeForOneOnOneCall() {
        self.call = mockCall(isGroup: false)
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on AuxStreamChangeEvent")
            expect.expectedFulfillmentCount = 1
            self.call?.subscribeAuxStream(view: MediaRenderView()) {
                result in
                switch result {
                case .success( _):
                    XCTAssertTrue(false)
                case .failure(let error):
                    XCTAssertNotNil(error)
                    expect.fulfill()
                }
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamCountChangeByLocus() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    XCTAssertTrue(count == 1)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(3), call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamCountChangeByLocus2() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            var isFirst = true
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    if isFirst {
                        isFirst = false
                        XCTAssertTrue(count == 1)
                        self.call?.update(model: FakeCallModelHelper.hangUpCallModel(callModel: self.call?.model ?? callmodel, hanupUser: user2))
                    } else {
                        XCTAssertTrue(count == 0)
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(3), call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
    
    func testAuxStreamCountChangeByMedia() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            var isFirst = true
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .auxStreamsCount(let count):
                    if isFirst {
                        isFirst = false
                        XCTAssertTrue(count == 1)
                        FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(2), call: self.call!)
                    } else {
                       XCTAssertTrue(count == 2)
                    }
                    
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.auxStreamsCount(1), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeAuxStream time out")
            }
        }
    }
 */
}
