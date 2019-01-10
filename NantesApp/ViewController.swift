//
//  ViewController.swift
//  NantesApp
//
//  Created by Chris Hansen on 1/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import Nantes
import UIKit

final class ViewController: UIViewController {
    enum ExampleString: String, RawRepresentable {
        case address = "123 Main St"
        case background = "String with a background set"
        case bottomAlignment = "Bottom Alignment"
        case date = "Date: 08-27-2018"
        case filled = "Stroke filled"
        case headTruncated = "Head truncated text so we see the end of the string that has a lot of words and content inside it."
        case highlightedShadow = "Highlighted Shadow Text"
        case link = "http://www.instacart.com"
        case middleTruncated = "Middle truncated text so we see the beginning and the end, but not the middle and there's a lot of content in here so that it gets truncated."
        case otherLink = "http://www.google.com"
        case phoneNumber = "415-555-0000"
        case scaling = "Scaling text that reduces its font size so we can see more of the label when there's some constraints put on the width of the label. There's a lot of content in here that makes it feel the need to shrink."
        case shadow = "Shadowed Text"
        case stroked = "Stroked text"
        case struckOut = "this is struck out text"
        case title = "Title text: Long title that will wrap so we can see some truncated text and expand it on taps on this label.\nWith some new lines."
        case topAlignment = "Top Alignment"
        case truncatedLink = "http://www.more.com"
        case truncatedLinkText = "Truncated link text with a longer body so we'll truncate it\nMaybe a newline for good measure"
        case transitInfo = "UA450"
    }

    private var strings: [String] = []

    @IBOutlet private weak var labelStackView: UIStackView!

    @IBOutlet private weak var titleLabel: NantesLabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTitleLabel()
        setupAddressLabel()
        setupDateLabel()
        setupLinkLabel()
        setupOtherLinkLabel()
        setupPhoneNumber()
        setupTransitInfo()
        setupFancyLabel()
        setupHeadTruncatedLabel()
        setupMiddleTruncatedLabel()
        setupScalingLabel()
        setupShadowedLabel()
        setupHighlightedShadowedLabel()
        setupBottomVerticalAlignedLabel()
        setupTopVerticalAlignedLabel()
        setupFilledLabel()
        setupStrokedLabel()
        setupTruncatedAttributedToken()
    }

    private func setupTitleLabel() {
        titleLabel.attributedTruncationToken = NSAttributedString(string: "... more")
        titleLabel.numberOfLines = 3
        titleLabel.labelTappedBlock = { [weak self] in
            guard let self = self else { return }
            self.titleLabel.numberOfLines = self.titleLabel.numberOfLines == 0 ? 3 : 0

            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }

        titleLabel.text = ExampleString.title.rawValue
    }

    private func setupAddressLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
        label.text = ExampleString.address.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupDateLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        label.enabledTextCheckingTypes = [.date]
        label.text = ExampleString.date.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupLinkLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
        label.activeLinkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red] // Highlight color while the user is pressing down on the label's link
        label.text = ExampleString.link.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupOtherLinkLabel() {
        let label: NantesLabel = .init(frame: .zero)
        let string = NSAttributedString(string: ExampleString.otherLink.rawValue)
        label.attributedText = string

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let result = detector.matches(in: string.string, options: .withTransparentBounds, range: NSRange(location: 0, length: string.length)).first else {
            return
        }

        let labelLink = NantesLabelLink(attributes: [NSAttributedString.Key.foregroundColor: UIColor.red], activeAttributes: nil, inactiveAttributes: nil, linkTappedBlock: { _, link in
            print("Tapped other link: \(link)")
        }, result: result)
        label.addLink(labelLink)
        labelStackView.addArrangedSubview(label)
    }

    private func setupPhoneNumber() {
        let label: NantesLabel = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        label.text = ExampleString.phoneNumber.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupTransitInfo() {
        let label: NantesLabel = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.purple]
        label.enabledTextCheckingTypes = [.transitInformation]
        label.text = ExampleString.transitInfo.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupFancyLabel() {
        let label: NantesLabel = .init(frame: .zero)
        let attributedText = NSMutableAttributedString(string: "\(ExampleString.background.rawValue) ", attributes: [NSAttributedString.Key.backgroundColor: UIColor.lightGray])
        let struckText = NSAttributedString(string: ExampleString.struckOut.rawValue, attributes: [NSAttributedString.Key.nantesLabelStrikeOut: true])
        attributedText.append(struckText)
        label.attributedText = attributedText
        labelStackView.addArrangedSubview(label)
    }

    private func setupHeadTruncatedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.attributedTruncationToken = NSAttributedString(string: "... more")
        label.lineBreakMode = .byTruncatingHead
        label.attributedText = NSAttributedString(string: ExampleString.headTruncated.rawValue)
        labelStackView.addArrangedSubview(label)
    }

    private func setupMiddleTruncatedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.attributedTruncationToken = NSAttributedString(string: "... more")
        label.lineBreakMode = .byTruncatingMiddle
        label.attributedText = NSAttributedString(string: ExampleString.middleTruncated.rawValue)
        labelStackView.addArrangedSubview(label)
    }

    private func setupScalingLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.attributedText = NSAttributedString(string: ExampleString.scaling.rawValue, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)])
        labelStackView.addArrangedSubview(label)
    }

    private func setupShadowedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.shadowColor = .blue
        label.text = ExampleString.shadow.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupHighlightedShadowedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.highlightedTextColor = .yellow
        label.isHighlighted = true
        label.highlightedShadowColor = .green
        label.text = ExampleString.highlightedShadow.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupBottomVerticalAlignedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.verticalAlignment = .bottom
        label.text = ExampleString.bottomAlignment.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupTopVerticalAlignedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.verticalAlignment = .top
        label.text = ExampleString.topAlignment.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupFilledLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.verticalAlignment = .top
        label.attributedText = NSAttributedString(string: ExampleString.filled.rawValue, attributes: [NSAttributedString.Key.nantesLabelBackgroundFillColor: UIColor.magenta])
        labelStackView.addArrangedSubview(label)
    }

    private func setupStrokedLabel() {
        let label: NantesLabel = .init(frame: .zero)
        label.verticalAlignment = .top
        label.attributedText = NSAttributedString(string: ExampleString.stroked.rawValue, attributes: [NSAttributedString.Key.nantesLabelBackgroundStrokeColor: UIColor.magenta])
        labelStackView.addArrangedSubview(label)
    }

    private func setupTruncatedAttributedToken() {
        let label: NantesLabel = .init(frame: .zero)
        label.verticalAlignment = .top
        label.attributedTruncationToken = NSAttributedString(string: ExampleString.truncatedLink.rawValue, attributes: [NSAttributedString.Key.link: ExampleString.truncatedLink.rawValue])
        label.labelTappedBlock = {
            print("Tapped truncated link text")
        }
        label.attributedText = NSAttributedString(string: ExampleString.truncatedLinkText.rawValue, attributes: [:])
        labelStackView.addArrangedSubview(label)
    }
}

extension ViewController: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String]) {
        print("Tapped address: \(addressComponents)")
    }

    func attributedLabel(_ label: NantesLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval) {
        print("Tapped Date: \(date), in time zone: \(timeZone), with duration: \(duration)")
    }

    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        print("Tapped link: \(link)")
    }

    func attributedLabel(_ label: NantesLabel, didSelectPhoneNumber phoneNumber: String) {
        print("Tapped phone number: \(phoneNumber)")
    }

    func attributedLabel(_ label: NantesLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String]) {
        print("Tapped transit info: \(transitInfo)")
    }
}

