//
//  TestLabel.swift
//  IntegerSelector
//
//  Created by Frank Schmitt on 2023-01-04.
//

import UIKit

class TestLabel: UILabel {
	override var intrinsicContentSize: CGSize {
		return super.intrinsicContentSize
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return super.sizeThatFits(size)
	}

	override func sizeToFit() {
		super.sizeToFit()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
	}

	override var bounds: CGRect {
		didSet {
			print("Bounds was set")
		}
	}

	override var frame: CGRect {
		didSet {
			print("Frame was set")
		}
	}

	override func invalidateIntrinsicContentSize() {
		super.invalidateIntrinsicContentSize()
	}

	override func setNeedsLayout() {
		super.setNeedsLayout()
	}

	override func setNeedsUpdateConstraints() {
		super.setNeedsUpdateConstraints()
	}

	override func setNeedsDisplay() {
		super.setNeedsDisplay()
	}

	override class func willChangeValue(forKey key: String) {
		super.willChangeValue(forKey: key)
	}

	override func updateConstraints() {
		super.updateConstraints()
	}
}
