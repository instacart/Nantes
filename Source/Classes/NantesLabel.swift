//
//  NantesLabel.swift
//  Carrot
//
//  Created by Chris Hansen on 12/10/18.
//  Copyright © 2018 Instacart. All rights reserved.
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

private class NantesLabelAccessibilityElement: UIAccessibilityElement {
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

private struct TruncationDrawingContext {
    let attributedString: NSAttributedString
    let context: CGContext
    let descent: CGFloat
    let lastLineRange: CFRange
    let lineOrigin: CGPoint
    let numberOfLines: Int
    let rect: CGRect
}

public extension NSAttributedString.Key {
    public static let nantesLabelBackgroundCornerRadius: NSAttributedString.Key = .init("NantesLabelBackgroundCornerRadiusAttribute")
    public static let nantesLabelBackgroundFillColor: NSAttributedString.Key = .init("NantesLabelBackgroundFillColorAttribute")
    public static let nantesLabelBackgroundFillPadding: NSAttributedString.Key = .init("NantesLabelBackgroundFillPaddingAttribute")
    public static let nantesLabelBackgroundLineWidth: NSAttributedString.Key = .init("NantesLabelBackgroundLineWidthAttribute")
    public static let nantesLabelBackgroundStrokeColor: NSAttributedString.Key = .init("NantesLabelBackgroundStrokeColorAttribute")
    public static let nantesLabelStrikeOut: NSAttributedString.Key = .init("NantesLabelStrikeOutAttribute")
}

open class NantesLabel: UILabel {
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

    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }

    public typealias LinkTappedBlock = ((NantesLabel, NantesLabel.Link) -> Void)

    /// NSAttributedString attributes used to style active links
    /// nil or [:] will add no styling
    open var activeLinkAttributes: [NSAttributedString.Key: Any]?

    /// A token to use when the label is truncated in height. Defaults to "\u{2026}" which is "…"
    open var attributedTruncationToken: NSAttributedString?

    /// Handling for touch events after touchesEnded
    /// Warning: Will not be called if `labelTappedBlock` is supplied
    open weak var delegate: NantesLabelDelegate?

    /// A list of text checking types that are enabled for the label. The label will automatically highlight elements when `text` or `attributedText` is set if this value is supplied before they're set.
    open var enabledTextCheckingTypes: NSTextCheckingResult.CheckingType = [] {
        didSet {
            guard !enabledTextCheckingTypes.isEmpty else {
                return
            }

            let preBuiltDataDetector = NantesLabel.dataDetectorsByType[enabledTextCheckingTypes.rawValue]
            guard preBuiltDataDetector == nil else {
                dataDetector = preBuiltDataDetector
                return
            }

            do {
                let detector = try NSDataDetector(types: enabledTextCheckingTypes.rawValue)
                NantesLabel.dataDetectorsByType[enabledTextCheckingTypes.rawValue] = detector
                dataDetector = NantesLabel.dataDetectorsByType[enabledTextCheckingTypes.rawValue]
            } catch {
                print("Failed to create data detector")
            }
        }
    }

    /// The distance, in points, from the leading margin of a frame to the beginning of the line paragraph's first line. 0.0 by default
    open var firstLineIndent: CGFloat = 0.0

    /// The shadow color for the label when the label's `highlighted` property is true. Defaults to nil
    open var highlightedShadowColor: UIColor?

    /// The shadow offset for the label when the label's `highlighted` propert is true. A value of 0 indicates no blur, larger numbers indicate more blur. This can't be a negative value.
    open var highlightedShadowOffset: CGSize = .zero

    /// The shadow blur radius for the label. A value of 0 indicates no blur. Larger values indicate more blur. This can't be a negative value.
    open var highlightedShadowRadius: CGFloat = 0.0

    /// NSAttributedString attributes used to style inactive links
    /// nil or [:] will add no styling
    open var inactiveLinkAttributes: [NSAttributedString.Key: Any]?

    /// Floating point number in points; amount to modify default kerning. 0 means kerning is disabled. nil uses default kerning
    open var kern: CGFloat?

    /// Block to run whenever the label is tapped. Triggered on touchesEnded.
    /// Warning: Will disable calls to `delegate` on taps if this property is set
    open var labelTappedBlock: (() -> Void)?

    /// The line height multiple. 1.0 by default
    open var lineHeightMultiple: CGFloat = 1.0

    /// The space in points added between lines within the paragraph
    open var lineSpacing: CGFloat = 0.0

    /// NSAttributedString attributes used to style links that are detected or manually added
    /// You must specify linkAttributes before setting autodetecting or manually adding links for these
    /// attributes to be applied
    open var linkAttributes: [NSAttributedString.Key: Any]?

    /// The edge inset for the background of a link. The default value is `{0, -1, 0, -1}`.
    open var linkBackgroundEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: -1, bottom: 0, right: -1)

    /// The maximum line height within the paragraph. If the value is 0.0, the maximum line height is set to the line height of the `font`. 0.0 by default
    open var maximumLineHeight: CGFloat = 0.0

    /// The minimum line height within the paragraph. If the value is 0.0, the minimum line height is set to the line height of the `font`. 0.0 by default
    open var minimumLineHeight: CGFloat = 0.0

    /// The shadow blur radius for the label. 0 indicates no blur, larger values indicate more blur. This can't be a negative value
    open var shadowRadius: CGFloat = 0.0

    /// Vertical alignment of the text within its frame
    /// defaults to .center
    open var verticalAlignment: NantesLabel.VerticalAlignment = .center

    // MARK: - Private constants

    private let lineBreakWordWrapTextWidthScalingFactor = CGFloat(Double.pi / M_E)

    // MARK: - Private vars

    static private var dataDetectorsByType: [UInt64: NSDataDetector] = [:]

    private var _accessibilityElements: [Any]?

    private var accessibilityLock: NSLock = .init()

    private var _attributedText: NSAttributedString?

    private var activeLink: NantesLabel.Link? {
        didSet {
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
    }

    private var dataDetector: NSDataDetector?

    private var flushFactor: CGFloat {
        switch textAlignment {
        case .center: return 0.5
        case .right: return 1.0
        default: return 0.0
        }
    }

    private var framesetter: CTFramesetter? {
        framesetterLock.lock()
        if needsFramesetter {
            if let renderedAttributedText = renderedAttributedText {
                let frame = CTFramesetterCreateWithAttributedString(renderedAttributedText)
                _framesetter = frame
                highlightFramesetter = nil
                needsFramesetter = false
            }

        }
        framesetterLock.unlock()

        return _framesetter
    }

    private var _framesetter: CTFramesetter?

    private var framesetterLock: NSLock = .init()

    private var highlightFramesetter: CTFramesetter?

    private var inactiveAttributedText: NSAttributedString?

    private(set) var linkModels: [NantesLabel.Link] = []

    private var needsFramesetter: Bool = false

    private var renderedAttributedText: NSAttributedString? {
        if _renderedAttributedText == nil, let attributedText = attributedText {
            _renderedAttributedText = NSAttributedString.attributedStringBySettingColor(attributedString: attributedText, color: textColor)
        }
        return _renderedAttributedText
    }

    private var _renderedAttributedText: NSAttributedString?

    // MARK: - UILabel vars

    override open var accessibilityElements: [Any]? {
        get {
            accessibilityLock.lock()
            defer {
                accessibilityLock.unlock()
            }

            guard _accessibilityElements == nil else {
                return _accessibilityElements
            }

            configureAccessibilityElements()
            return _accessibilityElements
        } set {
            _accessibilityElements = newValue
        }
    }

    /// It's important to set `attributedText` or `text` before adding links
    /// Since we reset linkModels to make sure our links are up to date when the text changes
    override open var attributedText: NSAttributedString? {
        get {
            return _attributedText
        } set {
            guard newValue != _attributedText else {
                return
            }

            _attributedText = newValue
            setNeedsFramesetter()
            _accessibilityElements = nil
            linkModels = []

            checkText()

            setNeedsDisplay()
            invalidateIntrinsicContentSize()

            super.text = attributedText?.string
        }
    }

    override open var canBecomeFirstResponder: Bool {
        return true
    }

    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(super.intrinsicContentSize)
    }

    override open var isAccessibilityElement: Bool {
        get {
            return false
        } set { }
    }

    override open var numberOfLines: Int {
        didSet {
            accessibilityElements = nil
        }
    }

    /// It's important to set `attributedText` or `text` before adding links
    /// Since we reset linkModels to make sure our links are up to date when the text changes
    override open var text: String? {
        get {
            return attributedText?.string
        } set {
            guard let text = newValue else {
                attributedText = nil
                return
            }

            let attributes = NSAttributedString.attributes(from: self)
            attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }

    // MARK: - UILabel functions

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
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

    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard link(at: point) != nil && isUserInteractionEnabled && !isHidden && alpha > 0.0 else {
            return super.hitTest(point, with: event)
        }

        return self
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

    override open func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        guard let attributedText = attributedText,
            let framesetter = framesetter else {
                return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        }

        var textRect = bounds
        textRect.size.height = max(font.lineHeight * CGFloat(max(2, numberOfLines)), bounds.size.height)

        var textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: attributedText.length), nil, textRect.size, nil)
        textSize = CGSize(width: ceil(textSize.width), height: ceil(textSize.height))

        if textSize.height < bounds.size.height {
            var yOffset: CGFloat = 0.0
            switch verticalAlignment {
            case .center:
                yOffset = floor((bounds.height - textSize.height) / 2.0)
            case .bottom:
                yOffset = bounds.height - textSize.height
            case .top:
                break
            }

            textRect.origin.y += yOffset
        }

        return textRect
    }

    /// We're handling link touches elsewhere, so we want to do nothing if we end up on a link
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let activeLink = link(at: touch.location(in: self)) else {
                super.touchesBegan(touches, with: event)
                return
        }

        self.activeLink = activeLink
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeLink != nil else {
            super.touchesCancelled(touches, with: event)
            return
        }

        activeLink = nil
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeLink = activeLink else {
            super.touchesEnded(touches, with: event)
            labelTappedBlock?()
            return
        }

        handleLinkTapped(activeLink)
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeLink = activeLink else {
            super.touchesMoved(touches, with: event)
            return
        }

        guard let touch = touches.first,
            let link = link(at: touch.location(in: self)) else {
                return
        }

        if activeLink != link {
            self.activeLink = nil
        }
    }

    // MARK: - Public

    /// Adds a single link
    open func addLink(_ link: NantesLabel.Link) {
        addLinks([link])
    }

    /// Adds a link to a `url` with a specified `range`
    @discardableResult
    open func addLink(to url: URL, withRange range: NSRange) -> NantesLabel.Link? {
        return addLinks(with: [.linkCheckingResult(range: range, url: url)], withAttributes: linkAttributes).first
    }

    // MARK: - Private

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

    private func boundingRect(for characterRange: NSRange) -> CGRect {
        guard let updatedAttributedText = attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return .zero
        }

        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: updatedAttributedText)

        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: bounds.size)
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange(location: 0, length: 0)
        layoutManager.characterRange(forGlyphRange: characterRange, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

    private func commonInit() {
        isUserInteractionEnabled = true
        enabledTextCheckingTypes = [.link, .address, .phoneNumber]
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

    private func checkText() {
        guard let attributedText = attributedText,
            !enabledTextCheckingTypes.isEmpty else {
                return
        }

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else {
                return
            }

            guard let dataDetector = self.dataDetector else {
                return
            }

            let results = dataDetector.matches(in: attributedText.string, options: .withTransparentBounds, range: NSRange(location: 0, length: attributedText.length))
            guard !results.isEmpty else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard self?.attributedText?.string == attributedText.string else {
                    // The string changed, these results aren't useful
                    return
                }

                self?.addLinks(with: results, withAttributes: self?.linkAttributes)
            }
        }
    }

    private func cleanUpLastNewlineCharIn(_ attributedString: NSAttributedString, at index: Int) -> NSMutableAttributedString? {
        guard index > 0 else {
            return nil
        }

        guard let character = attributedString.string.last, let scalar = Unicode.Scalar(String(character)) else {
            return nil
        }

        guard CharacterSet.newlines.contains(scalar) else {
            return nil
        }

        let cleanedUpString = attributedString.mutableCopy() as? NSMutableAttributedString
        cleanedUpString?.deleteCharacters(in: NSRange(location: index - 1, length: 1))
        return cleanedUpString
    }

    private func drawAttributedString(_ attributedString: NSAttributedString, inFramesetter framesetter: CTFramesetter, textRange: CFRange, inRect rect: CGRect, context: CGContext) {
        let path = CGMutablePath()
        path.addRect(rect)
        let frame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

        drawBackground(frame, inRect: rect, context: context)

        guard let lines = CTFrameGetLines(frame) as [AnyObject] as? [CTLine] else {
            return
        }

        let numberOfLines = self.numberOfLines > 0 ? min(self.numberOfLines, lines.count) : lines.count
        let truncateLastLine = lineBreakMode == .byTruncatingHead || lineBreakMode == .byTruncatingMiddle || lineBreakMode == .byTruncatingTail

        var lineOrigins: [CGPoint] = .init(repeating: .zero, count: numberOfLines)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), &lineOrigins)

        for lineIndex in 0..<lineOrigins.count {
            let lineOrigin = lineOrigins[lineIndex]
            context.textPosition = lineOrigin
            let line = lines[lineIndex]

            var descent: CGFloat = 0.0
            CTLineGetTypographicBounds(line, nil, &descent, nil)

            let lastLineRange = CTLineGetStringRange(line)

            // Checking to see if we're at the end of our text and that we should truncate since we have no more room to work with
            if lineIndex == numberOfLines - 1 &&
                truncateLastLine &&
                !(lastLineRange.length == 0 && lastLineRange.location == 0) &&
                lastLineRange.location + lastLineRange.length < textRange.location + textRange.length {
                let truncationDrawingContext = TruncationDrawingContext(attributedString: attributedString, context: context, descent: descent, lastLineRange: lastLineRange, lineOrigin: lineOrigin, numberOfLines: numberOfLines, rect: rect)
                drawTruncation(truncationDrawingContext)
            } else { // otherwise normal drawing here
                let penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(rect.size.width)))
                let yOffset = lineOrigin.y - descent - font.descender
                context.textPosition = CGPoint(x: penOffset, y: yOffset)
                CTLineDraw(line, context)
            }
        }

        drawStrike(frame: frame, inRect: rect, context: context)
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

    private func drawHighlightedString(_ highlightedAttributedString: NSAttributedString?, highlightedTextColor: UIColor, textRange: CFRange, inRect textRect: CGRect, context: CGContext) {
        guard let highlightAttributedString = highlightedAttributedString?.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        highlightAttributedString.addAttribute(.foregroundColor, value: highlightedTextColor, range: NSRange(location: 0, length: highlightAttributedString.length))

        let framesetter = highlightFramesetter ?? CTFramesetterCreateWithAttributedString(highlightAttributedString)
        highlightFramesetter = framesetter

        drawAttributedString(highlightAttributedString, inFramesetter: framesetter, textRange: textRange, inRect: textRect, context: context)
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

    private func drawTruncation(_ truncationDrawingContext: TruncationDrawingContext) {
        var lineBreakMode = self.lineBreakMode

        if truncationDrawingContext.numberOfLines != 1 {
            lineBreakMode = .byTruncatingTail
        }

        let truncation = truncationInfo(from: truncationDrawingContext.lastLineRange.location, length: truncationDrawingContext.lastLineRange.length, for: lineBreakMode)
        let truncationAttributePosition = truncation.position
        let truncationType = truncation.type

        if attributedTruncationToken == nil {
            let truncationTokenString = "\u{2026}" // … unicode
            let truncationTokenStringAttributes = truncationDrawingContext.attributedString.attributes(at: truncationAttributePosition, effectiveRange: nil)
            attributedTruncationToken = NSAttributedString(string: truncationTokenString, attributes: truncationTokenStringAttributes)
        }

        guard let attributedTruncationString = attributedTruncationToken else {
            return
        }

        let truncationToken = CTLineCreateWithAttributedString(attributedTruncationString)

        let lastLineRange = NSRange(location: truncationDrawingContext.lastLineRange.location, length: truncationDrawingContext.lastLineRange.length)
        var truncationString = NSMutableAttributedString(attributedString: truncationDrawingContext.attributedString.attributedSubstring(from: lastLineRange))

        truncationString = cleanUpLastNewlineCharIn(truncationString, at: truncationDrawingContext.lastLineRange.length) ?? truncationString

        truncationString.append(attributedTruncationString)
        let truncationLine = CTLineCreateWithAttributedString(truncationString)

        var truncatedLine: CTLine? = CTLineCreateTruncatedLine(truncationLine, Double(truncationDrawingContext.rect.size.width), truncationType, truncationToken)
        if truncatedLine == nil {
            // if the line is not as wide as the truncationToken, truncatedLine is nil
            truncatedLine = truncationToken
        }

        guard let line = truncatedLine else {
            return
        }

        let penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(truncationDrawingContext.rect.size.width)))
        let yDifference = truncationDrawingContext.lineOrigin.y - truncationDrawingContext.descent - font.descender
        truncationDrawingContext.context.textPosition = CGPoint(x: penOffset, y: yDifference)

        CTLineDraw(line, truncationDrawingContext.context)

        var linkRange = NSRange(location: 0, length: 0)
        guard attributedTruncationString.attribute(.link, at: 0, effectiveRange: &linkRange) != nil else {
            return
        }

        let tokenRange = (truncationString.string as NSString).range(of: attributedTruncationString.string)
        let tokenLinkRange = NSRange(location: (truncationDrawingContext.lastLineRange.location + truncationDrawingContext.lastLineRange.length) - tokenRange.length, length: tokenRange.length)

        guard let urlString = attributedTruncationString.attribute(.link, at: 0, effectiveRange: &linkRange) as? String,
            let url = URL(string: urlString) else {
            return
        }

        addLink(to: url, withRange: tokenLinkRange)
    }

    private func handleLinkTapped(_ link: NantesLabel.Link) {
        guard link.linkTappedBlock == nil else {
            link.linkTappedBlock?(self, link)
            self.activeLink = nil
            return
        }

        guard let result = link.result else {
            return
        }

        self.activeLink = nil

        guard let delegate = delegate else {
            return
        }

        switch result.resultType {
        case .address:
            if let address = result.addressComponents {
                delegate.attributedLabel(self, didSelectAddress: address)
            }
        case .date:
            if let date = result.date {
                delegate.attributedLabel(self, didSelectDate: date, timeZone: result.timeZone ?? TimeZone.current, duration: result.duration)
            }
        case .link:
            if let url = result.url {
                delegate.attributedLabel(self, didSelectLink: url)
            }
        case .phoneNumber:
            if let phoneNumber = result.phoneNumber {
                delegate.attributedLabel(self, didSelectPhoneNumber: phoneNumber)
            }
        case .transitInformation:
            if let transitInfo = result.components {
                delegate.attributedLabel(self, didSelectTransitInfo: transitInfo)
            }
        default: // fallback to result if we aren't sure
            delegate.attributedLabel(self, didSelectTextCheckingResult: result)
        }
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
    private func link(at point: CGPoint) -> NantesLabel.Link? {
        guard !linkModels.isEmpty && bounds.inset(by: UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)).contains(point) else {
            return nil
        }

        // TTTAttributedLabel also does some extra bounds checking around where the point happened
        // if we can't find the link at the point depending on extendsLinkTouchArea being true
        // it adds a lot of extra checks and we're not using it right now, so I'm skipping it
        return link(at: characterIndex(at: point))
    }

    private func setNeedsFramesetter() {
        _renderedAttributedText = nil
        needsFramesetter = true
    }

    /// if the text width is greater than our available width we'll scale the font down
    /// Returns the scaled down NSAttributedString otherwise nil if we didn't scale anything
    private func scaleAttributedTextIfNeeded(_ attributedText: NSAttributedString) -> NSAttributedString? {
        // Reset so we start from the original font size
        setNeedsFramesetter()
        setNeedsDisplay()

        invalidateIntrinsicContentSize()

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

    // MARK: - Accessibility

    private func configureAccessibilityElements() {
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

extension NantesLabel {
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
}
