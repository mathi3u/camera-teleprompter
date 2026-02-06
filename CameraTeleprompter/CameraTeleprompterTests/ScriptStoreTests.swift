import XCTest
@testable import CameraTeleprompter

final class ScriptStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ScriptStore.clear()
    }

    override func tearDown() {
        ScriptStore.clear()
        super.tearDown()
    }

    func testSaveAndLoadRoundTrip() {
        let script = Script(title: "Test Script", body: "Hello world")
        ScriptStore.save([script])

        let loaded = ScriptStore.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Test Script")
        XCTAssertEqual(loaded[0].body, "Hello world")
        XCTAssertEqual(loaded[0].id, script.id)
    }

    func testLoadEmptyReturnsEmptyArray() {
        let loaded = ScriptStore.load()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testSaveMultipleScripts() {
        let script1 = Script(title: "Script 1", body: "Body 1")
        let script2 = Script(title: "Script 2", body: "Body 2")
        ScriptStore.save([script1, script2])

        let loaded = ScriptStore.load()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].title, "Script 1")
        XCTAssertEqual(loaded[1].title, "Script 2")
    }

    func testOverwriteExistingScripts() {
        let script1 = Script(title: "Original", body: "First")
        ScriptStore.save([script1])

        let script2 = Script(title: "Replacement", body: "Second")
        ScriptStore.save([script2])

        let loaded = ScriptStore.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Replacement")
    }

    func testClearRemovesAll() {
        let script = Script(title: "Test", body: "Data")
        ScriptStore.save([script])
        ScriptStore.clear()

        let loaded = ScriptStore.load()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testScriptEquality() {
        let id = UUID()
        let date = Date()
        let script1 = Script(id: id, title: "Same", body: "Body", createdAt: date, updatedAt: date)
        let script2 = Script(id: id, title: "Same", body: "Body", createdAt: date, updatedAt: date)
        XCTAssertEqual(script1, script2)
    }
}
