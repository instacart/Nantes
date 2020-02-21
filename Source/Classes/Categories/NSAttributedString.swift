//
//  NSAttributedString.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

extension NSAttributedString {
    static func attributes(from label: NantesLabel) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]

        attributes[.font] = label.font
        attributes[.foregroundColor] = label.textColor
        attributes[.kern] = label.kern

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = label.textAlignment
        paragraphStyle.lineSpacing = label.lineSpacing
        paragraphStyle.minimumLineHeight = label.minimumLineHeight > 0 ? label.minimumLineHeight : label.font.lineHeight * label.lineHeightMultiple
        paragraphStyle.maximumLineHeight = label.maximumLineHeight > 0 ? label.maximumLineHeight : label.font.lineHeight * label.lineHeightMultiple
        paragraphStyle.lineHeightMultiple = label.lineHeightMultiple
        paragraphStyle.firstLineHeadIndent = label.firstLineIndent

        paragraphStyle.lineBreakMode = label.numberOfLines == 1 ? label.lineBreakMode : .byWordWrapping

        attributes[.paragraphStyle] = paragraphStyle

        return attributes
    }

    static func attributedStringByScaling(attributedString: NSAttributedString, scale: CGFloat) -> NSAttributedString? {
        guard let scaledString = attributedString.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }

        scaledString.enumerateAttribute(.font, in: NSRange(location: 0, length: scaledString.length), options: [], using: { value, range, _ in
            guard let font = value as? UIFont else {
                return
            }

            let fontName = font.fontName
            let pointSize = font.pointSize

            scaledString.removeAttribute(.font, range: range)
            let scaledFont = UIFont(name: fontName, size: floor(pointSize * scale))
            scaledString.addAttribute(.font, value: scaledFont as Any, range: range)
        })

        return scaledString
    }

    static func attributedStringBySettingColor(attributedString: NSAttributedString, color: UIColor) -> NSAttributedString {
        guard let copy = attributedString.mutableCopy() as? NSMutableAttributedString else {
            return attributedString
        }

        copy.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: copy.length), options: []) { value, range, _ in
            guard (value as? Bool) == true else {
                return
            }

            copy.setAttributes([.foregroundColor: color], range: range)
            copy.removeAttribute(kCTForegroundColorFromContextAttributeName as NSAttributedString.Key, range: range)
        }

        return copy
    }

    func findCheckingResults(usingDetector dataDetector: NSDataDetector) -> Set<NSTextCheckingResult> {
        Set(dataDetector.matches(in: string,
                                 options: .withTransparentBounds,
                                 range: NSRange(location: 0,
                                                length: length)))
    }
}
