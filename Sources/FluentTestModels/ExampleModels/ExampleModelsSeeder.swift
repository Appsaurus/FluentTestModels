//
//  ExampleModelsSeeder.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 7/10/18.
//

import Foundation
import Fluent
import FluentSQLite
import FluentSeeder


public class ExampleModelsSeeder: Seeder{
	public typealias Database = SQLiteDatabase
	public static let exampleModelCount = 50
	public static let exampleSiblingModelCount = 25
	public static let exampleChildModelCount = 10
	public static let siblingsPerExampleModel = 10

	open static func seeds() -> [SeedProtocol]{
		return [
			//Seed models first
			Seed<ExampleModel>(count: exampleModelCount),
			Seed<ExampleSiblingModel>(count: exampleSiblingModelCount),
			Seed<ExampleChildModel>(count: exampleChildModelCount),

			//Then relationships that depend on those models existing
			SiblingSeed<ExampleModelSiblingPivot>(count: siblingsPerExampleModel),
			ParentSeed<ExampleModel, ExampleChildModel>(at: \.optionalParentModelId)
		]
	}
}
