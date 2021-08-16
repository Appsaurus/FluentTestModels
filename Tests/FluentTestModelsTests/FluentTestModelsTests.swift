    import XCTest
    import XCTVapor
    import Fluent
    import FluentSQLiteDriver
    import FluentKit
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
            app.migrations.add([
                KitchenSink(),
                ParentModelMigration(),
                ChildModelMigration(),
                UserModelMigration(),
                FriendshipModelMigration()
            ])

        }

        func testKitchenSink() throws {
            let createUser = KitchenSink()
            try createUser.create(on: app.db).wait()
            let fetchedUser = try KitchenSink.query(on: app.db).first().wait()!
            XCTAssertNotNil(createUser.createdAt)
            XCTAssertNotNil(createUser.updatedAt)
            XCTAssertEqual(createUser.id, fetchedUser.id)
            XCTAssertEqual(createUser.stringField, fetchedUser.stringField)
            XCTAssertEqual(createUser.optionalStringField, fetchedUser.optionalStringField)
            XCTAssertEqual(createUser.intField, fetchedUser.intField)
            XCTAssertEqual(createUser.doubleField, fetchedUser.doubleField)
            XCTAssertEqual(createUser.booleanField, fetchedUser.booleanField)
            XCTAssertEqual(createUser.dateField.timeIntervalSince1970, fetchedUser.dateField.timeIntervalSince1970)
            XCTAssertEqual(createUser.stringArrayField, fetchedUser.stringArrayField)
            XCTAssertEqual(createUser.intArrayField, fetchedUser.intArrayField)
            XCTAssertEqual(createUser.doubleArrayField, fetchedUser.doubleArrayField)
            XCTAssertEqual(createUser.booleanArrayField, fetchedUser.booleanArrayField)
            XCTAssertEqual(createUser.dateArrayField, fetchedUser.dateArrayField)
            XCTAssertEqual(createUser.groupedFields.stringField, fetchedUser.groupedFields.stringField)
            XCTAssertEqual(createUser.groupedFields.optionalStringField, fetchedUser.groupedFields.optionalStringField)
            XCTAssertEqual(createUser.groupedFields.intField, fetchedUser.groupedFields.intField)
            XCTAssertEqual(createUser.stringEnum, fetchedUser.stringEnum)
            XCTAssertEqual(createUser.optionalStringEnum, fetchedUser.optionalStringEnum)
            XCTAssertEqual(createUser.rawStringEnum, fetchedUser.rawStringEnum)
            XCTAssertEqual(createUser.optionalRawStringEnum, fetchedUser.optionalRawStringEnum)
            XCTAssertEqual(createUser.rawIntEnum, fetchedUser.rawIntEnum)
            XCTAssertEqual(createUser.optionalRawIntEnum, fetchedUser.optionalRawIntEnum)
            XCTAssertEqual(createUser.stringEnumArray, fetchedUser.stringEnumArray)
            XCTAssertEqual(createUser.rawStringEnumArray, fetchedUser.rawStringEnumArray)
            XCTAssertEqual(createUser.rawIntEnumArray, fetchedUser.rawIntEnumArray)
        }

        func testParentChildRelationship() throws {
            let parent = ParentModel(name: "parent")
            try parent.create(on: app.db).wait()

            let son = try ChildModel(name: "son", parent: parent)
            let daughter = try ChildModel(name: "daughter", parent: parent)

            try son.create(on: app.db).wait()
            try daughter.create(on: app.db).wait()

//            let children = [son, daughter]
//            parent.$children.create([son, daughter], on: app.db)
            let fetchedChildren = try parent.$children.query(on: app.db).all().wait()
            let sonID = try son.requireID()
            let containsSon = fetchedChildren.contains(where: {$0.id == sonID && $0.name == son.name})
            let daughterID = try daughter.requireID()
            let containsDaughter = fetchedChildren.contains(where: {$0.id == daughterID && $0.name == daughter.name})

            XCTAssert(containsSon)
            XCTAssert(containsDaughter)

            XCTAssert(parent.$id.exists)
            XCTAssert(son.$id.exists)
            XCTAssert(daughter.$id.exists)


        }

        func testSelfSiblings() throws {
            let bill = UserModel(name: "Bill")
            try bill.create(on: app.db).wait()

            let ted = UserModel(name: "Ted")
            try ted.create(on: app.db).wait()

            let socrates = UserModel(name: "Socrates")
            try socrates.create(on: app.db).wait()
//            let socratesID = try socrates.requireID()

            try ted.$socialGraph.attach(bill, on: app.db).wait()
            try assert(bill, ted, areFriends: true)

            //Make sure we throw if we try to add an existing relationship in reverse
            XCTAssertThrowsError(try bill.$socialGraph.attach(ted, on: app.db).wait())

            //Detach friendship
            try bill.$socialGraph.detach(ted, on: app.db).wait()

            try assert(bill, ted, areFriends: false)



        }

        func assert(_ leftUser: UserModel, _ rightUser: UserModel, areFriends: Bool) throws {
            let leftUserID = try leftUser.requireID()
            let rightUserID = try rightUser.requireID()

            func assertion(_ expression: Bool) -> () {
                if areFriends {
                    XCTAssert(expression)
                }
                else {
                    XCTAssertFalse(expression)
                }
            }
            //Check these methods in both directions

            //Through isAttached(to:on:) method of socialGraph property.
            assertion(try leftUser.$socialGraph.isAttached(to: rightUser, on: app.db).wait())
            assertion(try rightUser.$socialGraph.isAttached(to: leftUser, on: app.db).wait())

            //Check queries to make sure they return friends.

            //Through sqlQuery(on:) method of socialGraph property.
            let rightUserFriends = try rightUser.$socialGraph
                .sqlQuery(on: app.db)
                .all(decoding: UserModel.self).wait()
            let rightUserIsFriendsWithBill = rightUserFriends.contains(where: {$0.id == leftUserID})

            assertion(rightUserIsFriendsWithBill)


            //Fetch all friends through Fluent QueryBuilder
            let leftUserFriends = try leftUser.$socialGraph.get(reload: true, on: app.db).wait()
            let leftUserIsFriendsWithTed = leftUserFriends.contains(where: {$0.id == rightUserID})

            assertion(leftUserIsFriendsWithTed)

            //Through query(on:) method of socialGraph property.
            let leftUserFriendQueryBuilder = try leftUser.$socialGraph.query(on: app.db).wait()
            let leftUserFilteredFriends = try leftUserFriendQueryBuilder.filter(\.$name == rightUser.name).all().wait()
            assertion(leftUserFilteredFriends.contains(where: {$0.id == rightUserID}))
        }
    }
