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
			self.evaluateDisplayMode()
		}
	}

	@IBInspectable public var maximumValue: Int {
		get {
			return self.range.upperBound
		}
		set {
			self.range = self.range.lowerBound...max(newValue, self.range.lowerBound)
			self.evaluateDisplayMode()
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
			if self.displayMode != oldValue {
				self.invalidateIntrinsicContentSize()
			}
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

		self.selectionView.layer.cornerRadius = min(self.selectionView.bounds.height, self.selectionView.bounds.width) / 2
	}

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		self.evaluateDisplayMode()
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

	private func evaluateDisplayMode() {
		self.updateScaledValues()

		let isPortraitPhone = traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular
		let nominalWidth: CGFloat = isPortraitPhone ? 300 : 600

		let lengthOfScale = self.scaleThickness * CGFloat(self.range.count)
		let usableCircumference = (nominalWidth - self.scaleThickness) * CGFloat.pi * 0.75

		// Update display mode based on scale length and round-or-wider buttons.
		if nominalWidth >= lengthOfScale {
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

	private var scaleViewAspectConstraint = NSLayoutConstraint()
	private var scaleViewHeightConstraint = NSLayoutConstraint()

	private var selectionViewSizeConstraints = [NSLayoutConstraint]()
	private var selectionViewPositionConstraints = [NSLayoutConstraint()]

	private var numberLabelWidthConstraints = [NSLayoutConstraint]()
	private var numberLabelHeightConstraints = [NSLayoutConstraint]()
	private var horizontalConstraints = [NSLayoutConstraint]()
	private var circularConstraints = [NSLayoutConstraint]()
	private var verticalConstraints = [NSLayoutConstraint]()

	private func configureViews() {
		self.evaluateDisplayMode()

		self.configureScaleView()
		self.scaleView.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(self.scaleView)

		self.tapGestureRecognizer.addTarget(self, action: #selector(tap(_:)))
		self.addGestureRecognizer(self.tapGestureRecognizer)

		self.panGestureRecognizer.addTarget(self, action: #selector(pan(_:)))
		self.addGestureRecognizer(self.panGestureRecognizer)

		self.selectionView.backgroundColor = self.selectionColor
		self.selectionView.translatesAutoresizingMaskIntoConstraints = false
		self.scaleView.addSubview(self.selectionView)

		self.configureNumberLabels()

		self.minimumLabel.font = self.descriptionFont
		self.minimumLabel.textColor = self.descriptionColor
		self.minimumLabel.adjustsFontForContentSizeCategory = true
		self.minimumLabel.textAlignment = .left
		self.minimumLabel.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(self.minimumLabel)

		self.maximumLabel.font = self.descriptionFont
		self.maximumLabel.textColor = self.descriptionColor
		self.maximumLabel.adjustsFontForContentSizeCategory = true
		self.maximumLabel.textAlignment = .right
		self.maximumLabel.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(self.maximumLabel)

		self.scaleViewAspectConstraint = self.scaleView.heightAnchor.constraint(equalTo: self.scaleView.widthAnchor, multiplier: 1/*(1 + cos(.pi / 4)) / 2 */, constant: self.scaleThickness / 2)
		self.scaleViewHeightConstraint = self.scaleView.heightAnchor.constraint(equalToConstant: self.scaleThickness)

		NSLayoutConstraint.activate([
			self.scaleView.topAnchor.constraint(equalTo: self.topAnchor),
			self.scaleView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			self.trailingAnchor.constraint(equalTo: self.scaleView.trailingAnchor),

			self.minimumLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.scaleView.bottomAnchor, multiplier: 1),
			self.maximumLabel.topAnchor.constraint(equalTo: self.minimumLabel.topAnchor),

			self.minimumLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1),
			self.maximumLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.minimumLabel.trailingAnchor, multiplier: 1),
			self.trailingAnchor.constraint(equalToSystemSpacingAfter: self.maximumLabel.trailingAnchor, multiplier: 1),

			self.bottomAnchor.constraint(equalTo: self.minimumLabel.bottomAnchor),
			self.maximumLabel.bottomAnchor.constraint(equalTo: self.minimumLabel.bottomAnchor),
		])

		self.selectionViewSizeConstraints = [
			self.selectionView.widthAnchor.constraint(equalToConstant: self.scaleThickness),
			self.selectionView.heightAnchor.constraint(equalToConstant: self.scaleThickness)
		]

		NSLayoutConstraint.activate(self.selectionViewSizeConstraints)

		self.updateSelection()
	}

	public override func updateConstraints() {
		super.updateConstraints()

		self.evaluateDisplayMode()

		switch self.displayMode {
		case .circular:
			self.scaleViewHeightConstraint.isActive = false
			self.scaleViewAspectConstraint.isActive = true

			self.scaleViewAspectConstraint.constant = self.scaleThickness / 2

		case .horizontal:
			self.scaleViewHeightConstraint.isActive = true
			self.scaleViewAspectConstraint.isActive = false

			self.scaleViewHeightConstraint.constant = self.scaleThickness

		case .vertical:
			self.scaleViewHeightConstraint.isActive = true
			self.scaleViewAspectConstraint.isActive = false

			self.scaleViewHeightConstraint.constant = self.scaleThickness * CGFloat(self.range.count)
		}

		for widthConstraint in self.numberLabelWidthConstraints {
			widthConstraint.constant = self.scaleThickness
		}

		for heightConstraint in self.numberLabelHeightConstraints {
			heightConstraint.constant = self.scaleThickness
		}

		for sizeConstraint in selectionViewSizeConstraints {
			sizeConstraint.constant = self.scaleThickness
		}

		// TODO: update radial constraint constants for scale thickness

		switch displayMode {
		case .horizontal:
			NSLayoutConstraint.deactivate(self.circularConstraints)
			NSLayoutConstraint.deactivate(self.verticalConstraints)
			NSLayoutConstraint.activate(self.horizontalConstraints)

		case .circular:
			NSLayoutConstraint.deactivate(self.horizontalConstraints)
			NSLayoutConstraint.deactivate(self.verticalConstraints)
			NSLayoutConstraint.activate(self.circularConstraints)

		case .vertical:
			NSLayoutConstraint.deactivate(self.circularConstraints)
			NSLayoutConstraint.deactivate(self.horizontalConstraints)
			NSLayoutConstraint.activate(self.verticalConstraints)
		}
	}

	private func configureNumberLabels() {
		guard range.lowerBound > -998 && range.upperBound < 999 else {
			return
		}

		for numberLabel in self.numberLabels {
			numberLabel.removeFromSuperview()
		}

		self.numberLabels.removeAll()

		self.numberLabelWidthConstraints.removeAll()
		self.numberLabelHeightConstraints.removeAll()
		self.horizontalConstraints.removeAll()
		self.circularConstraints.removeAll()
		self.verticalConstraints.removeAll()

		let fractionalIncrement = 2.0 / CGFloat(self.range.count)
		var fraction = fractionalIncrement / 2

		let maxAngle: CGFloat = 0.75 * 2 * .pi // Use 3/4 of a circle.
		let angleIncrement = maxAngle / CGFloat(self.range.count - 1)
		var angle: CGFloat = 0.75 * .pi // Start at 7:30, end at 4:30.

		for index in self.range {
			let label = UILabel(frame: .zero)
			label.text = Self.numberFormatter.string(from: index as NSNumber)
			label.textAlignment = .center
			label.tag = index
			label.isUserInteractionEnabled = true
			label.adjustsFontForContentSizeCategory = true
			label.font = self.numberFont
			label.translatesAutoresizingMaskIntoConstraints = false

			self.numberLabels.append(label)
			self.scaleView.insertSubview(label, aboveSubview: self.selectionView)

			self.numberLabelWidthConstraints.append(label.widthAnchor.constraint(equalToConstant: self.scaleThickness))
			self.numberLabelHeightConstraints.append(label.heightAnchor.constraint(equalToConstant: self.scaleThickness))

			self.horizontalConstraints.append(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self.scaleView, attribute: .centerX, multiplier: fraction, constant: 0))

			self.horizontalConstraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self.scaleView, attribute: .centerY, multiplier: 1, constant: 0))

			self.verticalConstraints.append(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self.scaleView, attribute: .centerX, multiplier: 1, constant: 0))

			self.verticalConstraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self.scaleView, attribute: .centerY, multiplier: fraction, constant: 0))

			self.circularConstraints.append(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self.scaleView, attribute: .centerX, multiplier: 1 + cos(angle), constant: -scaleThickness / 2 * cos(angle)))

			self.circularConstraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self.scaleView, attribute: .centerY, multiplier: 1 + sin(angle) + 0.0001, constant: -scaleThickness / 2 * sin(angle)))

			fraction += fractionalIncrement
			angle += angleIncrement
		}
	}

	private func updateSelection() {
		if let value = self.value {
			self.selectionView.isHidden = false

			let selectedLabel = self.numberLabels[value - self.range.lowerBound]

			for label in self.numberLabels {
				label.textColor = label == selectedLabel ? self.selectedNumberColor : self.numberColor
			}

			self.scaleView.removeConstraints(self.selectionViewPositionConstraints)
			
			self.selectionViewPositionConstraints = [
				self.selectionView.centerXAnchor.constraint(equalTo: selectedLabel.centerXAnchor),
				self.selectionView.centerYAnchor.constraint(equalTo: selectedLabel.centerYAnchor)
			]

			NSLayoutConstraint.activate(self.selectionViewPositionConstraints)
		} else {
			self.selectionView.isHidden = true
		}
	}

	@objc private func tap(_ sender: UITapGestureRecognizer) {
		// TODO: Use hit testing?
		if sender.location(in: self).y <= self.minimumLabel.frame.minY {
			if let index = self.findIndex(for: sender.location(in: self.scaleView)) {
				let correspondingValue = self.range.clamp(index + range.lowerBound)

				if self.value != correspondingValue {
					self.value = correspondingValue
					self.sendActions(for: .valueChanged)
				}
			}
		}
	}

	private func findIndex(for location: CGPoint) -> Int? {
		let xFraction = location.x / self.scaleView.bounds.width
		let yFraction = location.y / self.scaleView.bounds.height

		switch self.displayMode {
		case .horizontal:
			return self.findLinearIndex(axisFraction: xFraction, offAxisFraction: yFraction)

		case .circular:
			return self.findCircularIndex(for: CGPoint(x: xFraction, y: yFraction))

		case .vertical:
			return self.findLinearIndex(axisFraction: yFraction, offAxisFraction: xFraction)

		}
	}

	private func findLinearIndex(axisFraction: CGFloat, offAxisFraction: CGFloat) -> Int? {
		if offAxisFraction > -0.2 && offAxisFraction < 1.2 {
			return Int(axisFraction * CGFloat(self.range.count))
		} else {
			return nil
		}
	}

	private func findCircularIndex(for fraction: CGPoint) -> Int? {
		let point = CGPoint(x: fraction.x * 2 - 1, y: fraction.y * 2 - 1)
		let radius = sqrt(point.x * point.x + point.y * point.y)

		if radius > 0.5 && radius < 1.2 {
			let angleFromVertical = atan2(point.x, -point.y)
			let angleFromScaleStart = angleFromVertical + 0.75 * .pi
			let segmentSize = (1.5 * .pi) / (CGFloat(self.range.count) - 1)

			if angleFromScaleStart > -segmentSize / 2 && angleFromScaleStart < 1.5 * .pi + segmentSize / 2 {
				return Int(round(angleFromScaleStart / (1.5 * .pi) * (CGFloat(self.range.count) - 1)))
			} else {
				return nil
			}
		} else {
			return nil
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
		if event == "path", let boundsAnimation = super.animation(forKey: "bounds") as? CABasicAnimation {
			let animation = CABasicAnimation(keyPath: event)
			animation.fromValue = path
			// Copy values from existing action
			animation.autoreverses = boundsAnimation.autoreverses
			animation.beginTime = boundsAnimation.beginTime
			animation.delegate = boundsAnimation.delegate
			animation.duration = boundsAnimation.duration
			animation.fillMode = boundsAnimation.fillMode
			animation.repeatCount = boundsAnimation.repeatCount
			animation.repeatDuration = boundsAnimation.repeatDuration
			animation.speed = boundsAnimation.speed
			animation.timingFunction = boundsAnimation.timingFunction
			animation.timeOffset = boundsAnimation.timeOffset

			return animation
		} else {
			return super.action(forKey: event)
		}
	}
}
