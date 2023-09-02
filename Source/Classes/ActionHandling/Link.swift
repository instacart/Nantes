//
//  Link.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import UIKit

extension NantesLabel {
    public typealias LinkTappedBlock = ((NantesLabel, NantesLabel.Link) -> Void)

    public struct Link: Equatable {
        public var attributes: [NSAttributedString.Key: Any]
        public var activeAttributes: [NSAttributedString.Key: Any]
        public var inactiveAttributes: [NSAttributedString.Key: Any]
        public var linkTappedBlock: NantesLabel.LinkTappedBlock?
        public var result: NSTextCheckingResult?
        public var text: String?

        public init(attributes: [NSAttributedString.Key: Any]?, activeAttributes: [NSAttributedString.Key: Any]?, inactiveAttributes: [NSAttributedString.Key: Any]?, linkTappedBlock: NantesLabel.LinkTappedBlock?, result: NSTextCheckingResult?, text: String?) {
            self.attributes = attributes ?? [:]
            self.activeAttributes = activeAttributes ?? [:]
            self.inactiveAttributes = inactiveAttributes ?? [:]
            self.linkTappedBlock = linkTappedBlock
            self.result = result
            self.text = text
        }

        public init(label: NantesLabel, result: NSTextCheckingResult?, text: String?) {
            self.init(attributes: label.linkAttributes, activeAttributes: label.activeLinkAttributes, inactiveAttributes: label.inactiveLinkAttributes, linkTappedBlock: nil, result: result, text: text)
        }

        public static func == (lhs: NantesLabel.Link, rhs: NantesLabel.Link) -> Bool {
            return (lhs.attributes as NSDictionary).isEqual(to: rhs.attributes) &&
                (lhs.activeAttributes as NSDictionary).isEqual(to: rhs.activeAttributes) &&
                (lhs.inactiveAttributes as NSDictionary).isEqual(to: rhs.inactiveAttributes) &&
                lhs.result?.range == rhs.result?.range &&
                lhs.text == rhs.text
        }
    }

    /// Adds a single link
    public func addLink(_ link: NantesLabel.Link) {
        addLinks([link])
    }

    /// Adds a link to a `url` with a specified `range`
    @discardableResult
    public func addLink(to url: URL, withRange range: NSRange) -> NantesLabel.Link? {
        return addLinks(with: [.linkCheckingResult(range: range, url: url)], withAttributes: linkAttributes).first
    }

    @discardableResult
    private func addLinks(with textCheckingResults: [NSTextCheckingResult], withAttributes attributes: [NSAttributedString.Key: Any]?) -> [NantesLabel.Link] {
        var links: [NantesLabel.Link] = []

        for result in textCheckingResults {
            var text = self.text

            if let checkingText = self.text, let range = Range(result.range, in: checkingText) {
                text = String(checkingText[range])
            }

            let link = NantesLabel.Link(attributes: attributes, activeAttributes: activeLinkAttributes, inactiveAttributes: inactiveLinkAttributes, linkTappedBlock: nil, result: result, text: text)
            links.append(link)
        }

        addLinks(links)

        return links
    }

    private func addLinks(_ links: [NantesLabel.Link]) {
        guard let attributedText = attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        for link in links {
            let attributes = link.attributes

            guard let range = link.result?.range else {
                continue
            }

            attributedText.addAttributes(attributes, range: range)
        }

        linkModels.append(contentsOf: links)

        _attributedText = attributedText
        setNeedsFramesetter()
        setNeedsDisplay()
    }

    /// Finds the link at the character index
    ///
    /// returns nil if there's no link
    private func link(at characterIndex: Int) -> NantesLabel.Link? {
        // Skip if the index is outside the bounds of the text
        guard let attributedText = attributedText,
            NSLocationInRange(characterIndex, NSRange(location: 0, length: attributedText.length)) else {
                return nil
        }

        for link in linkModels {
            guard let range = link.result?.range else {
                continue
            }

            if NSLocationInRange(characterIndex, range) {
                return link
            }
        }

        return nil
    }

    /// Tries to find the link at a point
    ///
    /// returns nil if there's no link
    public func link(at point: CGPoint) -> NantesLabel.Link? {
        guard !linkModels.isEmpty && bounds.inset(by: UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)).contains(point) else {
            return nil
        }

        // TTTAttributedLabel also does some extra bounds checking around where the point happened
        // if we can't find the link at the point depending on extendsLinkTouchArea being true
        // it adds a lot of extra checks and we're not using it right now, so I'm skipping it
        return link(at: characterIndex(at: point))
    }

    func didSetActiveLink(activeLink: NantesLabel.Link?, oldValue: NantesLabel.Link?) {
        let linkAttributes = activeLink?.activeAttributes.isEmpty == false ? activeLink?.activeAttributes : activeLinkAttributes
        guard let activeLink = activeLink,
            let attributes = linkAttributes,
            attributes.isEmpty == false else {
                if inactiveAttributedText != nil {
                    _attributedText = inactiveAttributedText
                    inactiveAttributedText = nil
                    setNeedsFramesetter()
                    setNeedsDisplay()
                }
                return
        }

        if inactiveAttributedText == nil {
            inactiveAttributedText = attributedText?.copy() as? NSAttributedString
        }

        guard let updatedAttributedString = attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        guard let linkResultRange = activeLink.result?.range else {
            return
        }

        guard linkResultRange.length > 0 &&
            NSLocationInRange(NSMaxRange(linkResultRange) - 1, NSRange(location: 0, length: updatedAttributedString.length)) else {
                return
        }

        updatedAttributedString.addAttributes(attributes, range: linkResultRange)

        _attributedText = updatedAttributedString
        setNeedsFramesetter()
        setNeedsDisplay()
        CATransaction.flush()
    }

    func checkText() {
        guard let attributedText = attributedText,
            !enabledTextCheckingTypes.isEmpty else {
                return
        }

        self.nantesQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let dataDetector = self.dataDetector else {
                return
            }
            let detectorResult = attributedText.findCheckingResults(usingDetector: dataDetector)
            let existingLinks = attributedText.findExistingLinks()
            let results = detectorResult.union(existingLinks)

            guard !results.isEmpty else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard self?.attributedText?.string == attributedText.string else {
                    // The string changed, these results aren't useful
                    return
                }
                self?.addLinks(with: Array(results), withAttributes: self?.linkAttributes)
            }
        }
    }

    private func characterIndex(at point: CGPoint) -> Int {
        guard bounds.contains(point) else {
            return NSNotFound
        }

        let txtRect = textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        guard txtRect.contains(point) else {
            return NSNotFound
        }

        guard let framesetter = framesetter,
            let attributedText = attributedText else {
                return NSNotFound
        }

        var relativePoint = CGPoint(x: point.x - txtRect.origin.x, y: point.y - txtRect.origin.y)
        relativePoint = CGPoint(x: relativePoint.x, y: txtRect.size.height - relativePoint.y)

        let path = CGMutablePath()
        path.addRect(txtRect)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributedText.length), path, nil)

        guard let lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return NSNotFound
        }

        let lineCount = numberOfLines > 0 ? min(numberOfLines, lines.count) : lines.count
        guard lineCount > 0 else {
            return NSNotFound
        }

        var index = NSNotFound
        var lineOrigins: [CGPoint] = .init(repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lineCount), &lineOrigins)

        for lineIndex in 0..<lineOrigins.count {
            var lineOrigin = lineOrigins[lineIndex]
            let line = lines[lineIndex]
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            var leading: CGFloat = 0.0

            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
            let yMin = floor(lineOrigin.y - descent)
            let yMax = ceil(lineOrigin.y + ascent)

            let penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(txtRect.width)))
            lineOrigin.x = penOffset

            // if we've already passed the point, stop
            guard relativePoint.y <= yMax else {
                break
            }

            guard relativePoint.y >= yMin,
                relativePoint.x >= lineOrigin.x && relativePoint.x <= lineOrigin.x + width else {
                    continue
            }

            let position = CGPoint(x: relativePoint.x - lineOrigin.x, y: relativePoint.y - lineOrigin.y)
            index = CTLineGetStringIndexForPosition(line, position)
            break
        }

        return index
    }
}

extension NSAttributedString {
    func findExistingLinks() -> Set<NSTextCheckingResult> {
        var relinks: Set<NSTextCheckingResult> = []
        enumerateAttribute(.link, in: NSRange(location: 0, length: length), options: []) { attribute, linkRange, _ in
            let url: URL
            if let urlAttribute = attribute as? URL {
                url = urlAttribute
            } else if let stringAttribute = attribute as? String, let urlAttribute = URL(string: stringAttribute) {
                url = urlAttribute
            } else {
                return
            }
            relinks.insert(NSTextCheckingResult.linkCheckingResult(range: linkRange, url: url))
        }
        return relinks
    }
}
