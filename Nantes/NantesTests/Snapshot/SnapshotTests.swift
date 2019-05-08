//
//  SnapshotTests.swift
//  NantesTests
//
//  Created by Chris Hansen on 4/16/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

@testable import Nantes

import SnapshotTesting
import XCTest

// swiftlint:disable force_try

final class SnapshotTests: XCTestCase {
    var label: NantesLabel = .init(frame: .zero)
    var viewController: UIViewController = .init()
    var stackView: UIStackView = .init()
    var labelTappedExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        viewController = UIViewController()
        stackView = UIStackView()
        label = .init(frame: .zero)

        viewController.view.addSubview(stackView)
        stackView.frame = viewController.view.frame
        stackView.addArrangedSubview(label)
    }

    func testAddress() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.text = "123 Main st. Other text"

        waitForLinks(count: 1)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testDate() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.enabledTextCheckingTypes = [.date]
        label.text = "Date: 08-27-2018"

        waitForLinks(count: 1)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLink() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.text = "https://www.instacart.com"

        waitForLinks(count: 1)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testOtherLinks() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        let text = NSAttributedString(string: "https://www.instacart.com and https://www.google.com")
        label.attributedText = text

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let result = detector.matches(in: text.string, options: .withTransparentBounds, range: NSRange(location: 0, length: text.length))
        for link in result {
            let labelLink = NantesLabel.Link(attributes: [.foregroundColor: UIColor.red], activeAttributes: nil, inactiveAttributes: nil, linkTappedBlock: nil, result: link, text: link.url!.absoluteString)
            label.addLink(labelLink)
        }

        XCTAssertTrue(label.linkModels.count == 2)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testPhoneNumber() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.enabledTextCheckingTypes = [.phoneNumber]
        label.text = "555-555-5555"

        waitForLinks(count: 1)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testTransit() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.enabledTextCheckingTypes = [.transitInformation]
        label.text = "UA450"

        waitForLinks(count: 1)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLabelNoDelegate() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.text = "http://www.instacart.com"

        waitForLinks(count: 1)
        label.handleLinkTapped(label.linkModels.first!)

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLinkWithBlockTapped() {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        let text = NSAttributedString(string: "https://www.instacart.com")
        label.attributedText = text
        labelTappedExpectation = expectation(description: "waiting for label tap")

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let result = detector.matches(in: text.string, options: .withTransparentBounds, range: NSRange(location: 0, length: text.length))
        var l: NantesLabel.Link!
        for link in result {
            let labelLink = NantesLabel.Link(attributes: [.foregroundColor: UIColor.red], activeAttributes: nil, inactiveAttributes: nil, linkTappedBlock: { _, _ in
                self.labelTappedExpectation?.fulfill()
            }, result: link, text: link.url!.absoluteString)
            l = labelLink
            label.addLink(labelLink)
        }

        label.handleLinkTapped(l)
        wait(for: [labelTappedExpectation!], timeout: 0.25)

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testAddressTapped() {
        tapLabel(withText: "123 Main St")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testDateTapped() {
        label.enabledTextCheckingTypes = [.date]
        tapLabel(withText: "08-27-2018")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLinkTapped() {
        tapLabel(withText: "https://www.instacart.com")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testPhoneNumberTapped() {
        label.enabledTextCheckingTypes = [.phoneNumber]
        tapLabel(withText: "555-555-5555")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testTransitInfoTapped() {
        label.enabledTextCheckingTypes = [.transitInformation]
        tapLabel(withText: "UA450")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testFancyLabel() {
        let attributedText = NSMutableAttributedString(string: "Background set ", attributes: [.backgroundColor: UIColor.lightGray])
        attributedText.append(NSAttributedString(string: "Struck text", attributes: [.nantesLabelStrikeOut: true]))
        label.attributedText = attributedText

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testHeadTruncated() {
        label.attributedTruncationToken = NSAttributedString(string: "... more")
        label.lineBreakMode = .byTruncatingHead
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testMiddleTruncated() {
        label.attributedTruncationToken = NSAttributedString(string: "... more")
        label.lineBreakMode = .byTruncatingMiddle
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testScaling() {
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLineBreakWordWrapScaling() {
        let longTestString = "Longer test string that will wrap and force the label to scale down in size so that it can make everything fit inside it's smaller frames and have a bit more text"
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 12.0)
        label.text = longTestString

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testMinimumScaleFactorScaling() {
        let longTestString = "Longer test string that will wrap and force the label to scale down in size so that it can make everything fit inside it's smaller frames and have a bit more text"
        label.numberOfLines = 2
        label.minimumScaleFactor = 0.9
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 12.0)
        label.text = longTestString

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testNoScalingNeeded() {
        let longTestString = "Shorter text that won't wrap"
        label.numberOfLines = 2
        label.minimumScaleFactor = 0.9
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 12.0)
        label.text = longTestString

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testShadowed() {
        label.shadowColor = .blue
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testHighlightedShadowed() {
        label.isHighlighted = true
        label.highlightedTextColor = .yellow
        label.highlightedShadowColor = .green
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testBottomVerticalAlignment() {
        label.verticalAlignment = .bottom
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testTopVerticalAlignment() {
        label.verticalAlignment = .top
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testFilled() {
        label.attributedText = NSAttributedString(string: "Longer text that will wrap and will get cut off because it can't have more than one line", attributes: [.nantesLabelBackgroundFillColor: UIColor.magenta])

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testStroked() {
        label.attributedText = NSAttributedString(string: "Longer text that will wrap and will get cut off because it can't have more than one line", attributes: [.nantesLabelBackgroundStrokeColor: UIColor.magenta])

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testTruncatedAttributionToken() {
        label.attributedTruncationToken = NSAttributedString(string: "https://instacart.com", attributes: [.link: "https://instacart.com"])
        label.attributedText = NSAttributedString(string: "Longer text that will wrap and will get cut off because it can't have more than one line")

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testPrivacyPolicy() {
        let text = "Privacy Policy and Terms of Service"
        label.text = text
        label.linkAttributes = [
            .foregroundColor: UIColor.green,
            .font: UIFont.systemFont(ofSize: 14.0)
        ]
        label.activeLinkAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.green,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14.0)
        ]
        label.addLink(to: URL(string: "https://www.google.com")!, withRange: (text as NSString).range(of: "Privacy Policy"))
        label.addLink(to: URL(string: "https://www.instacart.com")!, withRange: (text as NSString).range(of: "Terms of Service"))

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testLineSpace() {
        label.lineSpacing = 40.0
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14.0)
        label.text = "Longer text that will wrap and will get cut off because it can't have more than one line"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testMultiline() {
        label.numberOfLines = 0
        label.text = "Really long text that has a lont of content so we can see it wrap onto multiple lines.\nNew lines are also good."

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testTruncation() {
        label.numberOfLines = 2
        label.attributedTruncationToken = NSAttributedString(string: "... Tap to see more")
        label.text = "Really long text that has a lont of content so we can see it wrap onto multiple lines.\nNew lines are also good. More text to make it fill in some more"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    func testMutlilineTruncation() {
        label.numberOfLines = 3
        label.attributedTruncationToken = NSAttributedString(string: "...\nTap to see more")
        label.text = "Really long text that has a lont of content so we can see it wrap onto multiple lines.\nNew lines are also good. More text to make it fill in some more"

        assertSnapshot(matching: viewController, as: .image(on: .iPhone8))
    }

    private func tapLabel(withText text: String) {
        label.linkAttributes = [.foregroundColor: UIColor.green]
        label.text = text
        label.delegate = self

        waitForLinks(count: 1)

        labelTappedExpectation = expectation(description: "waiting for label delegate")
        label.handleLinkTapped(label.linkModels.first!)
        wait(for: [labelTappedExpectation!], timeout: 0.25)
    }

    private func waitForLinks(count: Int) {
        let predicate = NSPredicate { object, _ -> Bool in
            guard let label = object as? NantesLabel else { return false }
            return label.linkModels.count == count
        }

        let promise = expectation(for: predicate, evaluatedWith: label, handler: .none)

        wait(for: [promise], timeout: 2.0)
    }
}

extension SnapshotTests: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String]) { labelTappedExpectation?.fulfill() }

    func attributedLabel(_ label: NantesLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval) { labelTappedExpectation?.fulfill() }

    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) { labelTappedExpectation?.fulfill() }

    func attributedLabel(_ label: NantesLabel, didSelectPhoneNumber phoneNumber: String) { labelTappedExpectation?.fulfill() }

    func attributedLabel(_ label: NantesLabel, didSelectTextCheckingResult result: NSTextCheckingResult) { labelTappedExpectation?.fulfill() }

    func attributedLabel(_ label: NantesLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String]) { labelTappedExpectation?.fulfill() }
}
