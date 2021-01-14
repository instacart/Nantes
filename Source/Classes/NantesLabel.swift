//
//  NantesLabel.swift
//  Carrot
//
//  Created by Chris Hansen on 12/10/18.
//  Copyright © 2018 Instacart. All rights reserved.
//

import UIKit

@IBDesignable open class NantesLabel: UILabel {
    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }

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
    @IBInspectable open var firstLineIndent: CGFloat = 0.0

    /// The shadow color for the label when the label's `highlighted` property is true. Defaults to nil
    @IBInspectable open var highlightedShadowColor: UIColor?

    /// The shadow offset for the label when the label's `highlighted` propert is true. A value of 0 indicates no blur, larger numbers indicate more blur. This can't be a negative value.
    @IBInspectable open var highlightedShadowOffset: CGSize = .zero

    /// The shadow blur radius for the label. A value of 0 indicates no blur. Larger values indicate more blur. This can't be a negative value.
    @IBInspectable open var highlightedShadowRadius: CGFloat = 0.0

    /// NSAttributedString attributes used to style inactive links
    /// nil or [:] will add no styling
    open var inactiveLinkAttributes: [NSAttributedString.Key: Any]?

    /// Floating point number in points; amount to modify default kerning. 0 means kerning is disabled. 0 is the default.
    @IBInspectable open var kern: CGFloat = 0

    /// Block to run whenever the label is tapped. Triggered on touchesEnded.
    /// Warning: Will disable calls to `delegate` on taps if this property is set
    open var labelTappedBlock: (() -> Void)?

    /// The line height multiple. 1.0 by default
    @IBInspectable open var lineHeightMultiple: CGFloat = 1.0

    /// The space in points added between lines within the paragraph
    @IBInspectable open var lineSpacing: CGFloat = 0.0

    /// NSAttributedString attributes used to style links that are detected or manually added
    /// You must specify linkAttributes before setting autodetecting or manually adding links for these
    /// attributes to be applied
    open var linkAttributes: [NSAttributedString.Key: Any]?

    /// The edge inset for the background of a link. The default value is `{0, -1, 0, -1}`.
    open var linkBackgroundEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: -1, bottom: 0, right: -1)

    /// The maximum line height within the paragraph. If the value is 0.0, the maximum line height is set to the line height of the `font`. 0.0 by default
    @IBInspectable open var maximumLineHeight: CGFloat = 0.0

    /// The minimum line height within the paragraph. If the value is 0.0, the minimum line height is set to the line height of the `font`. 0.0 by default
    @IBInspectable open var minimumLineHeight: CGFloat = 0.0

    /// The shadow blur radius for the label. 0 indicates no blur, larger values indicate more blur. This can't be a negative value
    @IBInspectable open var shadowRadius: CGFloat = 0.0

    /// Vertical alignment of the text within its frame
    /// defaults to .center
    open var verticalAlignment: NantesLabel.VerticalAlignment = .center

    // MARK: - Private vars

    static private var dataDetectorsByType: [UInt64: NSDataDetector] = [:]

    private var accessibilityLock: NSLock = .init()

    private var _framesetter: CTFramesetter?

    private var framesetterLock: NSLock = .init()

    private var needsFramesetter: Bool = false

    private var _renderedAttributedText: NSAttributedString?

    // MARK: - Internal lets
    
    let nantesQueue = DispatchQueue(label: "com.Nantes.NantesQueue",
                                            qos: .userInitiated,
                                            attributes: .concurrent)
    
    // MARK: - Internal vars

    var _accessibilityElements: [Any]?

    var _attributedText: NSAttributedString?

    var activeLink: NantesLabel.Link? {
        didSet {
            didSetActiveLink(activeLink: activeLink, oldValue: oldValue)
        }
    }

    var dataDetector: NSDataDetector?

    var framesetter: CTFramesetter? {
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

    var highlightFramesetter: CTFramesetter?

    var inactiveAttributedText: NSAttributedString?

    var linkModels: [NantesLabel.Link] = []

    var renderedAttributedText: NSAttributedString? {
        if _renderedAttributedText == nil, let attributedText = attributedText {
            _renderedAttributedText = NSAttributedString.attributedStringBySettingColor(attributedString: attributedText, color: textColor)
        }
        return _renderedAttributedText
    }

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

    @IBInspectable override open var numberOfLines: Int {
        didSet {
            accessibilityElements = nil
        }
    }

    /// It's important to set `attributedText` or `text` before adding links
    /// Since we reset linkModels to make sure our links are up to date when the text changes
    @IBInspectable override open var text: String? {
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

    // MARK: - Framesetter

    func setNeedsFramesetter() {
        _renderedAttributedText = nil
        needsFramesetter = true
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

    private func commonInit() {
        isUserInteractionEnabled = true
        enabledTextCheckingTypes = [.link, .address, .phoneNumber]
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    override open func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        guard let attributedText = attributedText,
            let framesetter = framesetter else {
                return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        }

        var textRect = bounds
        var maxLineHeight: CGFloat = -1.0
        attributedText.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedText.length), options: [], using: { value, _, _ in
            guard let font = value as? UIFont else {
                return
            }

            maxLineHeight = max(maxLineHeight, font.lineHeight)
        })
        maxLineHeight = maxLineHeight == -1.0 ? font.lineHeight : maxLineHeight
        textRect.size.height = max(maxLineHeight * CGFloat(max(2, numberOfLines)), bounds.height)

        var textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: attributedText.length), nil, textRect.size, nil)
        textSize = CGSize(width: ceil(textSize.width), height: ceil(textSize.height))

        if textSize.height < bounds.height {
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

    // MARK: - Public

    /// Use this setter when you want to set attributes on NantesLabel before setting attributedText and have the properties get copied over
    /// This will overwrite properties set on the attributedString passed in, if they're set on NantesLabel. Use `attributedText` if you want
    /// to keep the properties inside attributedString
    ///
    /// More info:
    /// Check out the `testAttributedStringPropertiesUpdate` test and `testAttributedStringPropertiesUpdateWithBlock` and compare them against
    /// `testAttributedStringPropertiesStay` for expected behavior against the functions
    public func setAttributedText(_ attributedString: NSAttributedString, afterInheritingLabelAttributesAndConfiguringWithBlock block: ((NSMutableAttributedString) -> NSMutableAttributedString)?) {
        var mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttributedString.addAttributes(NSAttributedString.attributes(from: self), range: NSRange(location: 0, length: attributedString.length))

        if let block = block {
            mutableAttributedString = block(mutableAttributedString)
        }

        attributedText = mutableAttributedString
    }
}
