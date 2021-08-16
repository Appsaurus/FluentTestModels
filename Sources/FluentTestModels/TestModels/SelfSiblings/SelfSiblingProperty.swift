//
//  File.swift
//  
//
//  Created by Brian Strobach on 8/12/21.
//

import FluentKit
import Foundation
import SQLKit

extension Model {
    public typealias SelfSiblings<Through> = SelfSiblingsProperty<Self, Through>
        where IDValue: Comparable, Through: Model
}

// MARK: Type

@propertyWrapper
public final class SelfSiblingsProperty<M, Through> where M: Model, Through: Model
{
    public enum AttachMethod {
        /// Always create the pivot model
        case always

        /// Only create the pivot if it doesn't already exist
        case ifNotExists
    }

    public let from: KeyPath<Through, Through.Parent<M>>
    public let to: KeyPath<Through, Through.Parent<M>>
    var idValue: M.IDValue?

    public var value: [M]?

    @ChildrenProperty<M, Through>
    public var pivots: [Through]

    public init(
        through _: Through.Type,
        from: KeyPath<Through, Through.Parent<M>>,
        to: KeyPath<Through, Through.Parent<M>>
    ) {
        self.from = from
        self.to = to
        self._pivots = ChildrenProperty<M, Through>(for: from)
    }

    public var wrappedValue: [M] {
        get {
            guard let value = self.value else {
                fatalError("Siblings relation not eager loaded, use $ prefix to access: \(name)")
            }
            return value
        }
        set {
            fatalError("Siblings relation is get-only.")
        }
    }

    public var projectedValue: SelfSiblingsProperty<M, Through> {
        return self
    }

    // MARK: Checking state

    /// Check whether a specific model is already attached through a sibling relationship.
    ///
    /// - Parameters:
    ///     - to: The model to check whether it is attached through a pivot.
    ///     - database: The database to perform check on.
    public func isAttached(to: M, on database: Database) -> EventLoopFuture<Bool> {
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        return self.isAttached(toID: toID, on: database)
    }

    /// Check whether a specific model ID is already attached through a sibling relationship.
    ///
    /// - Parameters:
    ///     - toID: The ID of the model to check whether it is attached through a pivot.
    ///     - database: The database to perform the check on.
    public func isAttached(toID: M.IDValue, on database: Database) -> EventLoopFuture<Bool> {

        let ids = sortedIDs(toID: toID)
        return Through.query(on: database)
            .filter(self.fromKeyPath == ids.fromID)
            .filter(self.toKeyPath == ids.toID)
            .first()
            .map { $0 != nil }
    }

    // MARK: Operations

    /// Attach an array model to this model through a pivot.
    ///
    /// - Parameters:
    ///     - tos: An array of models to attach through a sibling relationship
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func attach(
        _ tos: [M],
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }

        return tos.map { to -> Through in
            guard let toID = to.id else {
                fatalError("Cannot attach unsaved model.")
            }
            let pivot = Through()
            let sortedIDs = sortIDs(fromID, toID)
            pivot[keyPath: self.from].id = sortedIDs.fromID
            pivot[keyPath: self.to].id = sortedIDs.toID
            edit(pivot)
            return pivot
        }.create(on: database)
    }

    /// Attach a single model by creating a pivot model and specifying the attachment method.
    ///
    /// - Parameters:
    ///     - to: The model to attach through a sibling relationship
    ///     - method: The attachment method to use when deciding whether to create the pivot.
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func attach(
        _ to: M,
        method: AttachMethod,
        on database: Database,
        _ edit: @escaping (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        switch method {
        case .always:
            return self.attach(to, on: database, edit)
        case .ifNotExists:
            return self.isAttached(to: to, on: database).flatMap { alreadyAttached in
                if alreadyAttached {
                    return database.eventLoop.makeSucceededFuture(())
                }

                return self.attach(to, on: database, edit)
            }
        }
    }

    /// Attach a single model by creating a pivot model.
    ///
    /// - Parameters:
    ///     - to: The model to attach through a sibling relationship
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func attach(
        _ to: M,
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        let pivot = Through()
        let sortedIDs = sortIDs(fromID, toID)
        pivot[keyPath: self.from].id = sortedIDs.fromID
        pivot[keyPath: self.to].id = sortedIDs.toID
        edit(pivot)
        return pivot.save(on: database)
    }

    /// Detaches an array of models from this model by deleting each pivot.
    ///
    /// - Parameters:
    ///     - tos: An array of models to detach from this model.
    ///     - database: The database to perform the attachment on.
//    public func detach(_ tos: [M], on database: Database) -> EventLoopFuture<Void> {
//        guard let fromID = self.idValue else {
//            fatalError("Cannot detach siblings relation to unsaved model.")
//        }
//        let toIDs = tos.map { to -> M.IDValue in
//            guard let toID = to.id else {
//                fatalError("Cannot detach unsaved model.")
//            }
//            return toID
//        }
//        let sortedIDs = sortIDs(fromID, toID)
//        return Through.query(on: database)
//            .filter(self.from.appending(path: \.$id) == sortedIDs.fromID)
//            .filter(self.to.appending(path: \.$id) ~~ toIDs)
//            .delete()
//    }

    /// Detach a single model by deleting the pivot.
    ///
    /// - Parameters:
    ///     - to: The model to detach from this model.
    ///     - database: The database to perform the attachment on.
    public func detach(_ to: M, on database: Database) -> EventLoopFuture<Void> {
        let fromID = requireIDValue("Cannot detach siblings relation from unsaved model.")

        guard let toID = to.id else {
            fatalError("Cannot detach unsaved model.")
        }
        let sortedIDs = sortIDs(fromID, toID)
        return Through.query(on: database)
            .filter(self.fromKeyPath == sortedIDs.fromID)
            .filter(self.toKeyPath == sortedIDs.toID)
            .delete()
    }

//    /// Detach all models by deleting all pivots from this model.
//    public func detachAll(on database: Database) -> EventLoopFuture<Void> {
//        guard let fromID = self.idValue else {
//            fatalError("Cannot detach siblings relation from unsaved model.")
//        }
//
//        return Through.query(on: database)
//            .filter(self.from.appending(path: \.$id) == fromID)
//            .delete()
//    }

    // MARK: Query

    /// Returns a `QueryBuilder` that can be used to query the siblings.
    public func query(on database: Database) -> EventLoopFuture<QueryBuilder<M>> {

        return queryPivot(on: database).all().map { (models: [Through]) -> QueryBuilder<M> in
            let otherIDs = models.map { (model: Through) -> M.IDValue in
                let fromID = model[keyPath: self.fromKeyPath].wrappedValue
                let toID = model[keyPath: self.toKeyPath].wrappedValue
                return self.idValue == toID ? fromID : toID
            }
            return M.query(on: database).filter(\M._$id ~~ otherIDs)
        }
    }

    public func queryPivot(on database: Database) -> QueryBuilder<Through> {
        let idValue = requireIDValue()
        return Through.query(on: database)
            .group(.or) { or in
                or.filter(fromKeyPath == idValue)
                or.filter(toKeyPath == idValue)
            }
    }

    public func requireIDValue(_ errorMessage: String = "Missing idValue.") -> M.IDValue {
        guard let idValue = self.idValue else {
            fatalError(errorMessage)
        }
        return idValue
    }

    var fromKeyPath: KeyPath<Through, FieldProperty<Through, M.IDValue>> {
        self.from.appending(path: \.$id)
    }

    var toKeyPath: KeyPath<Through, FieldProperty<Through, M.IDValue>> {
        self.to.appending(path: \.$id)
    }

}

extension SelfSiblingsProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Property

extension SelfSiblingsProperty: AnyProperty { }

extension SelfSiblingsProperty: Property {
    public typealias Model = M
    public typealias Value = [M]
}

// MARK: Database

extension SelfSiblingsProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        []
    }

    public func input(to input: DatabaseInput) {
        // siblings never has input
    }

    public func output(from output: DatabaseOutput) throws {
        let key = M()._$id.key
        if output.contains(key) {
            self.idValue = try output.decode(key, as: M.IDValue.self)
            
//            self._pivots.idValue = self.idValue
        }
    }
}


// MARK: Codable

extension SelfSiblingsProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let rows = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
        }
    }

    public func decode(from decoder: Decoder) throws {
        // don't decode
    }
}

// MARK: Relation

extension SelfSiblingsProperty: Relation {
    public var name: String {
        let fromKey = Through.path(for: self.from.appending(path: \.$id))
        let toKey = Through.path(for: self.to.appending(path: \.$id))
        return "SelfSiblings<\(M.self), \(M.self), \(Through.self)>(from: \(fromKey), to: \(toKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        query(on: database).flatMap({ query in
            query.all().map {
                self.value = $0
            }
        })

    }
}
//
//// MARK: Eager Loadable
//
//extension SelfSiblingsProperty: EagerLoadable {
//    public static func eagerLoad<Builder>(
//        _ relationKey: KeyPath<M, M.Siblings<M, Through>>,
//        to builder: Builder
//    )
//        where Builder: EagerLoadBuilder, Builder.Model == M
//    {
//        let loader = SiblingsEagerLoader(relationKey: relationKey)
//        builder.add(loader: loader)
//    }
//
//
//    public static func eagerLoad<Loader, Builder>(
//        _ loader: Loader,
//        through: KeyPath<M, M.Siblings<M, Through>>,
//        to builder: Builder
//    ) where
//        Loader: EagerLoader,
//        Loader.Model == M,
//        Builder: EagerLoadBuilder,
//        Builder.Model == M
//    {
//        let loader = ThroughSiblingsEagerLoader(relationKey: through, loader: loader)
//        builder.add(loader: loader)
//    }
//}
//
//
//private struct SelfSiblingsEagerLoader<M, Through>: EagerLoader
//    where M: Model, Through: Model,
//{
//    let relationKey: KeyPath<M, M.SelfSiblings<M, Through>>
//
//    func run(models: [M], on database: Database) -> EventLoopFuture<Void> {
//        let ids = models.map { $0.id! }
//
//        let from = M()[keyPath: self.relationKey].from
//        let to = M()[keyPath: self.relationKey].to
//        return M.query(on: database)
//            .join(Through.self, on: \M._$id == to.appending(path: \.$id))
//            .filter(Through.self, from.appending(path: \.$id) ~~ Set(ids))
//            .all()
//            .flatMapThrowing
//        {
//            var map: [M.IDValue: [M]] = [:]
//            for to in $0 {
//                let fromID = try to.joined(Through.self)[keyPath: from].id
//                map[fromID, default: []].append(to)
//            }
//            for model in models {
//                model[keyPath: self.relationKey].value = map[model.id!] ?? []
//            }
//        }
//    }
//}
//
//private struct ThroughSelfSiblingsEagerLoader<M Through, Loader>: EagerLoader
//    where M: Model, Through: Model, Loader: EagerLoader, Loader.Model == M
//{
//    let relationKey: KeyPath<M, M.Siblings<M, Through>>
//    let loader: Loader
//
//    func run(models: [M], on database: Database) -> EventLoopFuture<Void> {
//        let throughs = models.flatMap {
//            $0[keyPath: self.relationKey].value!
//        }
//        return self.loader.run(models: throughs, on: database)
//    }
//}


extension SelfSiblingsProperty {
    /// Returns a `QueryBuilder` that can be used to query the siblings.
    public func sqlQuery(on database: Database) -> SQLSelectBuilder {
        guard let sqlDatabase = database as? SQLDatabase else {
            fatalError(#function + " can only be uses with an SQLDatabase ")
        }
        guard let _ = self.idValue else {
            fatalError("Cannot query siblings relation from unsaved model.")
        }

        guard let fromKey = Through.path(for: self.from.appending(path: \.$id)).first?.description else {
            fatalError("Missing keyPath for from key.")
        }

        guard let toKey = Through.path(for: self.to.appending(path: \.$id)).first?.description else {
            fatalError("Missing keyPath for to key.")
        }

        return sqlDatabase.select()
            .column("*")
            .from(M.schema)
            .join(Through.schema, on: "\(M.schema).id == \(toKey) OR \(M.schema).id == \(fromKey)")
    }

    func sortedIDs(toID: M.IDValue) -> (fromID: M.IDValue, toID: M.IDValue) {
        guard let fromID = self.idValue else {
            fatalError("Cannot check if siblings are attached to an unsaved model.")
        }

        return sortIDs(fromID, toID)

    }


    func sortIDs(_ firstID: M.IDValue, _ secondID: M.IDValue) -> (fromID: M.IDValue, toID: M.IDValue) {
        SelfSiblingIDSorter.sortIDs(firstID, secondID)
    }
}

public struct SelfSiblingIDSorter {
    static func sortModelIDs<M: Model>(_ firstModel: M, _ secondModel: M) -> (fromID: M.IDValue, toID: M.IDValue) {
        guard let firstID = firstModel.id, let secondID = secondModel.id else {
            fatalError("Siblings must both have ids set")
        }
        return sortIDs(firstID, secondID)
    }
    static func sortIDs<ID: Codable & Hashable>(_ firstID: ID, _ secondID: ID) -> (fromID: ID, toID: ID) {
        switch (firstID, secondID) {
        case (let firstID as UUID, let secondID as UUID):
            let sorted = [firstID, secondID].sorted(by: {$0.uuidString < $1.uuidString})
            return (fromID: sorted[0], toID: sorted[1]) as! (ID, ID)
        case (let firstID as String, let secondID as String):
                let sorted = [firstID, secondID].sorted()
                return (fromID: sorted[0], toID: sorted[1]) as! (ID, ID)
        case (let firstID as Int, let secondID as Int):
            let sorted = [firstID, secondID].sorted()
            return (fromID: sorted[0], toID: sorted[1]) as! (ID, ID)
        case (_, _):
            fatalError("Unsupported ID Type: \(ID.self)")
        }
    }
}



struct SelfSiblingModelMiddleware<Through: Model, M: Model>: ModelMiddleware {
    var from: KeyPath<Through, ParentProperty<Through, M>>
    var to: KeyPath<Through, ParentProperty<Through, M>>

    func create(model: Through, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // The model can be altered here before it is created.
        let ids = SelfSiblingIDSorter.sortIDs(model[keyPath: from].id, model[keyPath: to].id)
        model[keyPath: from].id = ids.fromID
        model[keyPath: to].id = ids.toID
        return next.create(model, on: db)
    }
}

extension Model {
    static func selfSiblingMiddleware<M>(from: KeyPath<Self, ParentProperty<Self, M>>,
                                         to: KeyPath<Self, ParentProperty<Self, M>>) -> SelfSiblingModelMiddleware<Self, M> {
        SelfSiblingModelMiddleware<Self, M>(from: from, to: to)
    }
}
