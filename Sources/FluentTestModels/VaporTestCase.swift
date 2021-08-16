//
//  VaporTestCase.swift
//  
//
//  Created by Brian Strobach on 8/16/21.
//

import XCTest
import XCTVapor

open class VaporTestCase: XCTestCase {

    open var app: Application!

    override open func setUp() {
        super.setUp()

        app = createApplication()
        try! configure(app)

    }

    override open func tearDown() {
        super.tearDown()
        app.shutdown()
    }

    open func createApplication() -> Application {
        Application(.testing)
    }

    open func configure(_ app: Application) throws {
        try routes(app.routes)
    }

    open func routes(_ router: Routes) throws {}

}
