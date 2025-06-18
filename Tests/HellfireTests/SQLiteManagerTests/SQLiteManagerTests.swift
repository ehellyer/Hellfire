import XCTest
@testable import Hellfire

final class SQLiteManagerTests: XCTestCase {

    var sqliteManager: SQLiteManager!

    override func setUpWithError() throws {
        sqliteManager = SQLiteManager()
    }

    override func tearDownWithError() throws {
        sqliteManager = nil
    }

    func testInsertAndFetchRequestItem() throws {
        let requestIdentifier = UUID()
        let taskIdentifier = 123
        let streamURL = URL(string: "https://example.com/stream")
        let requestItem = RequestItem(requestIdentifier: requestIdentifier, taskIdentifier: taskIdentifier, streamBodyURL: streamURL, requestDate: Date())

        try sqliteManager.insert(requestItem: requestItem)
        let fetchedItem = try sqliteManager.fetchRequestItem(byId: requestIdentifier)

        XCTAssertNotNil(fetchedItem)
        XCTAssertEqual(fetchedItem?.requestIdentifier, requestIdentifier)
        XCTAssertEqual(fetchedItem?.taskIdentifier, taskIdentifier)
        XCTAssertEqual(fetchedItem?.streamBodyURL, streamURL)
    }

    func testDeleteRequestItem() throws {
        let requestIdentifier = UUID()
        let requestItem = RequestItem(requestIdentifier: requestIdentifier, taskIdentifier: 456, streamBodyURL: nil, requestDate: Date())

        try sqliteManager.insert(requestItem: requestItem)
        var fetched = try sqliteManager.fetchRequestItem(byId: requestIdentifier)
        XCTAssertNotNil(fetched)

        try sqliteManager.deleteRequestItem(byId: requestIdentifier)
        fetched = try sqliteManager.fetchRequestItem(byId: requestIdentifier)
        XCTAssertNil(fetched)
    }

    func testFetchRequestItem_NotFound() throws {
        let requestIdentifier = UUID()
        let fetched = try sqliteManager.fetchRequestItem(byId: requestIdentifier)
        XCTAssertNil(fetched)
    }

    func testDeleteRequestItem_NotFound() throws {
        let requestIdentifier = UUID()
        XCTAssertNoThrow(try sqliteManager.deleteRequestItem(byId: requestIdentifier))
    }
}
