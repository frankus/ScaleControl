//
//  ScaleControl.swift
//  IntegerSelector
//
//  Created by Frank Schmitt on 2023-01-03.
//

import UIKit

@IBDesignable
public class ScaleControl: UIControl {
	public static var noValue = -999

	@IBInspectable public var minimumValue: Int {
		get {
			return self.range.lowerBound
		}
		set {
			self.range = min(newValue, self.range.upperBound)...self.range.upperBound
		}
	}

	@IBInspectable public var maximumValue: Int {
		get {
			return self.range.upperBound
		}
		set {
			self.range = self.range.lowerBound...max(newValue, self.range.lowerBound)
		}
	}

	@IBInspectable public var selectedValue: Int {
		get {
			return self.value ?? Self.noValue
		}
		set {
			if newValue == Self.noValue {
				self.value = nil
			} else {
				self.value = self.range.clamp(newValue)
			}
		}
	}

	@IBInspectable public var minimumDescription: String? {
		didSet {
			self.minimumLabel.text = self.minimumDescription
		}
	}

	@IBInspectable public var maximumDescription: String? {
		didSet {
			self.maximumLabel.text = self.maximumDescription
		}
	}

	@objc dynamic public var scaleColor: UIColor = .secondarySystemBackground

	@objc dynamic public var selectionColor: UIColor = .tintColor

	@objc dynamic public var numberColor: UIColor = .label

	@objc dynamic public var selectedNumberColor: UIColor = .systemBackground

	@objc dynamic public var selectorInset: CGFloat = 2

	@objc dynamic public var numberFont: UIFont = .preferredFont(forTextStyle: .body)

	@objc dynamic public var descriptionFont: UIFont = .preferredFont(forTextStyle: .footnote)

	@objc dynamic public var descriptionColor: UIColor = .secondaryLabel

	public init(range: ClosedRange<Int>) {
		self.range = range

		super.init(frame: .zero)

		self.configureViews()
	}

	convenience public init(minimumValue: Int, maximumValue: Int) {
		self.init(range: minimumValue...maximumValue)
	}

	public override init(frame: CGRect) {
		self.range = 1...10

		super.init(frame: .zero)

		self.configureViews()
	}

	override public func layoutSubviews() {
		super.layoutSubviews()

		let buttonWidth = self.bounds.width / CGFloat(range.count)

		self.layoutNumberLabels()

		self.scaleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.scaleHeight)
		self.scaleView.layer.cornerRadius = min(buttonWidth, self.scaleHeight) / 2

		self.updateSelection()

		self.selectionView.layer.cornerRadius = min(self.selectionView.bounds.height, self.selectionView.bounds.width) / 2

		self.minimumLabel.frame = CGRectMake(6, self.scaleView.frame.maxY + 6, self.bounds.width - 12, self.bounds.height - (self.scaleView.frame.maxY + 6))
		self.maximumLabel.frame = CGRectMake(6, self.scaleView.frame.maxY + 6, self.bounds.width - 12, self.bounds.height - (self.scaleView.frame.maxY + 6))
	}

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		self.updateScaledValues()

		self.setNeedsLayout()
		self.invalidateIntrinsicContentSize()
	}

	public func setSelectedValue(_ selectedValue: Int, animated: Bool) {
		let updateBlock = {
			self.selectedValue = selectedValue
		}

		if animated {
			UIView.animate(withDuration: Self.animationDuration, animations: updateBlock)
		} else {
			updateBlock()
		}
	}

	public override var bounds: CGRect {
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}
	
	public override func sizeThatFits(_ size: CGSize) -> CGSize {
		return CGSize(width: size.width, height: self.scaleHeight + self.descriptionHeight + 6)
	}

	public override var intrinsicContentSize: CGSize {
		return self.sizeThatFits(self.bounds.size)
	}

	// MARK: - NSCoding

	private static let minimumValueKey = "MinimumValue"
	private static let maximumValueKey = "MaximumValue"
	private static let selectedValueKey = "SelectedValue"

	required init?(coder: NSCoder) {
		self.range = coder.decodeInteger(forKey: Self.minimumValueKey)...coder.decodeInteger(forKey: Self.maximumValueKey)
		self.value = self.range.clamp(coder.decodeInteger(forKey: Self.selectedValueKey))

		super.init(coder: coder)

		self.configureViews()
	}

	// MARK: - Private

	private static let numberFormatter = NumberFormatter()
	private static let animationDuration: TimeInterval = 0.33

	private var numberLabels = [UILabel]()
	private let selectionView = UIView()
	private let scaleView = UIView()
	private let minimumLabel = UILabel()
	private let maximumLabel = UILabel()

	private let tapGestureRecognizer = UITapGestureRecognizer()
	private let panGestureRecognizer = UIPanGestureRecognizer()

	private let numberFontMetrics = UIFontMetrics(forTextStyle: .body)
	private let descriptionFontMetrics = UIFontMetrics(forTextStyle: .footnote)

	private var value: Int? {
		didSet {
			self.updateSelection()
			self.setNeedsLayout()
		}
	}

	private var range: ClosedRange<Int> {
		didSet {
			self.configureNumberLabels()
			self.setNeedsLayout()
		}
	}

	private var scaleHeight: CGFloat = 32
	private var descriptionHeight: CGFloat = 32

	private func updateScaledValues() {
		self.scaleHeight = max(32, self.numberFontMetrics.scaledValue(for: 32, compatibleWith: self.traitCollection))
		self.descriptionHeight = max(32, self.descriptionFontMetrics.scaledValue(for: 32, compatibleWith: self.traitCollection))
	}

	private func configureViews() {
		self.updateScaledValues()

		self.scaleView.backgroundColor = self.scaleColor
		self.addSubview(self.scaleView)

		self.tapGestureRecognizer.addTarget(self, action: #selector(tap(_:)))
		self.addGestureRecognizer(self.tapGestureRecognizer)

		self.panGestureRecognizer.addTarget(self, action: #selector(pan(_:)))
		self.addGestureRecognizer(self.panGestureRecognizer)

		self.selectionView.backgroundColor = self.selectionColor
		self.scaleView.addSubview(self.selectionView)

		self.configureNumberLabels()

		self.minimumLabel.font = self.descriptionFont
		self.minimumLabel.textColor = self.descriptionColor
		self.minimumLabel.adjustsFontForContentSizeCategory = true
		self.minimumLabel.textAlignment = .left
		self.addSubview(self.minimumLabel)

		self.maximumLabel.font = self.descriptionFont
		self.maximumLabel.textColor = self.descriptionColor
		self.maximumLabel.adjustsFontForContentSizeCategory = true
		self.maximumLabel.textAlignment = .right
		self.addSubview(self.maximumLabel)

		self.updateSelection()
	}

	private func configureNumberLabels() {
		for numberLabel in self.numberLabels {
			numberLabel.removeFromSuperview()
		}

		self.numberLabels.removeAll()

		for index in self.range {
			let label = UILabel(frame: .zero)
			label.text = Self.numberFormatter.string(from: index as NSNumber)
			label.textAlignment = .center
			label.tag = index
			label.isUserInteractionEnabled = true
			label.adjustsFontForContentSizeCategory = true
			label.font = self.numberFont

			self.numberLabels.append(label)
			self.scaleView.insertSubview(label, aboveSubview: self.selectionView)
		}

		self.layoutNumberLabels()
	}

	private func layoutNumberLabels() {
		let idealWidth = self.bounds.width / CGFloat(self.range.count)
		let displayWidth = self.displayScaleRound(idealWidth)
		var x: CGFloat = 0

		for numberLabel in self.numberLabels {
			numberLabel.frame = CGRect(x: self.displayScaleRound(x), y: 0, width: displayWidth, height: self.scaleHeight)

			x += idealWidth
		}
	}

	private func updateSelection() {
		if let value = self.value {
			self.selectionView.isHidden = false

			let selectedLabel = self.numberLabels[value - self.range.lowerBound]

			for label in self.numberLabels {
				label.textColor = label == selectedLabel ? self.selectedNumberColor : self.numberColor
			}

			self.selectionView.frame = selectedLabel.frame.insetBy(dx: self.selectorInset, dy: self.selectorInset)
		} else {
			self.selectionView.isHidden = true
		}
	}

	@objc private func tap(_ sender: UITapGestureRecognizer) {
		// TODO: Use hit testing
		if sender.location(in: self).y > self.minimumLabel.frame.minY {
			// Tapping on description labels increments/decrements the value,
			// or sets it to the extreme if not yet set.
			if sender.location(in: self).x < self.bounds.width / 2 {
				self.value = self.range.lowerBound
			} else {
				self.value = self.range.upperBound
			}
		} else {
			// Tapping on the scale immediately sets to the nearest value.
			let index = Int(sender.location(in: self.scaleView).x * CGFloat(self.range.count) / self.scaleView.bounds.width)
			let correspondingValue = self.range.clamp(index + range.lowerBound)

			if self.value != correspondingValue {
				self.value = correspondingValue
				self.sendActions(for: .valueChanged)
			}
		}
	}

	@objc private func pan(_ sender: UIPanGestureRecognizer) {
		let index = Int(sender.location(in: self.scaleView).x * CGFloat(self.range.count) / self.scaleView.bounds.width)
		let correspondingValue = self.range.clamp(index + range.lowerBound)

		if let value = self.value, abs(value - correspondingValue) > 1 || self.value == nil {
			// Don't recognize a pan if not starting close to current value.
			sender.reset()
		} else {
			self.value = correspondingValue

			if sender.state == .ended {
				self.sendActions(for: .valueChanged)
			}
		}
	}
}

extension UIView {
	func displayScaleRound(_ value: CGFloat) -> CGFloat {
		return round(value * self.traitCollection.displayScale) / self.traitCollection.displayScale
	}
}

private extension ClosedRange {
	func clamp(_ value: Bound) -> Bound {
		return Swift.min(Swift.max(lowerBound, value), upperBound)
	}
}
