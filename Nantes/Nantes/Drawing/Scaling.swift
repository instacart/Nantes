//
//  Scaling.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

extension NantesLabel {
    private var lineBreakWordWrapTextWidthScalingFactor: CGFloat { return CGFloat(Double.pi / M_E) }

    /// if the text width is greater than our available width we'll scale the font down
    /// Returns the scaled down NSAttributedString otherwise nil if we didn't scale anything
    func scaleAttributedTextIfNeeded(_ attributedText: NSAttributedString) -> NSAttributedString? {
        let maxSize = numberOfLines > 1 ? CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) : .zero

        var textWidth = sizeThatFits(maxSize).width
        let availableWidth = frame.size.width * CGFloat(numberOfLines)
        if numberOfLines > 1 && lineBreakMode == .byWordWrapping {
            textWidth *= lineBreakWordWrapTextWidthScalingFactor
        }

        if textWidth > availableWidth && textWidth > 0.0 {
            var scaleFactor = availableWidth / textWidth
            if minimumScaleFactor > scaleFactor {
                scaleFactor = minimumScaleFactor
            }

            return NSAttributedString.attributedStringByScaling(attributedString: attributedText, scale: scaleFactor)
        }

        return nil
    }
}
