//
//  ScaleControl.swift
//  IntegerSelector
//
//  Created by Frank Schmitt on 2023-01-03.
//

import UIKit

@IBDesignable
class ScaleControl: UIControl {
    public static var noValue = -1
    
    @IBInspectable public var minimumValue: Int {
        get {
            return self.range.lowerBound
        }
        set {
            self.range = newValue...self.range.upperBound
        }
    }
    
    @IBInspectable public var maximumValue: Int {
        get {
            return self.range.upperBound
        }
        set {
            self.range = self.range.lowerBound...newValue
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
    
    @objc dynamic public var scaleColor: UIColor = .secondarySystemBackground
    
    @objc dynamic public var selectionColor: UIColor = .tintColor
    
    @objc dynamic public var numberColor: UIColor = .label
    
    @objc dynamic public var selectedNumberColor: UIColor = .systemBackground
    
    @objc dynamic public var selectorInset: CGFloat = 2
    
    @objc dynamic public var font: UIFont = .preferredFont(forTextStyle: .body)
    
    init(range: ClosedRange<Int>) {
        self.range = range
        
        super.init(frame: .zero)
        
        self.configureViews()
    }
    
    convenience init(minimumValue: Int, maximumValue: Int) {
        self.init(range: minimumValue...maximumValue)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.layoutNumberLabels()
        
        let buttonSize = self.numberLabels.first?.bounds.size ?? .zero
        
        self.scaleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: buttonSize.height)
        
        self.scaleView.layer.cornerRadius = min(buttonSize.width, buttonSize.height) / 2
        
        self.updateSelection(animated: false)

        self.selectionView.layer.cornerRadius = min(self.selectionView.bounds.height, self.selectionView.bounds.width) / 2
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
    
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    private var value: Int? {
        didSet {
            self.updateSelection(animated: false)
            self.setNeedsLayout()
        }
    }
    
    private var range: ClosedRange<Int> {
        didSet {
            self.configureNumberLabels()
            self.setNeedsLayout()
        }
    }
    
    private func configureViews() {
        self.scaleView.backgroundColor = self.scaleColor
        self.addSubview(self.scaleView)
        
        self.tapGestureRecognizer.addTarget(self, action: #selector(tap(_:)))
        self.addGestureRecognizer(self.tapGestureRecognizer)
        
        self.selectionView.backgroundColor = self.selectionColor
        self.addSubview(self.selectionView)

        self.configureNumberLabels()
                        
        self.updateSelection(animated: false)
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
            label.font = self.font
            
            self.numberLabels.append(label)
            self.insertSubview(label, aboveSubview: self.selectionView)
        }
        
        self.layoutNumberLabels()
    }
    
    private func layoutNumberLabels() {
        let idealWidth = self.bounds.width / CGFloat(self.range.count)
        let screenWidth = self.displayScaleRound(idealWidth)
        var x: CGFloat = 0
        
        for numberLabel in self.numberLabels {
            numberLabel.frame = CGRect(x: self.displayScaleRound(x), y: 0, width: screenWidth, height: screenWidth)
            
            x += idealWidth
        }
    }

    private func updateSelection(animated: Bool) {
        let updateBlock = {
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
        
        if animated {
            UIView.animate(withDuration: Self.animationDuration, animations: updateBlock)
        } else {
            updateBlock()
        }
    }
    
    @objc private func tap(_ sender: UITapGestureRecognizer) {
        guard let subview = self.hitTest(sender.location(in: self), with: nil), Set(self.numberLabels).contains(subview) else {
            print("Touch not in number label")
            return
        }
        
        self.value = subview.tag
        
        self.sendActions(for: .valueChanged)
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
