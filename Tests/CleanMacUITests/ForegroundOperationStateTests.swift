import XCTest
@testable import CleanMac

final class ForegroundOperationStateTests: XCTestCase {
    func testOnlyOneForegroundOperationCanRunAtATime() {
        var state = ForegroundOperationState()

        let scanToken = state.begin(.scanningFiles)

        XCTAssertNotNil(scanToken)
        XCTAssertNil(state.begin(.cleaning))
        XCTAssertNil(state.begin(.reviewingWithAI))
        XCTAssertEqual(state.operation, .scanningFiles)
    }

    func testStaleCompletionCannotClearANewerOperation() throws {
        var state = ForegroundOperationState()
        let scanToken = try XCTUnwrap(state.begin(.scanningFiles))
        XCTAssertTrue(state.finish(scanToken))

        let cleaningToken = try XCTUnwrap(state.begin(.cleaning))
        XCTAssertFalse(state.finish(scanToken))
        XCTAssertEqual(state.operation, .cleaning)
        XCTAssertTrue(state.finish(cleaningToken))
        XCTAssertNil(state.operation)
    }
}
