//
//  FluentTestModelProtocol.swift
//  FluentTestApp
//
//  Created by Brian Strobach on 6/4/18.
//

import Foundation
import FluentSQLite
import Vapor
public typealias FluentTestModel = Reflectable & SQLiteModel & Content & Migration
