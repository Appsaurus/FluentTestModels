//
//  TestModel.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 11/28/17.
//

import Foundation
import Fluent
import FluentSQLiteDriver
import Vapor


public final class TestModel: FluentTestModel{

    public static var schema: String {
        "TestModel"
    }

    @ID(custom: .id)
	public var id: Int?

    //MARK: Basic Data Type Fields
    @Field(key: "stringField")
    public var stringField: String

    @OptionalField(key: "optionalStringField")
    public var optionalStringField: String?

    @Field(key: "intField")
    public var intField: Int

    @Field(key: "doubleField")
	public var doubleField: Double

    @Field(key: "booleanField")
	public var booleanField: Bool

    @Field(key: "dateField")
	public var dateField: Date

    //MARK: Timestamp Updated Fields
    @Timestamp(key: "createdAt", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    public var updatedAt: Date?

    @Timestamp(key: "deletedAt", on: .delete)
    public var deletedAt: Date?

    //MARK: Grouped Fields
    @Group(key: "group")
    public var groupedFields: TestGroupedFieldsModel

    @Enum(key: "stringEnum")
    public var stringEnum: TestStringEnum

    @OptionalEnum(key: "optionalStringEnum")
    public var optionalStringEnum: TestStringEnum?

    @Field(key: "rawStringEnum")
    public var rawStringEnum: TestRawStringEnum

    @OptionalField(key: "optionalRawStringEnum")
    public var optionalRawStringEnum: TestRawStringEnum?

    @Field(key: "rawIntEnum")
    public var rawIntEnum: TestRawIntEnum

    @OptionalField(key: "optionalRawIntEnum")
    public var optionalRawIntEnum: TestRawIntEnum?

    public convenience init() {
        self.init(optionalStringField: nil)
    }

    public init(id: Int? = nil,
                stringField: String = "StringValue",
                optionalStringField: String? = nil,
                intField: Int = 1,
                doubleField: Double = 2.0,
                booleanField: Bool = true,
                dateField: Date = Date(),
                groupedFields: TestGroupedFieldsModel = TestGroupedFieldsModel(),
                stringEnum: TestStringEnum = .case1,
                optionalStringEnum: TestStringEnum = .case1,
                rawStringEnum: TestRawStringEnum = .case1,
                optionalRawStringEnum: TestRawStringEnum = .case1,
                rawIntEnum: TestRawIntEnum = .case1,
                optionalRawIntEnum: TestRawIntEnum = .case1
                ) {
        self.id = id
        self.stringField = stringField
        self.optionalStringField = optionalStringField
        self.intField = intField
        self.doubleField = doubleField
        self.booleanField = booleanField
        self.dateField = dateField
        self.groupedFields = groupedFields
        self.stringEnum = stringEnum
        self.optionalStringEnum = optionalStringEnum
        self.rawStringEnum = rawStringEnum
        self.optionalRawStringEnum = optionalRawStringEnum
        self.rawIntEnum = rawIntEnum
        self.optionalRawIntEnum = optionalRawIntEnum
    }

}

//MARK: Migration
extension TestModel {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(TestModel.schema)
            .field(.id, .int, .identifier(auto: true))
            .field("stringField", .string, .required)
            .field("optionalStringField", .string)
            .field("intField", .int, .required)
            .field("doubleField", .double, .required)
            .field("booleanField", .bool, .required)
            .field("dateField", .date, .required)
            .field("createdAt", .date, .required)
            .field("updatedAt", .date)
            .field("deletedAt", .date)
            .field("group_stringField", .string, .required)
            .field("group_optionalStringField", .string)
            .field("group_intField", .int, .required)
            .field("stringEnum", .enum(TestStringEnum.self), .required)
            .field("optionalStringEnum", .enum(TestStringEnum.self))
            .field("rawStringEnum", .string, .required)
            .field("optionalRawStringEnum", .string)
            .field("rawIntEnum", .int, .required)
            .field("optionalRawIntEnum", .int)
//            .field("rawStringEnum", .enum(TestRawStringEnum.self), .required)
//            .field("optionalRawStringEnum", .enum(TestRawStringEnum.self))
//            .field("rawIntEnum", .enum(TestRawIntEnum.self), .required)
//            .field("optionalRawIntEnum", .enum(TestRawIntEnum.self))
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(TestModel.schema).delete()
    }
}

extension DatabaseSchema.DataType {

    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType {
        return .enum(type.toSchema(name: name))
    }
    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType.Enum {
        return type.toSchema(name: name)
    }
}
extension CaseIterable {
    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType{
        return .enum(toSchema(name: name))
    }


    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType.Enum {
        let name: String = name ?? String(describing: Self.self)
        let cases = allCases.map { "\($0)"}
        return .init(name: name, cases: cases)
    }
}

public final class TestGroupedFieldsModel: Fields {

    @Field(key: "stringField")
    public var stringField: String

    @OptionalField(key: "optionalStringField")
    public var optionalStringField: String?

    @Field(key: "intField")
    public var intField: Int

    public convenience init() {
        self.init(optionalStringField: nil)
    }

    public init(stringField: String = "StringValue",
                optionalStringField: String? = nil,
                intField: Int = 1) {
        self.stringField = stringField
        self.optionalStringField = optionalStringField
        self.intField = intField
    }
}


public enum TestIntEnum: Int, Codable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestStringEnum: String, Codable, RawRepresentable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestRawStringEnum: String, Codable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestRawIntEnum: Int, Codable, CaseIterable {
    case case1
    case case2
    case case3
}


