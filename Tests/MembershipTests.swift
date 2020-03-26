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
import XCTest
@testable import WebexSDK

class MembershipTests: XCTestCase {
    
    private var fixture: WebexTestFixture! = WebexTestFixture.sharedInstance
    private let MembershipCountValid = 10
    private var memberships: MembershipClient!
    private var spaceId: String!
    private var other: TestUser!
    private var membership: Membership?
    
    private func validate(membership: Membership) {
        XCTAssertNotNil(membership.id)
        XCTAssertNotNil(membership.personId)
        XCTAssertNotNil(membership.personEmail)
        XCTAssertNotNil(membership.spaceId)
        XCTAssertNotNil(membership.isModerator)
        XCTAssertNotNil(membership.created)
    }
    
    override func setUp() {
        continueAfterFailure = false
        XCTAssertNotNil(fixture)
        if other == nil {
            other = fixture.createUser()
        }
        memberships = fixture.webex.memberships
        let space = fixture.createSpace(testCase: self, title: "test space")
        XCTAssertNotNil(space?.id)
        spaceId = space?.id
    }
    
    override func tearDown() {
        if let membership = membership, let membershipId = membership.id {
            if(!deleteMembership(membershipId: membershipId)) {
                XCTFail("Failed to delete membership")
            }
        }
        if let spaceId = spaceId {
            fixture.deleteSpace(testCase: self, spaceId: spaceId)
        }
        super.tearDown()
    }
    
    override static func tearDown() {
        Thread.sleep(forTimeInterval: Config.TestcaseInterval)
        super.tearDown()
    }
    
    func testCreateNonModeratorMembershipWithSpaceIdAndPersonId() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let membership = membership {
            XCTAssertEqual(membership.spaceId, spaceId)
            XCTAssertEqual(membership.personEmail, other.email)
            XCTAssertEqual(membership.personId, other.personId)
            XCTAssertEqual(membership.isModerator, false)
            validate(membership: membership)
        } else {
            XCTFail("Failed to create membership")
        }
    }
    
    func testCreateModeratorMembershipWithSpaceIdAndPersonId() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: true)
        if let membership = membership {
            XCTAssertEqual(membership.spaceId, spaceId)
            XCTAssertEqual(membership.personEmail, other.email)
            XCTAssertEqual(membership.isModerator, true)
            validate(membership: membership)
        } else {
            XCTFail("Failed to create membership")
        }
    }
    
    func testCreateNonModeratorMembershipWithSpaceIdAndPersonEmail() {
        membership = createMembership(spaceId: spaceId, personEmail: other.email, isModerator: false)
        if let membership = membership {
            XCTAssertEqual(membership.personId, other.personId)
            XCTAssertEqual(membership.spaceId, spaceId)
            XCTAssertEqual(membership.personEmail, other.email)
            XCTAssertEqual(membership.isModerator, false)
            validate(membership: membership)
        } else {
            XCTFail("Failed to create membership")
        }
    }
//    func testCreateMembershipWithInvalidSpaceIdButValidPersonId() {
//        membership = createMembership(spaceId: Config.InvalidId, personId: other.personId, isModerator: false)
//        XCTAssertNil(membership, "Unexpected successful request")
//    }

//    func testCreateMembershipWithValidSpaceIdButInvalidPersonId() {
//        membership = createMembership(spaceId: spaceId, personId: Config.InvalidId, isModerator: false)
//        XCTAssertNil(membership, "Unexpected successful request")
//    }

//    func testCreateMembershipWithInvalidSpaceIdAndInvalidPersonId() {
//        membership = createMembership(spaceId: Config.InvalidId, personId: Config.InvalidId, isModerator: false)
//        XCTAssertNil(membership, "Unexpected successful request")
//    }
    
//    func testCreateMembershipWithInvalidSpaceIdButValidEmail() {
//        membership = createMembership(spaceId: Config.InvalidId, personEmail: other.email, isModerator: false)
//        XCTAssertNil(membership, "Unexpected successful request")
//    }
    
//    func testCreateMembershipWithValidRoomIdButInvalidEmail() {
//        membership = createMembership(spaceId: spaceId, personEmail: Config.InvalidEmail, isModerator: false)
//        if membership == nil {
//            XCTAssertTrue(true)
//        } else {
//            XCTAssertNotNil(membership?.id, "Failed to creature membership")
//        }
//    }
    
    func testCreateModeratorMembershipWithSpaceIdAndPersonEmail() {
        membership = createMembership(spaceId: spaceId, personEmail: other.email, isModerator: true)
        if let membership = membership {
            XCTAssertEqual(membership.personId, other.personId)
            XCTAssertEqual(membership.spaceId, spaceId)
            XCTAssertEqual(membership.personEmail, other.email)
            XCTAssertEqual(membership.isModerator, true)
            validate(membership: membership)
        } else {
            XCTFail("Failed to create membership")
        }
    }
    
    func testListingMembershipWithNoFiltersFindsMembership() {
        if let list = listMemberships(max: nil) {
            XCTAssertGreaterThanOrEqual(list.count, 1)
            validate(membership: list[0])
        } else {
            XCTFail("No memberships returned")
        }
    }
    
    func testListingMembershipWithSpaceIdAndPersonIdFindsMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let list = listMemberships(spaceId: spaceId, personId: other.personId) {
            XCTAssertEqual(list.count, 1)
            let foundMembership = list[0]
            XCTAssertEqual(foundMembership.personId, other.personId)
            XCTAssertEqual(foundMembership.personEmail, other.email)
            XCTAssertEqual(foundMembership.spaceId, spaceId)
            XCTAssertEqual(foundMembership.isModerator, false)
            validate(membership: foundMembership)
        } else {
            XCTFail("No memberships returned")
        }
    }
    
    func testListingMembershipWithOnlySpaceIdFindsMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let list = listMemberships(spaceId: spaceId, max: nil) {
            var foundMembership: Membership? = nil
            for currentMembership in list {
                if currentMembership.personId == other.personId {
                    validate(membership: currentMembership)
                    foundMembership = currentMembership
                }
            }
            XCTAssertNotNil(foundMembership)
        } else {
            XCTFail("No memberships returned")
        }
    }
    
    func testListingMembershipWithOnlySpaceIdAndPersonEmailFindsMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let list = listMemberships(spaceId: spaceId, personEmail: other.email) {
            var foundMembership: Membership? = nil
            for currentMembership in list {
                if currentMembership.personId == other.personId {
                    validate(membership: currentMembership)
                    foundMembership = currentMembership
                }
            }
            XCTAssertNotNil(foundMembership)
        } else {
            XCTFail("No memberships returned")
        }
    }
    
    func testGettingMembershipReturnsMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let membershipId = membership?.id, let foundMembership = getMembership(membershipId: membershipId) {
            XCTAssertEqual(foundMembership.id, membership?.id)
        } else {
            XCTFail("Failed to get membership")
        }
    }
    
    func testGettingMembershipWithInvalidIdDoesNotReturnMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        let foundMembership = getMembership(membershipId: Config.InvalidId)
        XCTAssertNil(foundMembership)
    }
    
    func testUpdatingMembershipToAddModeratorReturnsMembershipWithModerator() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        if let membershipId = membership?.id, let updatedMembership = updateMembership(membershipId: membershipId, isModerator: true) {
            XCTAssertEqual(updatedMembership.id, membershipId)
            XCTAssertEqual(updatedMembership.isModerator, true)
        } else {
            XCTFail("Failed to update membership")
        }
    }
    
    func testDeletingMembershipRemovesMembershipAndItCanNoLongerBeRetrieved() {
        let membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        XCTAssertNotNil(membership?.id)
        let membershipId = (membership?.id)!
        XCTAssertTrue(deleteMembership(membershipId: membershipId))
        XCTAssertNil(getMembership(membershipId: membershipId))
    }
    
    func testDeletingMembershipWithBadIdFails() {
        XCTAssertFalse(deleteMembership(membershipId: Config.InvalidId))
    }
    
    func testUpdatingMembershipWithInvalidIdDoesNotReturnMembership() {
        membership = createMembership(spaceId: spaceId, personId: other.personId, isModerator: false)
        let updatedMembership = updateMembership(membershipId: Config.InvalidId, isModerator: true)
        XCTAssertNil(updatedMembership)
    }
    
    private func createMembership(spaceId: String, personEmail: EmailAddress, isModerator: Bool) -> Membership? {
        let request = { (completionHandler: @escaping (ServiceResponse<Membership>) -> Void) in
            self.memberships.create(spaceId: spaceId, personEmail: personEmail, isModerator: isModerator, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func createMembership(spaceId: String, personId: String, isModerator: Bool) -> Membership? {
        let request = { (completionHandler: @escaping (ServiceResponse<Membership>) -> Void) in
            self.memberships.create(spaceId: spaceId, personId: personId, isModerator: isModerator, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func deleteMembership(membershipId: String) -> Bool {
        let request = { (completionHandler: @escaping (ServiceResponse<Any>) -> Void) in
            self.memberships.delete(membershipId: membershipId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request) != nil
    }
    
    private func listMemberships(max: Int?) -> [Membership]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) in
            self.memberships.list(max: max, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func listMemberships(spaceId: String, max: Int?) -> [Membership]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) in
            self.memberships.list(spaceId: spaceId, max: max, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
        
    private func listMemberships(spaceId: String, personId: String) -> [Membership]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) in
            self.memberships.list(spaceId: spaceId, personId: personId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func listMemberships(spaceId: String, personEmail: EmailAddress) -> [Membership]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) in
            self.memberships.list(spaceId: spaceId, personEmail: personEmail, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func getMembership(membershipId: String) -> Membership? {
        let request = { (completionHandler: @escaping (ServiceResponse<Membership>) -> Void) in
            self.memberships.get(membershipId: membershipId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func updateMembership(membershipId: String, isModerator: Bool) -> Membership? {
        let request = { (completionHandler: @escaping (ServiceResponse<Membership>) -> Void) in
            self.memberships.update(membershipId: membershipId, isModerator: isModerator, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
}
