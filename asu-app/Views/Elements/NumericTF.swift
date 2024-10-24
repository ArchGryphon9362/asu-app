//
//  NumericTF.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 28/09/2024.
//

import Foundation
import SwiftUI
import Combine

private extension View {
    @ViewBuilder
    func sendLabel() -> some View {
        if #available(iOS 15, *) {
            self.submitLabel(.send)
        } else {
            self
        }
    }
}

private extension NSNumber {
    func value<T: Numeric>() -> T? {
        switch T.self {
        case is Int.Type:
            return self.intValue as? T
        case is Float.Type:
            return self.floatValue as? T
        case is Double.Type:
            return self.doubleValue as? T
        // TODO: add more as needed
        default:
            return nil
        }
    }
}

struct NumericTF<T: Numeric>: View {
    var name: String
    @Binding var value: T
    var `in`: ClosedRange<Float>
    var unit: String? = nil
    var step: Float = 0.001
    /// one unit of input will result in `scaleFactor` units of change
    var scaleFactor: Float = 1.0

    @State private var displayValue: String = ""
    @State private var prevDisplayValue: String = ""

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        var points = String(step).split(separator: ".")[1].count
        if points == 1 && String(step).split(separator: ".")[1] == "0" {
            points = 0
        }
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = points
        formatter.numberStyle = .none
        return formatter
    }

    var body: some View {
        HStack {
            Text(self.name)
                .foregroundColor(.secondary)
            Spacer()
            TextField(
                name,
                text: self.$displayValue,
                onCommit: {
                    // i wish there was a built-in such .value()...
                    guard let displayValue = self.numberFormatter.number(from: self.displayValue) else { return }
                    let scaled = displayValue.floatValue * self.scaleFactor as NSNumber
                    guard let newValue: T = scaled.value() else { return }
                    self.value = newValue
                }
            )
            .sendLabel()
            .multilineTextAlignment(.trailing)
            .onAppear {
                guard let value = (self.value as? NSNumber)?.floatValue else { return }
                self.updateUi(value / self.scaleFactor as NSNumber)
            }
            .onChange(of: self.displayValue) { _ in
                guard self.displayValue != self.prevDisplayValue else { return }
                
                let lower = numberFormatter.string(for: self.in.lowerBound) ?? "0"
                guard !self.displayValue.isEmpty else {
                    self.prevDisplayValue = lower
                    self.displayValue = lower
                    
                    return
                }
                
                let trailingDot = [".", ","].contains(self.displayValue.suffix(1)) ? self.displayValue.suffix(1) : ""
                var result = self.displayValue
                
                if var floatValue = self.numberFormatter.number(from: self.displayValue)?.floatValue {
                    floatValue = round((floatValue - self.in.lowerBound) / step) * step + self.in.lowerBound
                    
                    if !self.in.contains(floatValue) {
                        floatValue = min(max(floatValue, self.in.lowerBound), self.in.upperBound)
                    }
                    
                    result = (numberFormatter.string(for: floatValue) ?? lower) + trailingDot
                } else {
                    result = self.prevDisplayValue
                }
                
                if self.displayValue != result {
                    self.displayValue = result
                }
                
                self.prevDisplayValue = self.displayValue
            }
            .onChange(of: self.value) { _ in
                guard let value = (self.value as? NSNumber)?.floatValue else { return }
                self.updateUi(value / self.scaleFactor as NSNumber)
            }
            if let unit = self.unit {
                Spacer()
                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func updateUi(_ value: NSNumber) {
        let result = self.numberFormatter.string(from: value) ?? self.displayValue
        
        if self.displayValue != result {
            DispatchQueue.main.async {
                self.prevDisplayValue = result
                self.displayValue = result
            }
        }
    }
}
