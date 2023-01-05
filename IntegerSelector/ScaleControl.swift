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

	public enum DisplayMode {
		case horizontal
		case circular
		case vertical
	}

	public var displayMode: DisplayMode = .horizontal {
		didSet {
			self.invalidateIntrinsicContentSize()
			self.setNeedsLayout()
		}
	}

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
		self.updateScaleView()

		switch self.displayMode {
		case .circular:
			self.scaleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width)

		case .horizontal:
			self.scaleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.scaleThickness)
			self.scaleView.layer.cornerRadius = min(buttonWidth, self.scaleThickness) / 2

		case .vertical:
			self.scaleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.scaleThickness * CGFloat(self.range.count))
		}

		self.updateSelection()

		self.selectionView.layer.cornerRadius = min(self.selectionView.bounds.height, self.selectionView.bounds.width) / 2

		self.minimumLabel.frame = CGRectMake(6, self.scaleView.frame.maxY + 6, self.bounds.width - 12, self.bounds.height - (self.scaleView.frame.maxY + 6))
		self.maximumLabel.frame = CGRectMake(6, self.scaleView.frame.maxY + 6, self.bounds.width - 12, self.bounds.height - (self.scaleView.frame.maxY + 6))
	}

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if previousTraitCollection?.preferredContentSizeCategory != self.traitCollection.preferredContentSizeCategory {
			self.updateScaledValues()
			self.invalidateIntrinsicContentSize()
		}
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

	public  func mySizeThatFits(_ size: CGSize) -> CGSize {
		switch self.displayMode {
		case .circular:
			return CGSize(width: UIView.noIntrinsicMetric, height: size.width + self.descriptionHeight + 6)

		case .horizontal:
			return CGSize(width: UIView.noIntrinsicMetric, height: self.scaleThickness + self.descriptionHeight + 6)

		case .vertical:
			return CGSize(width: UIView.noIntrinsicMetric, height: self.scaleThickness * CGFloat(self.range.count))
		}
	}

	public override var intrinsicContentSize: CGSize {
		self.evaluateDisplayMode(forWidth: self.bounds.width)
		return self.mySizeThatFits(self.bounds.size)
	}

	public override var bounds: CGRect {
		willSet {
			self.evaluateDisplayMode(forWidth: newValue.width)
		}
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}

	// MARK: - NSCoding

	required init?(coder: NSCoder) {
		self.range = -998...999

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

	private var scaleThickness: CGFloat = 32
	private var descriptionHeight: CGFloat = 32

	private func updateScaledValues() {
		self.scaleThickness = max(32, self.numberFontMetrics.scaledValue(for: 32, compatibleWith: self.traitCollection))
		self.descriptionHeight = max(32, self.descriptionFontMetrics.scaledValue(for: 32, compatibleWith: self.traitCollection))
	}

	private func evaluateDisplayMode(forWidth width: CGFloat) {
		let lengthOfScale = self.scaleThickness * CGFloat(self.range.count)
		let usableCircumference = (width - self.scaleThickness) * CGFloat.pi * 0.75

		// Update display mode based on scale length and round-or-wider buttons.
		if width >= lengthOfScale {
			self.displayMode = .horizontal
		} else if usableCircumference >= lengthOfScale {
			self.displayMode = .circular
		} else {
			self.displayMode = .vertical
		}
	}

	private var shapeLayer: ScaleLayer = ScaleLayer()

	private func updateScaleView() {
		var path: UIBezierPath

		switch self.displayMode {
			case .circular:
				let startAngle: CGFloat = 0.75 * .pi
				let endAngle: CGFloat = 0.25 * .pi;

				let halfWidth = self.bounds.width / 2
				let center = CGPointMake(halfWidth, halfWidth)
				let radius: CGFloat = halfWidth - (self.scaleThickness / 2)
				path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

			case .horizontal:
				let start = CGPoint(x: self.scaleThickness / 2, y: self.scaleThickness / 2)
				let end = CGPoint(x: self.bounds.width - self.scaleThickness / 2, y: self.scaleThickness / 2)
				path = UIBezierPath()
				path.move(to: start)
				path.addLine(to: end)

			case .vertical:
				let start = CGPoint(x: self.scaleThickness / 2, y: self.scaleThickness / 2)
				let end = CGPoint(x: self.scaleThickness / 2, y: self.bounds.height - self.scaleThickness / 2)
				path = UIBezierPath()
				path.move(to: start)
				path.addLine(to: end)
			}

		self.shapeLayer.frame = self.bounds
		self.shapeLayer.path = path.cgPath
	}

	private func configureScaleView() {
		self.shapeLayer.fillColor = UIColor.clear.cgColor
		self.shapeLayer.strokeColor = self.scaleColor.cgColor
		self.shapeLayer.lineWidth = self.scaleThickness
		self.shapeLayer.lineCap = .round

		self.scaleView.layer.addSublayer(self.shapeLayer)
	}

	private func configureViews() {
		self.updateScaledValues()

		self.configureScaleView()
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
		switch displayMode {
		case .horizontal:
			let idealWidth = self.bounds.width / CGFloat(self.range.count)
			let displayWidth = self.displayScaleRound(idealWidth)
			var x: CGFloat = 0

			for numberLabel in self.numberLabels {
				numberLabel.frame = CGRect(x: self.displayScaleRound(x), y: 0, width: displayWidth, height: self.scaleThickness)

				x += idealWidth
			}

		case .circular:
			let maxAngle: CGFloat = 0.75 * 2 * .pi // Use 3/4 of a circle.
			let angleIncrement = maxAngle / CGFloat(self.range.count - 1)
			let scaleRadius = (self.bounds.width - self.scaleThickness) / 2
			var angle: CGFloat = 0.75 * .pi // Start at 7:30, end at 4:30.

			for numberLabel in self.numberLabels {
				let centerX = self.scaleView.bounds.midX + cos(angle) * scaleRadius
				let centerY = self.scaleView.bounds.midY + sin(angle) * scaleRadius
				let origin = CGPoint(x: centerX - scaleThickness / 2, y: centerY - scaleThickness / 2)
				numberLabel.center = CGPoint(x: centerX, y: centerY)
				numberLabel.bounds = CGRect(origin: .zero, size: CGSize(width: self.scaleThickness, height: self.scaleThickness))

				angle += angleIncrement
			}

			break

		case .vertical:
			var y: CGFloat = 0

			for numberLabel in self.numberLabels {
				numberLabel.frame = CGRect(x: 0, y: y, width: self.scaleThickness, height: self.scaleThickness)

				y += self.scaleThickness
			}
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

private class ScaleLayer: CAShapeLayer {
	override func action(forKey event: String) -> CAAction? {
		if event == "path" {
			let animation = CABasicAnimation(keyPath: event)
			animation.duration = CATransaction.animationDuration()
			animation.timingFunction = CATransaction.animationTimingFunction()

			return animation
		} else {
			return super.action(forKey: event)
		}
	}
}
