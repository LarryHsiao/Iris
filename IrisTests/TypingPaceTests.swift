import XCTest
@testable import Iris

final class TypingPaceTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func at(_ seconds: TimeInterval) -> Date {
        start.addingTimeInterval(seconds)
    }

    /// Records one keystroke every 0.2 s (five a second, 60 WPM) from `from` to `to`.
    private func typeSteadily(_ pace: inout TypingPace, from: TimeInterval, to: TimeInterval) {
        var t = from
        while t <= to + 0.001 {
            pace.record(keystrokes: 1, at: at(t))
            t += 0.2
        }
    }

    func testNoKeystrokesReadsAsIdle() {
        let expected: Double? = nil
        let pace = TypingPace()
        XCTAssertEqual(pace.wordsPerMinute(at: start), expected)
    }

    func testSteadyTypingFillsTheWindow() throws {
        let expected = 60.0
        var pace = TypingPace()
        typeSteadily(&pace, from: 0, to: 4.8)
        let actual = try XCTUnwrap(pace.wordsPerMinute(at: at(4.8)))
        XCTAssertEqual(actual, expected, accuracy: 0.001)
    }

    func testKeystrokesOlderThanTheWindowAreDropped() throws {
        let expected = 12.0
        var pace = TypingPace()
        pace.record(keystrokes: 10, at: at(0))
        pace.record(keystrokes: 5, at: at(6))
        let actual = try XCTUnwrap(pace.wordsPerMinute(at: at(6)))
        XCTAssertEqual(actual, expected, accuracy: 0.001)
    }

    func testStillTypingJustBeforeTheIdleCutoff() throws {
        let expected = 2.4
        var pace = TypingPace()
        pace.record(keystrokes: 1, at: at(0))
        let actual = try XCTUnwrap(pace.wordsPerMinute(at: at(1.9)))
        XCTAssertEqual(actual, expected, accuracy: 0.001)
    }

    func testIdleAtTheCutoff() {
        let expected: Double? = nil
        var pace = TypingPace()
        pace.record(keystrokes: 1, at: at(0))
        XCTAssertEqual(pace.wordsPerMinute(at: at(2)), expected)
    }

    func testZeroCountIsIgnored() {
        let expected: Double? = nil
        var pace = TypingPace()
        pace.record(keystrokes: 0, at: at(0))
        XCTAssertEqual(pace.wordsPerMinute(at: at(0)), expected)
    }

    func testNegativeCountIsIgnored() {
        let expected: Double? = nil
        var pace = TypingPace()
        pace.record(keystrokes: -3, at: at(0))
        XCTAssertEqual(pace.wordsPerMinute(at: at(0)), expected)
    }

    func testRunJustShortOfTheWindowDoesNotSetTheBest() {
        let expected = 0.0
        var pace = TypingPace()
        for t in [0, 1.5, 3, 4.5, 4.9] { pace.record(keystrokes: 5, at: at(t)) }
        XCTAssertEqual(pace.best, expected)
    }

    func testRunOfExactlyTheWindowSetsTheBest() {
        let expected = 48.0
        var pace = TypingPace()
        for t in [0, 1.5, 3, 4.5, 5] { pace.record(keystrokes: 5, at: at(t)) }
        XCTAssertEqual(pace.best, expected, accuracy: 0.001)
    }

    func testShortBurstDoesNotSetTheBest() {
        let expected = 0.0
        var pace = TypingPace()
        pace.record(keystrokes: 30, at: at(0))
        pace.record(keystrokes: 30, at: at(1))
        XCTAssertEqual(pace.best, expected)
    }

    func testSustainedTypingSetsTheBest() {
        let expected = 60.0
        var pace = TypingPace()
        typeSteadily(&pace, from: 0, to: 6)
        XCTAssertEqual(pace.best, expected, accuracy: 0.001)
    }

    func testSlowerTypingKeepsTheStoredBest() {
        let expected = 128.0
        var pace = TypingPace(best: expected)
        typeSteadily(&pace, from: 0, to: 6)
        XCTAssertEqual(pace.best, expected)
    }

    func testPauseRestartsTheSustainedRun() {
        let expected = 60.0
        var pace = TypingPace()
        typeSteadily(&pace, from: 0, to: 6)
        pace.record(keystrokes: 100, at: at(9))
        XCTAssertEqual(pace.best, expected, accuracy: 0.001)
    }
}
