//
//  ParentChildRelationship.swift
//  FluentTestChildModels
//
//  Created by Brian Strobach on 12/1/17.
//

import Foundation
import Fluent
import Vapor

private extension FieldKey {
    static var name: Self { "name" }

}

public final class ParentModel: Model, Content {
    public static var schema: String {
        "ParentModel"
    }

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @Children(for: \.$parent)
    var children: [ChildModel]

    public init() {}

    public init(id: UUID? = nil,
                name: String) {
        self.id = id
        self.name = name
    }
}

public class ParentModelMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(ParentModel.schema)
            .id()
            .field(.name, .string, .required)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ParentModel.schema).delete()
    }
}

private extension FieldKey {
    static var parent: Self { "parent" }
}
public final class ChildModel: Model, Content {

    public static var schema: String {
        "ChildModel"
    }

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @Parent(key: .parent)
    var parent: ParentModel

    public init() {}

    public init(id: UUID? = nil,
                name: String,
                parent: ParentModel) throws {
        self.id = id
        self.name = name
        self.$parent.id = try parent.requireID()
    }
}

public class ChildModelMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(ChildModel.schema)
            .id()
            .field(.name, .string, .required)
            .field(.parent, .uuid, .required)
            .foreignKey(.parent, references: ParentModel.schema, .id)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ChildModel.schema).delete()
    }
}

