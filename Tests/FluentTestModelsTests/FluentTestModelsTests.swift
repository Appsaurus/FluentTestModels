    import XCTest
    import XCTVapor
    import Fluent
    import FluentSQLiteDriver
    
    @testable import FluentTestModels

    final class FluentTestModelsTests: XCTestCase {

        private var app: Application!

        override func setUp() {
            super.setUp()

            app = Application(.testing)
            app.logger.logLevel = .debug

            app.databases.use(.sqlite(.memory), as: .sqlite)

            try! migrations(app)
            try! app.autoRevert().wait()
            try! app.autoMigrate().wait()

        }

        private func migrations(_ app: Application) throws {
            app.migrations.add(TestModel())
        }

        func testExample() throws {
            let createUser = TestModel()
            try createUser.create(on: app.db).wait()
            let fetchedUser = try TestModel.query(on: app.db).first().wait()!
            XCTAssertEqual(createUser.id, fetchedUser.id)
            XCTAssertNotNil(createUser.createdAt)
            XCTAssertNotNil(createUser.updatedAt)
            XCTAssertEqual(createUser.createdAt?.description, fetchedUser.createdAt?.description)
        }
    }
