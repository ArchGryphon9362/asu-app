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
    var step: Float = 0.001

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
                    guard let newValue: T = self.numberFormatter.number(from: self.displayValue)?.value() else { return }
                    self.value = newValue
                }
            )
            .sendLabel()
            .multilineTextAlignment(.trailing)
            .onAppear {
                self.updateUi(value)
            }
            .onChange(of: self.displayValue) { _ in
                guard self.displayValue != self.prevDisplayValue else { return }
                
                guard !self.displayValue.isEmpty else {
                    self.prevDisplayValue = "0"
                    self.displayValue = "0"
                    
                    return
                }
                
                let trailingDot = [".", ","].contains(self.displayValue.suffix(1)) ? self.displayValue.suffix(1) : ""
                var result = self.displayValue
                
                if var floatValue = self.numberFormatter.number(from: self.displayValue)?.floatValue {
                    floatValue = (round((floatValue + self.in.lowerBound) / step) - self.in.lowerBound) * step
                    
                    if !self.in.contains(floatValue) {
                        floatValue = min(max(floatValue, self.in.lowerBound), self.in.upperBound)
                    }
                    
                    result = (numberFormatter.string(for: floatValue) ?? "0") + trailingDot
                } else {
                    result = self.prevDisplayValue
                }
                
                if self.displayValue != result {
                    self.displayValue = result
                }
                
                self.prevDisplayValue = self.displayValue
            }
            .onChange(of: self.value) { _ in
                self.updateUi(value)
            }
        }
    }
    
    private func updateUi(_ value: T) {
        guard let value = value as? NSNumber else { return }
        
        let result = self.numberFormatter.string(from: value) ?? self.displayValue
        
        if self.displayValue != result {
            DispatchQueue.main.async {
                self.prevDisplayValue = result
                self.displayValue = result
            }
        }
    }
}
