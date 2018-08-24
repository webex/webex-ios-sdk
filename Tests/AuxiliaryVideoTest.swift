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
        while AuxiliaryVideoTest.remoteUsers.count < MAX_REMOTE_AUX_VIDEO_NUMBER+2 && tryCount < 30 {
            if let user = self.fixture.createUser() {
                AuxiliaryVideoTest.remoteUsers.append(user)
            }
            tryCount = tryCount + 1
        }
        
        if let callee = self.remoteUser, self.otherUsers?.count ?? 0 >= MAX_REMOTE_AUX_VIDEO_NUMBER {
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
    
    // MARK: - Test cases
    func testSubscribeRemoteAuxVideoSuccess() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
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
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(1), call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testSubscribeMaximumRemoteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = MAX_REMOTE_AUX_VIDEO_NUMBER
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
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
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(MAX_REMOTE_AUX_VIDEO_NUMBER), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testExceededRemoteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = MAX_REMOTE_AUX_VIDEO_NUMBER
            let expectFail = expectation(description: "subscribe RemoteAuxVideo fail")
            expectFail.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
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
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(MAX_REMOTE_AUX_VIDEO_NUMBER + 1), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testSubscribeRemoteAuxVideoFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.fakeWME?.stubSubscribeFailed = true
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
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
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(1), call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testUnSubscribeRemoteAuxVideoSuccess() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
                                self.call?.unsubscribeRemoteAuxVideo(remoteAuxVideo: remoteAuxVideo) {
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
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(2), call: self.call!)
            
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testUnSubscribeRemoteAuxVideoFailed() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    for _ in 0..<count {
                        self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                            result in
                            switch result {
                            case .success(let remoteAuxVideo):
                                XCTAssertNotNil(remoteAuxVideo)
                                self.call?.unsubscribeRemoteAuxVideo(remoteAuxVideo: remoteAuxVideo) {
                                    error in
                                    XCTAssertNil(error)
                                    self.call?.unsubscribeRemoteAuxVideo(remoteAuxVideo: remoteAuxVideo) {
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
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(1), call: self.call!)
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    
    func testRemoteAuxVideoPersonChangedEvent() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxVideoPersonChangedEvent(let remoteAuxVideo,let from,let to):
                    XCTAssertNil(from)
                    XCTAssertNotNil(to)
                    XCTAssertTrue(auxVideo?.person?.id == to?.id)
                    XCTAssertTrue(auxVideo?.person?.id == remoteAuxVideo.person?.id)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoPersonChangedToNobody() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxVideoPersonChangedEvent(let remoteAuxVideo,let from,let to):
                    if remoteAuxVideo.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == remoteAuxVideo.person?.id)
                        FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: [])
                    }
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoPersonChangedToNobodyByLocus() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxVideoPersonChangedEvent(let remoteAuxVideo,let from,let to):
                    if remoteAuxVideo.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == remoteAuxVideo.person?.id)
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoPersonChangedToNobodyByLocusAndMedia() {
        if let callmodel = self.call?.model,let user = self.remoteUser ,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: user.csi)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxVideoPersonChangedEvent(let remoteAuxVideo,let from,let to):
                    if remoteAuxVideo.person == nil {
                        XCTAssertNil(to)
                        XCTAssertNotNil(from)
                    } else {
                        XCTAssertNil(from)
                        XCTAssertNotNil(to)
                        XCTAssertTrue(auxVideo?.person?.id == to?.id)
                        XCTAssertTrue(auxVideo?.person?.id == remoteAuxVideo.person?.id)
                        FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoPersonChangedEvent(remoteAuxVideo,From: nil,To: nil), call: self.call!,csi: [])
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxSendingVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    self.fakeWME?.stubRemoteAuxMuted = false
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(remoteAuxVideo.isSendingVideo)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    self.fakeWME?.stubRemoteAuxMuted = true
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(!remoteAuxVideo.isSendingVideo)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    self.fakeWME?.stubLocalAuxMuted = true
                    remoteAuxVideo.isReceivingVideo = false
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.receivingAuxVideoEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .receivingAuxVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(remoteAuxVideo.isReceivingVideo == false)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testUnMuteAuxVideo() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    self.fakeWME?.stubLocalAuxMuted = false
                    remoteAuxVideo.isReceivingVideo = true
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.receivingAuxVideoEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .receivingAuxVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(remoteAuxVideo.isReceivingVideo == true)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoSizeChanged() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            let size: CGSize = CGSize(width: 300, height: 200)
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    self.fakeWME?.stubAuxSize = size
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxVideoSizeChangedEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxVideoSizeChangedEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(Int(remoteAuxVideo.remoteAuxVideoSize.width) == Int(size.width))
                    XCTAssertTrue(Int(remoteAuxVideo.remoteAuxVideoSize.height) == Int(size.height))
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testAddRemoteAuxVideoView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            let newRenderView: MediaRenderView = MediaRenderView()
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    remoteAuxVideo.addRenderView(view: newRenderView)
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(remoteAuxVideo.containRenderView(view: newRenderView))
                    XCTAssertTrue(remoteAuxVideo.renderViews.count == 2)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoveRemoteAuxVideoView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 2
            var auxVideo: RemoteAuxVideo?
            let newRenderView: MediaRenderView = MediaRenderView()
            let newRenderView1: MediaRenderView = MediaRenderView()
            var readyToAdd: Bool = false
            self.call?.subscribeRemoteAuxVideo(view: newRenderView) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    remoteAuxVideo.removeRenderView(view: newRenderView)
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                    
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                    if readyToAdd == false {
                        XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                        XCTAssertFalse(remoteAuxVideo.containRenderView(view: newRenderView))
                        XCTAssertTrue(remoteAuxVideo.renderViews.count == 0)
                        expect.fulfill()
                        readyToAdd = true
                        remoteAuxVideo.addRenderView(view: newRenderView1)
                        FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                    } else {
                        XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                        XCTAssertTrue(remoteAuxVideo.containRenderView(view: newRenderView1))
                        XCTAssertTrue(remoteAuxVideo.renderViews.count == 1)
                        expect.fulfill()
                    }
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testUpdateRemoteAuxVideoView() {
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            var auxVideo: RemoteAuxVideo?
            let newRenderView: MediaRenderView = MediaRenderView()
            let newRenderView1: MediaRenderView = MediaRenderView()
            self.call?.subscribeRemoteAuxVideo(view: newRenderView) {
                result in
                switch result {
                case .success(let remoteAuxVideo):
                    XCTAssertNotNil(remoteAuxVideo)
                    auxVideo = remoteAuxVideo
                    remoteAuxVideo.updateRenderView(view: newRenderView)
                    remoteAuxVideo.updateRenderView(view: newRenderView1)
                    remoteAuxVideo.addRenderView(view: newRenderView1)
                    FakeWME.stubRemoteAuxVideoEvent(eventType: Call.RemoteAuxVideoChangeEvent.remoteAuxSendingVideoEvent(remoteAuxVideo), call: self.call!)
                    
                case .failure(_):
                    XCTAssertTrue(false)
                }
            }
            
            self.call?.onRemoteAuxVideoChanged = {
                event in
                switch event {
                case .remoteAuxSendingVideoEvent(let remoteAuxVideo):
                    XCTAssertTrue(auxVideo?.vid == remoteAuxVideo.vid)
                    XCTAssertTrue(remoteAuxVideo.containRenderView(view: newRenderView))
                    XCTAssertTrue(remoteAuxVideo.containRenderView(view: newRenderView1))
                    XCTAssertTrue(remoteAuxVideo.renderViews.count == 2)
                    remoteAuxVideo.updateRenderView(view: newRenderView)
                    remoteAuxVideo.updateRenderView(view: newRenderView1)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testSubscribeForOneOnOneCall() {
        self.call = mockCall(isGroup: false)
        if let callmodel = self.call?.model,let user = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: user))
            let expect = expectation(description: "on RemoteAuxVideoChangeEvent")
            expect.expectedFulfillmentCount = 1
            self.call?.subscribeRemoteAuxVideo(view: MediaRenderView()) {
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
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoCountChangeByLocus() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 1
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    XCTAssertTrue(count == 1)
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(3), call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoCountChangeByLocus2() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser,let user2 = self.otherUsers?.first {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            var isFirst = true
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
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
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(3), call: self.call!)
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user2))
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
    
    func testRemoteAuxVideoCountChangeByMedia() {
        if let callmodel = self.call?.model,let answerUser = self.remoteUser {
            self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: callmodel, answerUser: answerUser))
            let expect = expectation(description: "on onMediaChanged")
            expect.expectedFulfillmentCount = 2
            var isFirst = true
            self.call?.onMediaChanged = {
                event in
                switch event {
                case .remoteAuxVideosCount(let count):
                    if isFirst {
                        isFirst = false
                        XCTAssertTrue(count == 1)
                        FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(2), call: self.call!)
                    } else {
                       XCTAssertTrue(count == 2)
                    }
                    
                    expect.fulfill()
                    break
                default:
                    break
                }
            }
            
            FakeWME.stubMediaChangeNotification(eventType: Call.MediaChangedEvent.remoteAuxVideosCount(1), call: self.call!)
            for user in self.otherUsers ?? [] {
                self.call?.update(model: FakeCallModelHelper.answerCallModel(callModel: self.call?.model ?? callmodel, answerUser: user))
            }
            
            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error, "subscribeRemoteAuxVideo time out")
            }
        }
    }
}
