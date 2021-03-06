//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus


class FakeVerificationHandler: VerificationHandler {

    var lastCallIdentifier: String?
    var lastMatchCount: Int?
    var lastDifferentArgumentsCount: Int?
    var lastMode: VerificationMode?
    var lastTestLocation: TestLocation?

    override func verifyCall(callIdentifier: String, matchCount: Int, differentArgumentsMatchCount: Int, mode: VerificationMode, testLocation: TestLocation) {
        lastCallIdentifier = callIdentifier
        lastMatchCount = matchCount
        lastDifferentArgumentsCount = differentArgumentsMatchCount
        lastTestLocation = testLocation
        lastMode = mode
    }
}

class MockTests: XCTestCase {

    class MockRecorder: Mock {
        var storage = [RecordedCall]()
    }

    var mockRecorder: MockRecorder!
    var fakeVerificationHandler: FakeVerificationHandler!

    override func setUp() {
        super.setUp()

        mockRecorder = MockRecorder()
        fakeVerificationHandler = FakeVerificationHandler()

        VerificationHandler.shared = fakeVerificationHandler
    }

    override func tearDown() {
        mockRecorder = nil
        fakeVerificationHandler = nil

        VerificationHandler.shared = VerificationHandler()
    }

    // MARK: Test No Recorder Invocations

    func testNoRecorderInvocations() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastCallIdentifier, "Fixture Identifier", "Expected verification handler to receive correct call identifier")
    }

    func testBaseVerificationMode() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastMode, VerificationMode.times(1), "Expected verification handler to receive default verification mode")
    }

    func testCustomVerificationMode() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", mode: .never)

        XCTAssertEqual(fakeVerificationHandler.lastMode, VerificationMode.never, "Expected verification handler to receive correct custom verification mode")
    }

    func testCorrectFileLocation() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", file: "Fixture File", line: 42)

        let expectedFileName: StaticString = "Fixture File"
        // Not too beautiful - we're using our matchers as XCTest cannot verify StaticStrings
        let namesMatched = expectedFileName.equalTo(other: fakeVerificationHandler.lastTestLocation?.file)

        XCTAssertTrue(namesMatched, "Expected verification handler to receive correct file")
        XCTAssertEqual(fakeVerificationHandler.lastTestLocation?.line, 42, "Expected verification handler to receive correct line")
    }

    func testCorrectNumberOfMatches() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 2")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 3")

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastMatchCount, 2, "Expected verification handler to receive correct number of matches")
    }

    func testCorrectNumberOfMatchesWithArguments() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 2")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 3")

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])

        XCTAssertEqual(fakeVerificationHandler.lastMatchCount, 2, "Expected verification handler to receive correct number of matches")
    }

    func testCorrectNumberOfMismatchedArguments() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [43])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [42])

        XCTAssertEqual(fakeVerificationHandler.lastMatchCount, 1, "Expected verification handler to receive correct number of matches")
        XCTAssertEqual(fakeVerificationHandler.lastDifferentArgumentsCount, 2, "Expected verification handler to receive correct number of unmatched arguments")
    }

    func testCaptureArgument() {
        let argumentCaptor = CaptureArgumentMatcher()

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [argumentCaptor])

        let lastValue = argumentCaptor.capturedValues.last as? Int

        XCTAssertEqual(lastValue, 42, "Expected to receive captured value")
    }
}
