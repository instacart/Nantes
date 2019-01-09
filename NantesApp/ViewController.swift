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
        case title = "Sed et quam bibendum, interdum lacus at, convallis orci. Duis scelerisque convallis mauris, quis faucibus odio aliquam sit amet. Donec eleifend egestas dui non volutpat. Proin ac aliquet ligula, in consectetur quam. Phasellus luctus rutrum faucibus. Nulla facilisi. Integer eleifend lectus a massa laoreet, eget feugiat dui elementum. Suspendisse cursus aliquam urna nec posuere."
        case address = "123 Main St"
        case date = "Date: 08-27-2018, Another date: Aug 27, 2018"
        case link = "http://www.instacart.com"
        case phoneNumber = "415-555-0000"
        case transitInfo = "UA450"
    }

    private var strings: [String] = []

    @IBOutlet private weak var labelStackView: UIStackView!

    @IBOutlet private weak var titleLabel: Label!
    @IBOutlet private weak var linkText: Label!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTitleLabel()
        setupAddressLabel()
        setupDateLabel()
        setupLinkLabel()
        setupPhoneNumber()
        setupTransitInfo()
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
        let label: Label = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
        label.text = ExampleString.address.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupDateLabel() {
        let label: Label = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        label.enabledTextCheckingTypes = [.date]
        label.text = ExampleString.date.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupLinkLabel() {
        linkText.delegate = self
        linkText.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
        linkText.activeLinkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red] // Highlight color while the user is pressing down on the label's link
        linkText.text = ExampleString.link.rawValue
    }

    private func setupPhoneNumber() {
        let label: Label = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        label.text = ExampleString.phoneNumber.rawValue
        labelStackView.addArrangedSubview(label)
    }

    private func setupTransitInfo() {
        let label: Label = .init(frame: .zero)
        label.delegate = self
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.purple]
        label.enabledTextCheckingTypes = [.transitInformation]
        label.text = ExampleString.transitInfo.rawValue
        labelStackView.addArrangedSubview(label)
    }
}

extension ViewController: LabelDelegate {
    func attributedLabel(_ label: Label, didSelectAddress addressComponents: [NSTextCheckingKey: String]) {
        print("Tapped address: \(addressComponents)")
    }

    func attributedLabel(_ label: Label, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval) {
        print("Tapped Date: \(date), in time zone: \(timeZone), with duration: \(duration)")
    }

    func attributedLabel(_ label: Label, didSelectLink link: URL) {
        print("Tapped link: \(link)")
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }

    func attributedLabel(_ label: Label, didSelectPhoneNumber phoneNumber: String) {
        print("Tapped phone number: \(phoneNumber)")
    }

    func attributedLabel(_ label: Label, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String]) {
        print("Tapped transit info: \(transitInfo)")
    }
}

