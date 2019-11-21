//
//  Truncation.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

extension NantesLabel {
    /// Returns an array of lines, truncated by `attributedTruncationToken`
    ///
    /// Takes into account multi line truncation tokens and replaces the original
    /// lines array with an updated array with the truncation inside it, ready
    /// for normal drawing
    func truncateLines(_ lines: [CTLine], fromAttritubedString attributedString: NSAttributedString, rect: CGRect, path: CGPath) -> [CTLine] {
        var lines = lines
        var lineBreakMode = self.lineBreakMode

        if self.numberOfLines != 1 {
            lineBreakMode = .byTruncatingTail
        }

        let truncationAttributePosition = attributedString.length - 1
        if attributedTruncationToken == nil {
            let truncationTokenString = "\u{2026}" // … unicode
            let truncationTokenStringAttributes = attributedString.attributes(at: truncationAttributePosition, effectiveRange: nil)
            attributedTruncationToken = NSAttributedString(string: truncationTokenString, attributes: truncationTokenStringAttributes)
        }

        guard let attributedTruncationString = attributedTruncationToken else {
            return lines
        }

        // We need a framesetter to draw truncation tokens that have newlines inside them
        let tokenFramesetter = CTFramesetterCreateWithAttributedString(attributedTruncationString)
        let tokenFrame = CTFramesetterCreateFrame(tokenFramesetter, CFRange(location: 0, length: attributedTruncationString.length), path, nil)
        guard let tokenLines = CTFrameGetLines(tokenFrame) as [AnyObject] as? [CTLine] else {
            return lines
        }

        guard tokenLines.count <= lines.count else {
            print("The truncation token supplied is bigger than the text inside the label, consider a shorter truncation token, otherwise all we're painting here is truncation info")
            return lines
        }

        // Walk across all the lines of truncation, replacing lines starting with our last line - the number of truncation token lines we have
        // the first line we replace, we'll truncate it, after that, we 100% replace lines of the original string with truncation lines
        for (index, tokenLine) in tokenLines.enumerated() {
            let originalIndex = self.numberOfLines - tokenLines.count + index

            // We want to replace every other line besides the first truncated line completely with the lines from the truncation token
            guard index == 0 else {
                lines[originalIndex] = tokenLine
                continue
            }

            guard 0..<lines.count ~= originalIndex else { continue }

            let originalLine = lines[originalIndex]
            let originalRange = NSRange(range: CTLineGetStringRange(originalLine))
            let originalString = NSMutableAttributedString(attributedString: attributedString.attributedSubstring(from: originalRange))

            let truncation = truncationInfo(from: originalRange.location, length: originalRange.length, for: lineBreakMode)

            let tokenRange = NSRange(range: CTLineGetStringRange(tokenLine))
            let tokenString = attributedTruncationString.attributedSubstring(from: tokenRange)
            originalString.append(tokenString)

            let truncationLine = CTLineCreateWithAttributedString(originalString)

            // CTLineCreateTruncatedLine will return nil if the truncation token is wider than the width, so we fallback to using the full truncation token
            let truncatedLine: CTLine = CTLineCreateTruncatedLine(truncationLine, Double(rect.width), truncation.type, tokenLine) ?? tokenLine

            lines[originalIndex] = truncatedLine
        }

        return lines
    }

    private func truncationInfo(from lastLineLocation: Int, length: Int, for lineBreakMode: NSLineBreakMode) -> (position: Int, type: CTLineTruncationType) {
        var position = lastLineLocation
        var truncationType: CTLineTruncationType

        switch lineBreakMode {
        case .byTruncatingHead:
            truncationType = .start
        case .byTruncatingMiddle:
            truncationType = .middle
            position += length / 2
        default:
            truncationType = .end
            position += length - 1
        }

        return (position: position, type: truncationType)
    }
}
