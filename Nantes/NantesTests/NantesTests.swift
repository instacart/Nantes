//
//  NantesLabelTests.swift
//  InstacartTests
//
//  Created by Chris Hansen on 1/7/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import XCTest
@testable import Nantes

final class NantesLabelTests: XCTestCase {
    var label: NantesLabel = .init(frame: .zero)

    override func setUp() {
        super.setUp()
        label = .init(frame: .zero)
    }

    func testInit() {
        let label: NantesLabel = .init(frame: .zero)
        XCTAssertNil(label.attributedText)
        XCTAssertNil(label.text)
    }

    func testLabelLink() {
        label.activeLinkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]

        let labelLink: NantesLabel.Link = .init(attributes: nil, activeAttributes: nil, inactiveAttributes: nil, linkTappedBlock: nil, result: nil, text: nil)
        XCTAssertNil(labelLink.result)

        let anotherLink: NantesLabel.Link = .init(label: label, result: nil, text: nil)
        XCTAssertNil(anotherLink.result)

        XCTAssertFalse(labelLink == anotherLink)

        let equalLabel: NantesLabel.Link = .init(attributes: nil, activeAttributes: nil, inactiveAttributes: nil, linkTappedBlock: nil, result: nil, text: nil)
        XCTAssertTrue(labelLink == equalLabel)
    }

    func testText() {
        label.text = "Test text"

        XCTAssert(label.text == "Test text")
    }

    func testAttributedText() {
        label.attributedText = NSAttributedString(string: "Test text")

        XCTAssertTrue(label.text == "Test text")
        XCTAssertTrue(label.attributedText?.string == "Test text")
    }

    func testAccessibility() {
        XCTAssertNil(label.accessibilityElements)

        label.attributedText = NSAttributedString(string: "Test text")
        XCTAssertTrue(label.accessibilityElements?.count == 1)

        let linkText = NSAttributedString(string: "http://www.instacart.com")
        label.attributedText = linkText
        addLink(linkText, to: label)
        XCTAssertTrue(label.accessibilityElements?.count == 1)

        let linkAndLeadingText = NSAttributedString(string: "Leading text and a link: http://www.instacart.com")
        label.attributedText = linkAndLeadingText
        addLink(linkAndLeadingText, to: label)
        XCTAssertTrue(label.accessibilityElements?.count == 1)
    }

    func testTextCheckingTypes() {
        label.enabledTextCheckingTypes = []
        XCTAssertTrue(label.enabledTextCheckingTypes.isEmpty)
        label.text = "http://www.instacart.com"

        label.enabledTextCheckingTypes = [.link]
        XCTAssertTrue(label.enabledTextCheckingTypes == [.link])

        // Test that prebuilt detectors are reused
        label.enabledTextCheckingTypes = [.link]
        XCTAssertTrue(label.enabledTextCheckingTypes == [.link])
    }

    func testAddLink() {
        let linkText = NSAttributedString(string: "http://www.instacart.com")
        addLink(linkText, to: label)
        XCTAssertTrue(label.linkModels.count == 0) // we shouldn't be able to add any links unless we have text

        label.attributedText = NSAttributedString()
        addLink(NSAttributedString(string: ""), to: label)
        XCTAssertTrue(label.linkModels.count == 1) // we don't add attributes for a link we can't get a range for, but we'll still add the link

        label.attributedText = NSAttributedString(string: "\(linkText.string) with text")

        addLink(linkText, to: label)

        XCTAssertTrue(label.linkModels.count == 1)
    }

    func testNumberOfLines() {
        label.numberOfLines = 1
        XCTAssertTrue(label.numberOfLines == 1)
    }

    func testCanPerform() {
        XCTAssertTrue(label.canPerformAction(#selector(label.copy(_:)), withSender: nil))
    }

    func testHitTest() {
        let badPoint = CGPoint(x: -1, y: -1)
        let goodPoint = CGPoint(x: 5, y: 5)
        let linkText = NSAttributedString(string: "http://www.instacart.com")

        label.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        label.enabledTextCheckingTypes = [.link]
        label.attributedText = linkText
        addLink(linkText, to: label)

        XCTAssertEqual(label.hitTest(goodPoint, with: nil), label)

        label.text = "Test text"
        XCTAssertEqual(label.hitTest(goodPoint, with: nil), label)
        XCTAssertNil(label.hitTest(badPoint, with: nil))

        label.isUserInteractionEnabled = false
        XCTAssertNil(label.hitTest(goodPoint, with: nil))

        label.isUserInteractionEnabled = true
    }

    func testEmptyDelegates() {
        let testClass = DelegateTestClass()
        label.delegate = testClass
        testClass.attributedLabel(label, didSelectAddress: [:])
        testClass.attributedLabel(label, didSelectDate: Date(), timeZone: TimeZone(secondsFromGMT: 0)!, duration: TimeInterval())
        testClass.attributedLabel(label, didSelectLink: URL(string: "http://www.instacart.com")!)
        testClass.attributedLabel(label, didSelectPhoneNumber: "555-555-5555")
        testClass.attributedLabel(label, didSelectTextCheckingResult: NSTextCheckingResult())
        testClass.attributedLabel(label, didSelectTransitInfo: [:])
        XCTAssertNotNil(label)
    }

    func testSizeThatFits() {
        let constraints = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let emptySize = NantesLabel.sizeThatFitsAttributedString(nil, withConstraints: constraints, limitedToNumberOfLines: 0)
        XCTAssertTrue(emptySize == .zero)

        let attributedString = NSAttributedString(string: "Test string")
        label.attributedText = attributedString
        let size = NantesLabel.sizeThatFitsAttributedString(attributedString, withConstraints: constraints, limitedToNumberOfLines: 0)
        XCTAssertTrue(size == CGSize(width: 55.0, height: 15.0))
    }

    func testAttributedStringPropertiesStay() {
        let paragraphStyle = getParagraphStyle()
        let attributedString = NSAttributedString(string: "Test string with properties", attributes: [.paragraphStyle: paragraphStyle, .kern: 30])
        addPropertiesToLabel(&label)

        label.attributedText = attributedString

        let updatedParagraphStyle = label.attributedText!.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as! NSParagraphStyle
        let updatedKern = label.attributedText!.attribute(.kern, at: 0, effectiveRange: nil) as! NSNumber

        XCTAssertEqual(updatedParagraphStyle.lineSpacing, 20)
        XCTAssertEqual(updatedParagraphStyle.minimumLineHeight, 30)
        XCTAssertEqual(updatedParagraphStyle.maximumLineHeight, 40)
        XCTAssertEqual(updatedKern.intValue, 30)
    }

    func testAttributedStringPropertiesUpdate() {
        let paragraphStyle = getParagraphStyle()
        let attributedString = NSAttributedString(string: "Test string with properties", attributes: [.paragraphStyle: paragraphStyle, .kern: 30])
        addPropertiesToLabel(&label)

        label.setAttributedText(attributedString, afterInheritingLabelAttributesAndConfiguringWithBlock: nil)

        let updatedParagraphStyle = label.attributedText!.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as! NSParagraphStyle
        let updatedKern = label.attributedText!.attribute(.kern, at: 0, effectiveRange: nil) as! NSNumber

        XCTAssertEqual(updatedParagraphStyle.lineSpacing, 21)
        XCTAssertEqual(updatedParagraphStyle.minimumLineHeight, 31)
        XCTAssertEqual(updatedParagraphStyle.maximumLineHeight, 41)
        XCTAssertEqual(updatedKern.intValue, 31)
    }

    func testAttributedStringPropertiesUpdateWithBlock() {
        let paragraphStyle = getParagraphStyle()
        let attributedString = NSAttributedString(string: "Test string with properties", attributes: [.paragraphStyle: paragraphStyle, .kern: 30])
        addPropertiesToLabel(&label)

        let promise = expectation(description: "waiting for attributes to be set")

        label.setAttributedText(attributedString) { mutableString -> NSMutableAttributedString in
            defer {
                promise.fulfill()
            }
            let range = NSRange(location: 0, length: mutableString.length)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 22
            paragraphStyle.minimumLineHeight = 32
            paragraphStyle.maximumLineHeight = 42

            mutableString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            mutableString.addAttribute(.kern, value: 32, range: range)
            return mutableString
        }

        XCTWaiter().wait(for: [promise], timeout: 2)

        let updatedParagraphStyle = label.attributedText!.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as! NSParagraphStyle
        let updatedKern = label.attributedText!.attribute(.kern, at: 0, effectiveRange: nil) as! NSNumber

        XCTAssertEqual(updatedParagraphStyle.lineSpacing, 22)
        XCTAssertEqual(updatedParagraphStyle.minimumLineHeight, 32)
        XCTAssertEqual(updatedParagraphStyle.maximumLineHeight, 42)
        XCTAssertEqual(updatedKern.intValue, 32)
    }

    private func addPropertiesToLabel(_ label: inout NantesLabel) {
        label.lineSpacing = 21
        label.minimumLineHeight = 31
        label.maximumLineHeight = 41
        label.kern = 31
    }

    private func getParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 20
        paragraphStyle.minimumLineHeight = 30
        paragraphStyle.maximumLineHeight = 40
        return paragraphStyle
    }

    private func addLink(_ link: NSAttributedString, to label: NantesLabel) {
        let dataDetector = try! NSDataDetector(types: label.enabledTextCheckingTypes.rawValue)
        let result = dataDetector.matches(in: link.string, options: .withTransparentBounds, range: NSRange(location: 0, length: link.length)).first

        let labelLink = NantesLabel.Link(attributes: [:], activeAttributes: [:], inactiveAttributes: [:], linkTappedBlock: nil, result: result, text: label.text)
        label.addLink(labelLink)
    }
}

private final class DelegateTestClass: NantesLabelDelegate { }
