//
//  Drawing.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

extension NantesLabel {
    var flushFactor: CGFloat {
        switch textAlignment {
        case .center: return 0.5
        case .right: return 1.0
        default: return 0.0
        }
    }

    override open func drawText(in rect: CGRect) {
        guard var attributedText = attributedText else {
            super.drawText(in: rect)
            return
        }

        let originalAttributedText: NSAttributedString? = attributedText.copy() as? NSAttributedString

        if adjustsFontSizeToFitWidth && numberOfLines > 0 {
            // Scale the font down if need be, to fit the width
            if let scaledAttributedText = scaleAttributedTextIfNeeded(attributedText) {
                _attributedText = scaledAttributedText
                setNeedsFramesetter()
                attributedText = scaledAttributedText
            }
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        defer {
            context.restoreGState()
        }

        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0.0, y: rect.size.height)
        // invert context to match iOS coordinates, otherwise we'll draw upside down
        context.scaleBy(x: 1.0, y: -1.0)

        let textRange = CFRangeMake(0, attributedText.length)
        let limitedRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)

        context.translateBy(x: rect.origin.x, y: rect.size.height - limitedRect.origin.y - limitedRect.size.height)

        if let shadowColor = shadowColor, !isHighlighted {
            context.setShadow(offset: shadowOffset, blur: shadowRadius, color: shadowColor.cgColor)
        } else if let highlightedShadowColor = highlightedShadowColor {
            context.setShadow(offset: shadowOffset, blur: shadowRadius, color: highlightedShadowColor.cgColor)
        }

        if let highlightedTextColor = highlightedTextColor, isHighlighted {
            drawHighlightedString(renderedAttributedText, highlightedTextColor: highlightedTextColor, textRange: textRange, inRect: limitedRect, context: context)
        } else {
            guard let framesetter = framesetter,
                let renderedAttributedText = renderedAttributedText else {
                    return
            }

            drawAttributedString(renderedAttributedText, inFramesetter: framesetter, textRange: textRange, inRect: limitedRect, context: context)
        }

        // If we had to scale it to fit, lets reset to the original attributed text
        if let originalAttributedText = originalAttributedText, originalAttributedText != attributedText {
            _attributedText = originalAttributedText
        }
    }

    private func drawAttributedString(_ attributedString: NSAttributedString, inFramesetter framesetter: CTFramesetter, textRange: CFRange, inRect rect: CGRect, context: CGContext) {
        let path = CGMutablePath()
        path.addRect(rect)
        let frame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

        guard var lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return
        }

        // We don't want to handle truncation for lineBreakModes .byWordWrapping, .byCharWrapping, or .byClipping
        let shouldHandleTruncation = lineBreakMode == .byTruncatingHead || lineBreakMode == .byTruncatingMiddle || lineBreakMode == .byTruncatingTail

        // If we have more lines than number of lines, we should paint truncation
        let hasExtraLines = self.numberOfLines != 0 && self.numberOfLines < lines.count

        // If our last line's range is less than our total strings range, we should paint truncation
        guard let lastLine = lines.last else {
            return
        }
        let lastLineRange = NSRange(range: CTLineGetStringRange(lastLine))
        let isPaintingTruncatedString = lastLineRange.location + lastLineRange.length < textRange.location + textRange.length

        if shouldHandleTruncation && (hasExtraLines || isPaintingTruncatedString) {
            lines = truncateLines(lines, fromAttritubedString: attributedString, rect: rect, path: path)
        }

        drawBackground(frame, inRect: rect, context: context)

        let numberOfLines = self.numberOfLines > 0 ? min(self.numberOfLines, lines.count) : lines.count

        var lineOrigins: [CGPoint] = .init(repeating: .zero, count: numberOfLines)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), &lineOrigins)

        for lineIndex in 0..<lineOrigins.count {
            let lineOrigin = lineOrigins[lineIndex]
            context.textPosition = lineOrigin
            let line = lines[lineIndex]

            var descent: CGFloat = 0.0
            CTLineGetTypographicBounds(line, nil, &descent, nil)

            let penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(rect.size.width)))
            let yOffset = lineOrigin.y - descent - font.descender
            context.textPosition = CGPoint(x: penOffset, y: yOffset)
            CTLineDraw(line, context)
        }

        drawStrike(frame: frame, inRect: rect, context: context)
    }

    private func drawHighlightedString(_ highlightedAttributedString: NSAttributedString?, highlightedTextColor: UIColor, textRange: CFRange, inRect textRect: CGRect, context: CGContext) {
        guard let highlightAttributedString = highlightedAttributedString?.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        highlightAttributedString.addAttribute(.foregroundColor, value: highlightedTextColor, range: NSRange(location: 0, length: highlightAttributedString.length))

        let framesetter = highlightFramesetter ?? CTFramesetterCreateWithAttributedString(highlightAttributedString)
        highlightFramesetter = framesetter

        drawAttributedString(highlightAttributedString, inFramesetter: framesetter, textRange: textRange, inRect: textRect, context: context)
    }

    /// Seems like there's some frame issues with our background drawing here
    /// Falling back to using the normal background drawing seems to look alright
    /// TODO: Chris - Investigate frame issues here
    private func drawBackground(_ frame: CTFrame, inRect rect: CGRect, context: CGContext) {
        guard let lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return
        }

        var origins: [CGPoint] = .init(repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)

        var lineIndex = 0
        for line in lines {
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            var leading: CGFloat = 0.0

            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

            guard let glyphRuns = CTLineGetGlyphRuns(line) as [AnyObject] as? [CTRun] else {
                continue
            }

            for glyphRun in glyphRuns {
                guard let attributes = CTRunGetAttributes(glyphRun) as NSDictionary as? [NSAttributedString.Key: Any] else {
                    continue
                }

                let strokeColor: UIColor? = attributes[.nantesLabelBackgroundStrokeColor] as? UIColor
                let fillColor: UIColor? = attributes[.nantesLabelBackgroundFillColor] as? UIColor
                let fillPadding: UIEdgeInsets = attributes[.nantesLabelBackgroundFillPadding] as? UIEdgeInsets ?? .zero
                let cornerRadius: CGFloat = attributes[.nantesLabelBackgroundCornerRadius] as? CGFloat ?? 0.0
                let lineWidth: CGFloat = attributes[.nantesLabelBackgroundLineWidth] as? CGFloat ?? 0.0

                guard strokeColor != nil || fillColor != nil else {
                    lineIndex += 1
                    continue
                }

                var runBounds: CGRect = .zero
                var runAscent: CGFloat = 0.0
                var runDescent: CGFloat = 0.0

                runBounds.size.width = CGFloat(CTRunGetTypographicBounds(glyphRun, CFRange(location: 0, length: 0), &runAscent, &runDescent, nil)) + fillPadding.left + fillPadding.right
                runBounds.size.height = runAscent + runDescent + fillPadding.top + fillPadding.bottom

                var xOffset: CGFloat = 0.0
                let glyphRange = CTRunGetStringRange(glyphRun)

                switch CTRunGetStatus(glyphRun) {
                case .rightToLeft:
                    xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location + glyphRange.length, nil)
                default:
                    xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location, nil)
                }

                runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset - fillPadding.left - rect.origin.x
                runBounds.origin.y = origins[lineIndex].y + rect.origin.y - fillPadding.bottom - rect.origin.y - runDescent

                // We don't want to draw too far to the right
                runBounds.size.width = runBounds.width > width ? width : runBounds.width

                let roundedRect = runBounds.inset(by: linkBackgroundEdgeInset).insetBy(dx: lineWidth, dy: lineWidth)
                let path: CGPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius).cgPath

                context.setLineJoin(.round)

                if let fillColor = fillColor {
                    context.setFillColor(fillColor.cgColor)
                    context.addPath(path)
                    context.fillPath()
                }

                if let strokeColor = strokeColor {
                    context.setStrokeColor(strokeColor.cgColor)
                    context.addPath(path)
                    context.strokePath()
                }
            }

            lineIndex += 1
        }
    }

    private func drawStrike(frame: CTFrame, inRect: CGRect, context: CGContext) {
        guard let lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return
        }

        var origins: [CGPoint] = .init(repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)

        var lineIndex: Int = 0

        for line in lines {
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            var leading: CGFloat = 0.0

            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

            guard let glyphRuns = CTLineGetGlyphRuns(line) as [AnyObject] as? [CTRun] else {
                continue
            }

            for glyphRun in glyphRuns {
                guard let attributes = CTRunGetAttributes(glyphRun) as NSDictionary as? [NSAttributedString.Key: Any] else {
                    continue
                }

                guard let strikeOut = attributes[.nantesLabelStrikeOut] as? Bool, strikeOut else {
                    continue
                }

                let superscriptStyle = attributes[kCTSuperscriptAttributeName as NSAttributedString.Key] as? Int

                var runBounds: CGRect = .zero
                var runAscent: CGFloat = 0.0
                var runDescent: CGFloat = 0.0

                runBounds.size.width = CGFloat(CTRunGetTypographicBounds(glyphRun, CFRange(location: 0, length: 0), &runAscent, &runDescent, nil))
                runBounds.size.height = runAscent + runDescent

                var xOffset: CGFloat = 0.0
                let glyphRange: CFRange = CTRunGetStringRange(glyphRun)

                switch CTRunGetStatus(glyphRun) {
                case .rightToLeft:
                    xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location + glyphRange.length, nil)
                default:
                    xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location, nil)
                }

                runBounds.origin.x = origins[lineIndex].x + xOffset
                runBounds.origin.y = origins[lineIndex].y - runDescent

                // Don't draw strikeout too far to the right
                runBounds.size.width = runBounds.width > width ? width : runBounds.width

                switch superscriptStyle {
                case 1:
                    runBounds.origin.y -= runAscent * 0.47
                case 2:
                    runBounds.origin.y -= runAscent * 0.25
                default: break
                }

                let color: UIColor = attributes[.foregroundColor] as? UIColor ?? .black
                context.setStrokeColor(color.cgColor)

                guard let myFont = self.font else {
                    continue
                }

                let font = CTFontCreateWithName(myFont.fontName as CFString, myFont.pointSize, nil)
                context.setLineWidth(CTFontGetUnderlineThickness(font))

                let y = round(runBounds.origin.y + (runBounds.size.height / 2.0))
                context.move(to: CGPoint(x: runBounds.origin.x, y: y))
                context.addLine(to: CGPoint(x: runBounds.origin.x + runBounds.size.width, y: y))

                context.strokePath()
            }

            lineIndex += 1
        }
    }
}
