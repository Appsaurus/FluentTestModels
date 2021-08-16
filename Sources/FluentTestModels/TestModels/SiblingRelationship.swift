//
//  SiblingRelationship.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 12/11/17.
//

import Fluent
import Vapor

public final class StudentModel: Model, Content {

    public static let schema: String = "StudentModel"

    @ID(key: .id)
    public var id: UUID?

    @Siblings(through: EnrollmentModel.self, from: \.$student, to: \.$class)
    var classes: [ClassModel]

    public init() {}
}

extension StudentModel: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(StudentModel.schema)
            .id()
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(StudentModel.schema).delete()
    }
 }

public final class ClassModel: Model, Content {

    public static let schema: String = "ClassModel"

    @ID(key: .id)
    public var id: UUID?

    @Siblings(through: EnrollmentModel.self, from: \.$class, to: \.$student)
    var students: [StudentModel]

    public init() {}
}

extension ClassModel: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(ClassModel.schema)
            .id()
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ClassModel.schema).delete()
    }
 }

private extension FieldKey {
    static var studentID: Self { "studentID" }
    static var classID: Self { "classID" }
}

public final class EnrollmentModel: Model, Content {

    public static let schema = "EnrollmentModel"

     @ID(key: .id)
    public var id: UUID?

    @Parent(key: .classID)
     var `class`: ClassModel

    @Parent(key: .studentID)
     var student: StudentModel

    public init() { }
}

extension EnrollmentModel: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(EnrollmentModel.schema)
            .id()
            .field(.studentID, .uuid, .required)
            .field(.classID, .uuid, .required)
            .unique(on: .studentID, .classID)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(EnrollmentModel.schema).delete()
    }
 }
