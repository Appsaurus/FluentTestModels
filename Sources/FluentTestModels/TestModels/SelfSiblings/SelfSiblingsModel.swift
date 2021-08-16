//
//  SelfSiblingsModel.swift
//  
//
//  Created by Brian Strobach on 8/13/21.
//

import FluentKit
import Foundation
import Vapor

private extension FieldKey {
    static var name: Self { "name" }
}

public final class UserModel: Model, Content {

    public static var schema: String {
        "UserModel"
    }

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @SelfSiblingsProperty(through: FriendshipModel.self, from: \.$fromUser, to: \.$toUser)
    public var socialGraph: [UserModel]

    public init() {}

    public init(id: UUID? = nil,
                name: String) {
        self.id = id
        self.name = name
    }
}

public class UserModelMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(UserModel.schema)
            .id()
            .field(.name, .string, .required)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema).delete()
    }
}

private extension FieldKey {
    static var fromUser: Self { "fromUser"}
    static var toUser: Self { "toUser"}
}

final class FriendshipModel: Model, Content {
    static let schema = "FriendshipModel"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: .fromUser)
    var fromUser: UserModel

    @Parent(key: .toUser)
    var toUser: UserModel

    init() { }


//    init(id: UUID? = nil, users: (UserModel, UserModel)) throws {
//
//        let leftID = try users.0.requireID()
//        let rightID = try users.1.requireID()
//
//        guard leftID != rightID else {
//            throw Abort(.badRequest, reason: "A sibling cannot be related to itself.")
//        }
//
//        //Friendship is represented by single connection, so we sort to create avoid duplicates.
//        let ids = [leftID, rightID].sorted { leftUUID, rightUUID in
//            leftUUID.uuidString < rightUUID.uuidString
//        }
//        self.id = id
//        self.$fromUser.id = ids[0]
//        self.$toUser.id = ids[1]
//    }
}





//MARK: SiblingModel Migration
public class FriendshipModelMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(FriendshipModel.schema)
            .id()
            .field(.toUser, .uuid, .required)
            .foreignKey(.toUser, references: UserModel.schema, .id)
            .field(.fromUser, .uuid, .required)
            .foreignKey(.fromUser, references: UserModel.schema, .id)
            .unique(on: .toUser, .fromUser)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(FriendshipModel.schema).delete()
    }
}
