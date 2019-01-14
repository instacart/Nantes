//
//  NantesAppUITests.swift
//  NantesAppUITests
//
//  Created by Chris Hansen on 1/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import XCTest

class NantesAppUITests: XCTestCase {
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }

    func testTaps() {
        let app = XCUIApplication()
        let titlePredicate = NSPredicate(format: "label BEGINSWITH 'Title text:'")
        let titleLabel = app.staticTexts.element(matching: titlePredicate).firstMatch
        titleLabel.tap() // Expand text
        titleLabel.tap() // Collapse text

        app.staticTexts["123 Main St"].firstMatch.tap()
        app.staticTexts["Date: 08-27-2018"].firstMatch.tap()
        app.staticTexts["http://www.instacart.com"].firstMatch.tap()

        // Touches Moved
        app.staticTexts["http://www.instacart.com"].firstMatch.press(forDuration: 0.2, thenDragTo: titleLabel)

        app.staticTexts["http://www.google.com"].firstMatch.tap()

        app.staticTexts["415-555-0000"].firstMatch.tap()
        app.staticTexts["UA450"].firstMatch.tap()

        app.staticTexts["String with a background set this is struck out text"].firstMatch.tap()

        let headPredicate = NSPredicate(format: "label BEGINSWITH 'Head truncated'")
        let headLabel = app.staticTexts.element(matching: headPredicate).firstMatch
        headLabel.tap()

        let middlePredicate = NSPredicate(format: "label BEGINSWITH 'Middle truncated'")
        let middleLabel = app.staticTexts.element(matching: middlePredicate).firstMatch
        middleLabel.tap()

        let scalingPredicate = NSPredicate(format: "label BEGINSWITH 'Scaling text'")
        let scalingLabel = app.staticTexts.element(matching: scalingPredicate).firstMatch
        scalingLabel.tap()

        app.staticTexts["Shadowed Text"].firstMatch.tap()
        app.staticTexts["Highlighted Shadow Text"].firstMatch.tap()
        app.staticTexts["Bottom Alignment"].firstMatch.tap()
        app.staticTexts["Top Alignment"].firstMatch.tap()
        app.staticTexts["Stroke filled"].firstMatch.tap()
        app.staticTexts["Stroked text"].firstMatch.tap()

        let truncatedLinkPredicate = NSPredicate(format: "label BEGINSWITH 'Truncated link text'")
        let truncatedLinkLabel = app.staticTexts.element(matching: truncatedLinkPredicate).firstMatch
        truncatedLinkLabel.tap()
    }
}
