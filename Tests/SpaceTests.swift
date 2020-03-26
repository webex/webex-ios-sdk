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

import XCTest
@testable import WebexSDK

class SpaceTests: XCTestCase {
    
    private let fixture: WebexTestFixture! = WebexTestFixture.sharedInstance
    private let spaceTitle  = "space_for_testing"
    private let specialTitle = "@@@ &&&_%%%"
    private let updatedSpaceTitle  = "space_for_testing_updated"
    private var me: TestUser!
    private var spaces: SpaceClient!
    private var space: Space?

    private func validate(space: Space?) {
        XCTAssertNotNil(space)
        XCTAssertNotNil(space?.id)
        XCTAssertNotNil(space?.title)
        XCTAssertNotNil(space?.type)
        XCTAssertNotNil(space?.isLocked)
        XCTAssertNotNil(space?.lastActivityTimestamp)
        XCTAssertNotNil(space?.created)
    }
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCTAssertNotNil(fixture)
        me = fixture.selfUser
        spaces = fixture.webex.spaces
    }
    
    override func tearDown() {
        if let space = space, let spaceId = space.id {
            if(!deleteSpace(spaceId: spaceId)) {
                XCTFail("Failed to delete space")
            }
        }
        Thread.sleep(forTimeInterval: Config.TestcaseInterval)
        super.tearDown()
    }
    
    func testCreatingSpaceWithTitleReturnsSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        validate(space: space)
        XCTAssertEqual(space?.title, spaceTitle)
    }
    
    func testCreatingSpaceWithEmptyTitleReturnsSpace() {
        space = createSpace(title: "", teamId: nil)
        XCTAssertNotNil(space?.id)
        XCTAssertNil(space?.title)
    }
    
    func testCreatingSpaceWithSpecialTitleReturnsSpace() {
        space = createSpace(title: specialTitle, teamId: nil)
        validate(space: space)
        XCTAssertEqual(space?.title, specialTitle)
    }
    
    func testCreatingSpaceWithTeamIdReturnsSpace() {
        let team = TestTeam(testCase: self)
        XCTAssertNotNil(team?.id)
        space = createSpace(title: spaceTitle, teamId: team?.id)
        validate(space: space)
        XCTAssertEqual(space?.title, spaceTitle)
        XCTAssertEqual(space?.teamId, team?.id)
        if(!deleteSpace(spaceId: space!.id!)) {
            XCTFail("Failed to delete space")
        }
        space = nil
    }
    
    func testUpdatingSpaceWithSpaceIdAndTitleReturnsUpdatedSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        validate(space: space)
        let spaceId = (space?.id)!
        let updatedSpace = updateSpace(spaceId: spaceId, title: updatedSpaceTitle)
        validate(space: updatedSpace)
        XCTAssertEqual(updatedSpace?.title, updatedSpaceTitle)
    }
    
    func testUpdatingSpaceWithInvalidSpaceIdFails() {
        space = createSpace(title: spaceTitle, teamId: nil)
        let updatedSpace = updateSpace(spaceId: Config.InvalidId, title: updatedSpaceTitle)
        XCTAssertNil(updatedSpace)
    }
    
    func testUpdatingSpaceWithSpaceIdAndSpecialTitleReturnsUpdatedSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        validate(space: space)
        let spaceId = (space?.id)!
        let updatedSpace = updateSpace(spaceId: spaceId, title: specialTitle)
        validate(space: updatedSpace)
        XCTAssertEqual(updatedSpace?.title, specialTitle)
    }
    
    func testDeletingSpaceWithSpaceIdRemovesSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        validate(space: space)
        let spaceId = (space?.id)!
        XCTAssertTrue(deleteSpace(spaceId: spaceId))
        XCTAssertNil(getSpace(spaceId: spaceId))
        space = nil
    }
    
    func testDeletingSpaceWithBadIdFails() {
        XCTAssertFalse(deleteSpace(spaceId: Config.InvalidId))
    }
    
    func testGettingSpaceWithSpaceIdReturnsSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        validate(space: space)
        let spaceId = (space?.id)!
        let spaceDetails = getSpace(spaceId: spaceId)
        validate(space: spaceDetails)
        XCTAssertEqual(spaceDetails?.id, space?.id)
        XCTAssertEqual(spaceDetails?.title, space?.title)
    }
    
    func testGettingSpaceWithInvalidSpaceIdFails() {
        XCTAssertNil(getSpace(spaceId: Config.InvalidId))
    }
    
    func testGettingSpaceWithEmptySpaceIdReturnsSpace() {
        // XXX: There may be a reason for why we want this behavior, but if so it is not known
        space = createSpace(title: spaceTitle, teamId: nil)
        let spaceDetails = getSpace(spaceId: "")
        XCTAssertNotNil(spaceDetails)
        XCTAssertNil(spaceDetails?.id)
        XCTAssertNil(spaceDetails?.title)
    }
    
    func testListingSpaceWithNoDetailsReturnsSpace() {
        space = createSpace(title: spaceTitle, teamId: nil)
        let spaceArray = listSpaces(teamId: nil, max: nil, type: nil)
        if let spaceArray = spaceArray {
            XCTAssertGreaterThanOrEqual(spaceArray.count, 1)
            validate(space: spaceArray.first)
        } else {
            XCTFail("Could not retrieve spaces")
        }
    }
    
    func testListingSpacesWithValidMaxReturnsSpaces() {
        space = createSpace(title: spaceTitle, teamId: nil)
        let spaceArray = listSpaces(teamId: nil, max: 10, type: nil)
        if let spaceArray = spaceArray {
            XCTAssertLessThanOrEqual(spaceArray.count, 10)
            XCTAssertGreaterThanOrEqual(spaceArray.count, 1)
            validate(space: spaceArray.first)
        } else {
            XCTFail("Could not retrieve spaces")
        }
    }
    
    func testListingSpacesWithValidMaxAndDirectTypeDoesNotFail() {
        // We do not have a way that we're currently creating "direct" 1-to-1 spaces in this test
        let spaceArray = listSpaces(teamId: nil, max: 10, type: .direct)
        XCTAssertNotNil(spaceArray)
    }
    
    func testListingSpacesWithMaxOf1ReturnsOnly1Space() {
        space = createSpace(title: spaceTitle, teamId: nil)
        let otherSpace = createSpace(title: spaceTitle, teamId: nil)
        let spaceArray = listSpaces(teamId: nil, max: 1, type: nil)
        if let spaceArray = spaceArray {
            XCTAssertEqual(spaceArray.count, 1)
            validate(space: spaceArray.first)
        } else {
            XCTFail("Could not retrieve spaces")
        }
        _ = deleteSpace(spaceId: (otherSpace?.id)!)
    }
    
    func testListingSpacesWithInvalidMaxFails() {
        XCTAssertNil(listSpaces(teamId: nil, max: -1, type: nil))
    }
    
    func testListingSpaceWithTeamIdReturnsSpace() {
        let team = TestTeam(testCase: self)
        XCTAssertNotNil(team?.id)
        space = createSpace(title: spaceTitle, teamId: team?.id)
        validate(space: space)
        XCTAssertNotNil(space?.teamId)
        if let spaceArray = listSpaces(teamId: team?.id, max: nil, type: nil) {
            XCTAssertEqual(spaceArray.first?.id, space?.id)
            XCTAssertEqual(spaceArray.first?.teamId, space?.teamId)
            if(!deleteSpace(spaceId: space!.id!)) {
                XCTFail("Failed to delete space")
            }
            space = nil
        } else {
            XCTFail("Could not retrieve spaces")
        }
    }
    
    private func createSpace(title: String, teamId: String?) -> Space? {
        let request = { (completionHandler: @escaping (ServiceResponse<Space>) -> Void) in
            self.spaces.create(title: title, teamId: teamId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func updateSpace(spaceId: String, title: String) -> Space? {
        let request = { (completionHandler: @escaping (ServiceResponse<Space>) -> Void) in
            self.spaces.update(spaceId: spaceId, title: title, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func getSpace(spaceId: String) -> Space? {
        let request = { (completionHandler: @escaping (ServiceResponse<Space>) -> Void) in
            self.spaces.get(spaceId: spaceId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func listSpaces(teamId: String?, max: Int?, type: SpaceType?) -> [Space]? {
        let request = { (completionHandler: @escaping (ServiceResponse<[Space]>) -> Void) in
            self.spaces.list(teamId: teamId, max: max, type: type, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request)
    }
    
    private func deleteSpace(spaceId: String) -> Bool {
        let request = { (completionHandler: @escaping (ServiceResponse<Any>) -> Void) in
            self.spaces.delete(spaceId: spaceId, completionHandler: completionHandler)
        }
        return fixture.getResponse(testCase: self, request: request) != nil
    }
}
