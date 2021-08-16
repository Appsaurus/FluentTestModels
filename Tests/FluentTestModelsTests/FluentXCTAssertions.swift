//
//  FluentXCTAssertions.swift
//  
//
//  Created by Brian Strobach on 8/11/21.
//

import Foundation
import XCTest
import Fluent

//public func XCTAssert<D: Database, R>(query: QueryBuilder<D, R>, hasCount count: Int) {
//    XCTAssertEqual(try query.count().wait(), count)
//}
//
//public func XCTAssert<M: Model>(model: M.Type, hasCount count: Int, on conn: DatabaseConnectable){
//    XCTAssert(query: M.query(on: conn), hasCount: count)
//}
public func XCTAssertJSONEqual<E: Encodable>(_ source: E, candidates: E...) {
    XCTAssert(jsonIsEqual(source, candidates: candidates))
}

public func XCTAssertJSONNotEqual<E: Encodable>(_ source: E, candidates: E...) {
    XCTAssertFalse(jsonIsEqual(source, candidates: candidates))
}

public func jsonIsEqual<E: Encodable>(_ source: E, candidates: [E]) -> Bool{
//    let encoder = JSONEncoder()
    let sourceData = try! source.encodeAsJSONString()
//    let sourceData: Data = try! encoder.encode(source)
    return !candidates.contains(where: {try! $0.encodeAsJSONString() != sourceData})
}

public func XCTAssertReferencingSameEntity<RE: Model>(_ target: RE, _ testCandidates: RE...) {
    testCandidates.forEach { (testCandidate) in
        XCTAssert(target.isReferencingSameEntity(as: testCandidate))
    }
}

public func XCTAssertAllReferencingSameEntity<RE: Model>(_ target: [RE], _ testCandidate: [RE])
    where RE.IDValue: Comparable {
        XCTAssert(target.areReferencingSameEntities(as: testCandidate))
}


extension Collection where Element: Model, Element.IDValue: Comparable {
    public func areReferencingSameEntities(as otherEntities: Self) -> Bool{
        return hasEqualValues(at: \.id, as: otherEntities)
    }
}

extension Model {
    public func isReferencingSameEntity(as entityReference: Self) -> Bool {
        return self.id == entityReference.id
    }
}

//TODO: Refactor into general Swift library
extension Collection{
    public func values<C: Comparable>(at keyPath: KeyPath<Element, C>) -> [C]{
        return self.map({$0[keyPath: keyPath]})
    }
    public func sortedValues<C: Comparable>(at keyPath: KeyPath<Element, C>) -> [C]{
        return values(at: keyPath).sorted()
    }
    public func sortedValues<C: Comparable>(at keyPath: KeyPath<Element, C>, by sorter: (C, C) throws -> Bool) throws -> [C]{
        return try values(at: keyPath).sorted(by: sorter)
    }

    public func hasEqualValues<C: Comparable>(at keyPath: KeyPath<Element, C>, as otherCollection: Self) -> Bool{
        let targetSorted = sortedValues(at: keyPath)
        let candidateSorted = otherCollection.sortedValues(at: keyPath)
        guard targetSorted.count == candidateSorted.count else { return false }
        for (index, target) in targetSorted.enumerated(){
            guard target == candidateSorted[index] else { return false }
        }
        return true
    }

    //Optional value KeyPaths
    public func values<C: Comparable>(at keyPath: KeyPath<Element, C?>) -> [C]{
        return self.map({$0[keyPath: keyPath]}).compactMap({$0})
    }

    public func sortedValues<C: Comparable>(at keyPath: KeyPath<Element, C?>) -> [C]{
        return values(at: keyPath).sorted()
    }

    public func hasEqualValues<C: Comparable>(at keyPath: KeyPath<Element, C?>, as otherCollection: Self) -> Bool{
        return self.values(at: keyPath).containsSameElements(as: otherCollection.values(at: keyPath))
    }
}

extension Collection where Element: Comparable{
    public func containsSameElements(as other: Self) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}



extension Encodable {
    public func encodeAsJSONData(using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }

    //WARN: There is some precision lost on decimals: https://bugs.swift.org/browse/SR-7054
    public func encodeAsJSONString(encoder: JSONEncoder = JSONEncoder(), stringEncoding: String.Encoding = .utf8) throws -> String{
        let jsonData = try encodeAsJSONData(using: encoder)
        guard let jsonString = String(data: jsonData, encoding: stringEncoding) else{
            let context = EncodingError.Context(codingPath: [], debugDescription: "Unable to convert data \(jsonData) from object \(self) to string.")
            throw EncodingError.invalidValue(self, context)
        }
        return jsonString
    }
}
