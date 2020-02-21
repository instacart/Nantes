//
//  Sizing.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

extension NantesLabel {
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(super.intrinsicContentSize)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let string = renderedAttributedText,
            let framesetter = framesetter else {
                return super.sizeThatFits(size)
        }

        let labelSize = NantesLabel.suggestFrameSize(for: string, framesetter: framesetter, withSize: size, numberOfLines: numberOfLines)
        // add textInsets?

        return labelSize
    }

    /// Returns a `CGSize` that the `attributedString` fits within based on the `constraints` and number of lines from `limitedToNumberOfLines`
    public static func sizeThatFitsAttributedString(_ attributedString: NSAttributedString?, withConstraints constraints: CGSize, limitedToNumberOfLines: Int) -> CGSize {
        guard let attributedString = attributedString, attributedString.length != 0 else {
            return .zero
        }

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        return NantesLabel.suggestFrameSize(for: attributedString, framesetter: framesetter, withSize: constraints, numberOfLines: limitedToNumberOfLines)
    }

    private static func suggestFrameSize(for attributedString: NSAttributedString, framesetter: CTFramesetter, withSize size: CGSize, numberOfLines: Int) -> CGSize {
        var rangeToSize = CFRange(location: 0, length: attributedString.length)
        let constraints = CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)

        let path = CGMutablePath()

        let width = size.width > 0 ? size.width : CGFloat.greatestFiniteMagnitude
        path.addRect(CGRect(x: 0.0, y: 0.0, width: width, height: CGFloat.greatestFiniteMagnitude))
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        guard let lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return .zero
        }

        if lines.count > 0 {
            let lastVisibleLineIndex = numberOfLines > 0 ? min(numberOfLines, lines.count) - 1 : lines.count - 1
            let lastVisibleLine = lines[lastVisibleLineIndex]

            let rangeToLayout = CTLineGetStringRange(lastVisibleLine)
            rangeToSize = CFRange(location: 0, length: rangeToLayout.location + rangeToLayout.length)
        }

        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, nil, constraints, nil)

        return CGSize(width: ceil(suggestedSize.width), height: ceil(suggestedSize.height))
    }
}
