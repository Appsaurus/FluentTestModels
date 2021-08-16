//
//  FluentTestCase.swift
//  
//
//  Created by Brian Strobach on 8/16/21.
//

import XCTest
import XCTVapor
import FluentSQLiteDriver
import FluentKit


open class FluentTestCase: VaporTestCase {

    override open func setUp() {
        super.setUp()
        try! app.autoRevert().wait()
        try! app.autoMigrate().wait()

    }



    open override func configure(_ app: Application) throws {
        try super.configure(app)
        try configure(app.databases)
        try configure(app.databases.middleware)
        try migrate(app.migrations)
    }

    open func configure(_ databases: Databases) throws{}

    open func configure(_ middleware: Databases.Middleware) throws {}

    open func migrate(_ migrations: Migrations) throws {}

}

public struct FluentTestModels {

    open class TestCase: FluentTestCase {

        override open func configure(_ databases: Databases) throws {
            try super.configure(databases)
            databases.use(.sqlite(.memory), as: .sqlite)
        }
        override open func configure(_ middleware: Databases.Middleware) throws {
            try super.configure(middleware)
            let siblingsMiddleware = FriendshipModel.selfSiblingMiddleware(from: \.$fromUser, to: \.$toUser)
            middleware.use(siblingsMiddleware)
        }
        override open func migrate(_ migrations: Migrations) throws {
            try super.migrate(migrations)
            migrations.add([
                KitchenSink(),
                ParentModelMigration(),
                ChildModelMigration(),
                StudentModel(),
                ClassModel(),
                EnrollmentModel(),
                UserModelMigration(),
                FriendshipModelMigration()
            ])
        }
    }
}

