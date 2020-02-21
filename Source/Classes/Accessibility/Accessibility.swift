//
//  Accessibility.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

final class NantesLabelAccessibilityElement: UIAccessibilityElement {
    var boundingRect: CGRect = .zero
    weak var superview: UIView?

    override var accessibilityFrame: CGRect {
        get {
            guard let superview = superview else {
                assertionFailure("LabelAccessibilityElements need a superview to setup their bounding rect correctly")
                return .zero
            }
            return UIAccessibility.convertToScreenCoordinates(boundingRect, in: superview)
        } set {}
    }
}

extension NantesLabel {
    override open var isAccessibilityElement: Bool {
        get { false }
        set { }
    }

    func configureAccessibilityElements() {
        guard attributedText != nil else {
            _accessibilityElements = nil
            return
        }

        var elements: [NantesLabelAccessibilityElement] = []
        var actions: [UIAccessibilityCustomAction] = []

        let baseElement = NantesLabelAccessibilityElement(accessibilityContainer: self)
        baseElement.accessibilityLabel = super.accessibilityLabel
        baseElement.accessibilityHint = super.accessibilityHint
        baseElement.accessibilityValue = super.accessibilityValue
        baseElement.accessibilityTraits = super.accessibilityTraits
        baseElement.boundingRect = bounds
        baseElement.superview = self
        elements.append(baseElement)

        for link in linkModels {
            guard let name = link.text, name.isEmpty == false else {
                continue
            }

            let action = UIAccessibilityCustomAction(name: name, target: self, selector: #selector(handleAccessibilityActivate(_:)))
            actions.append(action)
        }

        accessibilityElements = elements
        accessibilityCustomActions = actions
    }

    @objc private func handleAccessibilityActivate(_ action: UIAccessibilityCustomAction) {
        guard let link = linkModels.first(where: { link -> Bool in
            link.text == action.name
        }) else {
            return
        }

        handleLinkTapped(link)
    }
}
