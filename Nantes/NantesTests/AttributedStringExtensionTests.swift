//
//  AttributedStringExtensionTests.swift
//  NantesTests
//
//  Created by Joseph Spadafora on 3/28/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import XCTest
@testable import Nantes

final class AttributedStringExtensionTests: XCTestCase {
    
    private let testUrl = URL(string: "https://www.swiftjoe.com")!
    func testReturnsLinksIfFoundInAttributedString() {
        let linkString = NSAttributedString(string: "Contains a link", attributes: [.link: testUrl])
        let existingLinks = linkString.findExistingLinks()
        XCTAssertFalse(existingLinks.isEmpty)
    }
    
    func testFindsLinksForAttributedStringsCreatedFromHTML() {
        let htmlString = "<a href=\"http://www.google.com\">I can be clicked\""
        guard let data = htmlString.data(using: .utf8) else {
            XCTFail()
            return
        }
        do{
            let attributedString = try NSAttributedString(data: data,
                                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                                          documentAttributes: nil)
            let existingLinks = attributedString.findExistingLinks()
            XCTAssertFalse(existingLinks.isEmpty)
        } catch {
            XCTFail()
        }
    }
    
    func testReturnsLinkIsEmptyIfNoAttributedLink() {
        let linkString = NSAttributedString(string: "Contains no links at all")
        let checkingResults = linkString.findExistingLinks()
        XCTAssertTrue(checkingResults.isEmpty)
    }
    
    func testCheckingResultsIsEmptyIfAttributedStringContainsAttributedLink() {
        do {
            let detector = try NSDataDetector(types: NantesLabel().enabledTextCheckingTypes.rawValue)
            let linkString = NSAttributedString(string: "Contains a link", attributes: [.link: testUrl])
            let checkingResults = linkString.findCheckingResults(usingDetector: detector)
            XCTAssertTrue(checkingResults.isEmpty)
        } catch {
            XCTFail()
        }
    }
    
    func testCheckingResultsContainsValueIfDataFoundInString() {
        do {
            let detector = try NSDataDetector(types: NantesLabel().enabledTextCheckingTypes.rawValue)
            let linkString = NSAttributedString(string: "867-5309")
            let checkingResults = linkString.findCheckingResults(usingDetector: detector)
            XCTAssertFalse(checkingResults.isEmpty)
        } catch {
            XCTFail()
        }
    }
}
