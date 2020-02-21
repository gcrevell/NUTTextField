//
//  NUTTextField.swift
//  Nutshell
//
//  Created by Gabriel Revells on 12/18/19.
//  Copyright © 2019 Gabriel Revells. All rights reserved.
//

import UIKit

/// A text field that includes a custom placeholder that animates into a label
///
/// This textfield shows a placeholder when it has no content. When editing starts, the placeholder aniimates
/// to above the textfield to be a label.
///
/// - Note: This works best with a height of 40 pixels, but will not enforce that in any way
///
/// - Warning: The placeholder text color will appear differenlty on a storyboard
@IBDesignable
class NUTTextField: UITextField {

    /// The animated placeholder label
    private var floatingPlaceholderLabel: UILabel = UILabel()

    /// Textfield font
    ///
    /// Setting this will also set the placeholder font
    open override var font: UIFont? {
        didSet {
            floatingPlaceholderLabel.font = font
        }
    }

    /// Minimum font size for the placeholder when floading
    ///
    /// Changing this means you should change the overall height by the same amount
    @IBInspectable
    open var floatingPlaceholderMinFontSize: CGFloat = 10

    /// Placeholder animation duration
    open var floatingPlaceholderDuration: Double = 0.2

    /// Placeholder color
    ///
    /// Default is the default system placeholder color
    @IBInspectable
    open var floatingPlaceholderColor: UIColor = .systemGray {
        didSet {
            floatingPlaceholderLabel.textColor = floatingPlaceholderColor
        }
    }

    /// The color of the underline view
    @IBInspectable
    private var underlineColor: UIColor = .systemGray

    /// Padding to the left of text
    private var leftPadding: CGFloat = 4

    /// Margin under placeholder when on top
    private var floatingPlaceholderBottomMargin: CGFloat = 8

    /// Placeholder Bottom Constraint
    private var floatingPlaceholderBottomConstraint: NSLayoutConstraint!

    /// Placeholder Leading Constraint
    private var floatingPlaceholderLeadingConstraint: NSLayoutConstraint!

    /// Under line width constraint
    private var underLineViewWidth: NSLayoutConstraint?

    /// Under line View
    private var underlineView: UIView?

    /// Old under line color
    private var oldUnderlineView: UIView?

    /// Whether placeholder is above
    private var isPlaceholderFloating = false

    /// Whether placehlder should be avove
    private var shouldPlaceholderBeFloating = false

    private var placeholderResizeRatio: CGFloat {
        return isPlaceholderFloating ? floatingPlaceholderMinFontSize / font!.pointSize : font!.pointSize / floatingPlaceholderMinFontSize
    }

    /// The natural size for the receiving view, considering only properties of the view itself
    override open var intrinsicContentSize: CGSize {
        let intrinsicContentSize = super.intrinsicContentSize
        return CGSize(width: intrinsicContentSize.width,
                      height: intrinsicContentSize.height + floatingPlaceholderBottomMargin + floatingPlaceholderLabel.bounds.height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()

        // When editing is started in case character input is not made
        if isFirstResponder && text == "" && !isPlaceholderFloating {
            placeholder(toFloat: true)
        }
        // When editing is ended when character input is not made
        else if !isFirstResponder && text == "" && isPlaceholderFloating {
            placeholder(toFloat: false)
        }

        // When an initial value is given to textfield
        if text != "" && !isPlaceholderFloating {
            isPlaceholderFloating = true
            DispatchQueue.main.async {
                self.placeholder(toFloat: true)
                self.animateUnderlineColor()
            }

        }

        animateUnderlineColor()
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return CGRect(x: rect.origin.x, y: rect.origin.y + floatingPlaceholderBottomMargin, width: rect.size.width, height: rect.size.height).integral
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return CGRect(x: rect.origin.x, y: rect.origin.y + floatingPlaceholderBottomMargin, width: rect.size.width, height: rect.size.height).integral
    }

    // MARK: - Setup

    // The following methods are setup methods, and really should only be called
    // during initalization of the view

    /// Initial setup
    private func setup() {
        borderStyle = .none
        setupLeftView()
        setupFloatingPlaceholder()
        setupUnderlineView()
    }

    /// Set up left margin
    private func setupLeftView() {
        leftView = UIView()
        leftView?.frame.size.width = leftPadding
        leftViewMode = .always
    }

    /// Set up placeholder label
    private func setupFloatingPlaceholder() {
        floatingPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingPlaceholderLabel.text = placeholder
        floatingPlaceholderLabel.textColor = floatingPlaceholderColor
        floatingPlaceholderLabel.font = font
        placeholder = nil
        addSubview(floatingPlaceholderLabel)
        floatingPlaceholderLeadingConstraint = floatingPlaceholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftPadding)
        floatingPlaceholderLeadingConstraint.isActive = true
        floatingPlaceholderBottomConstraint = floatingPlaceholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -floatingPlaceholderBottomMargin)
        floatingPlaceholderBottomConstraint.isActive = true
    }

    /// Set up under view
    private func setupUnderlineView() {
        oldUnderlineView = UIView()
        oldUnderlineView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(oldUnderlineView!)
        oldUnderlineView?.heightAnchor.constraint(equalToConstant: 2).isActive = true
        oldUnderlineView?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        oldUnderlineView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        oldUnderlineView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        oldUnderlineView?.backgroundColor = underlineColor

        underlineView = UIView()
        underlineView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underlineView!)
        underlineView?.heightAnchor.constraint(equalToConstant: 2).isActive = true
        underLineViewWidth = underlineView?.widthAnchor.constraint(equalToConstant: 0)
        underLineViewWidth?.isActive = true
        underlineView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        underlineView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        underlineView?.backgroundColor = underlineColor
    }

    /// Move placeholder label
    private func placeholder(toFloat: Bool) {
        isPlaceholderFloating = toFloat
        floatingPlaceholderBottomConstraint.constant = toFloat ? -bounds.height + floatingPlaceholderLabel.frame.height : -floatingPlaceholderBottomMargin

        let leading = -floatingPlaceholderLabel.frame.width * (1 - self.placeholderResizeRatio) / 2 + leftPadding
        floatingPlaceholderLeadingConstraint.constant = toFloat ? leading : leftPadding
        shouldPlaceholderBeFloating = true
    }

    /// Set the color of the underline view
    ///
    /// Animating the color change will cause the color to "spread" from the center of the line out to the
    /// edges. The animation duration is the same duration used for animating the placeholder movement.
    /// To not show an underline at all, use a clear color here.
    open func setUnderline(color: UIColor, animated: Bool = true) {
        self.underlineColor = color

        if animated {
            animateUnderlineColor()
        } else {
            oldUnderlineView?.backgroundColor = underlineColor
            underlineView?.backgroundColor = underlineColor
        }
    }

    /// Set bottom line with animation
    private func animateUnderlineColor() {
        underlineView?.backgroundColor = underlineColor
        underLineViewWidth?.constant = bounds.width

        UIView.animate(withDuration: floatingPlaceholderDuration, delay: 0, options: .curveLinear, animations: {
            self.layoutIfNeeded()
            if self.shouldPlaceholderBeFloating {
                self.floatingPlaceholderLabel.transform = self.floatingPlaceholderLabel.transform.scaledBy(x: self.placeholderResizeRatio, y: self.placeholderResizeRatio)
                self.shouldPlaceholderBeFloating = false
            }
        }, completion: { _ in
            self.underLineViewWidth?.constant = 0
            self.oldUnderlineView?.backgroundColor = self.underlineColor
        })
    }

    override func prepareForInterfaceBuilder() {
        setup()
    }
}
