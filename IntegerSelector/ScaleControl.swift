//
//  ScaleControl.swift
//  IntegerSelector
//
//  Created by Frank Schmitt on 2023-01-03.
//

import UIKit

class ScaleControl: UIControl {
    public var selectedValue: Int?
    public let minimumValue: Int
    public let maximumValue: Int
    
    init(minimumValue: Int, maximumValue: Int) {
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        
        (self.numberLabels, self.backgroundView, self.selectionView) = Self.buildViews(for: self.minimumValue...self.maximumValue)

        super.init(frame: .zero)
    }
    
    // MARK: - NSCoding
    
    private static let minimumValueKey = "MinimumValue"
    private static let maximumValueKey = "MaximumValue"
    private static let selectedValueKey = "SelectedValue"

    required init?(coder: NSCoder) {
        self.minimumValue = coder.decodeInteger(forKey: Self.minimumValueKey)
        self.maximumValue = coder.decodeInteger(forKey: Self.maximumValueKey)
        self.selectedValue = coder.decodeInteger(forKey: Self.selectedValueKey)
        
        (self.numberLabels, self.backgroundView, self.selectionView) = Self.buildViews(for: self.minimumValue...self.maximumValue)
        
        super.init(coder: coder)
    }
    
    // MARK: - Private
    
    private static let numberFormatter = NumberFormatter()
    private static let initialSize: CGFloat = 44
    
    private let numberLabels: [UILabel]
    private let backgroundView: UIView
    private let selectionView: UIView
    
    // MARK: Private Static
    
    private static func buildNumberLabels(for range: ClosedRange<Int>) -> [UILabel] {
        var result = [UILabel]()
        var x: CGFloat = 0
        
        for index in range {
            let label = UILabel(frame: CGRect(x: x, y: 0, width: self.initialSize, height: self.initialSize))
            label.text = Self.numberFormatter.string(from: index as NSNumber)
            
            result.append(label)
            
            x += self.initialSize
        }
        
        return result
    }
    
    private static func buildBackgroundView(for range: ClosedRange<Int>) -> UIView {
        return UIView(frame: CGRect(x: 0, y: 0, width: self.initialSize * CGFloat(range.count), height: self.initialSize))
    }
    
    private static func buildSelectionView() -> UIView {
        return UIView(frame: CGRect(x: 0, y: 0, width: Self.initialSize, height: Self.initialSize))
    }
    
    private static func buildViews(for range: ClosedRange<Int>) -> ([UILabel], UIView, UIView) {
        return (self.buildNumberLabels(for: range), self.buildBackgroundView(for: range), self.buildSelectionView())
    }
}
