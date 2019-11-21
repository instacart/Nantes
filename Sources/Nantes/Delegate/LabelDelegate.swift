//
//  LabelDelegate.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

public protocol NantesLabelDelegate: class {
    func attributedLabel(_ label: NantesLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String])
    func attributedLabel(_ label: NantesLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval)
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL)
    func attributedLabel(_ label: NantesLabel, didSelectPhoneNumber phoneNumber: String)
    func attributedLabel(_ label: NantesLabel, didSelectTextCheckingResult result: NSTextCheckingResult)
    func attributedLabel(_ label: NantesLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String])
}

public extension NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String]) { }
    func attributedLabel(_ label: NantesLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval) { }
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) { }
    func attributedLabel(_ label: NantesLabel, didSelectPhoneNumber phoneNumber: String) { }
    func attributedLabel(_ label: NantesLabel, didSelectTextCheckingResult result: NSTextCheckingResult) { }
    func attributedLabel(_ label: NantesLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String]) { }
}
