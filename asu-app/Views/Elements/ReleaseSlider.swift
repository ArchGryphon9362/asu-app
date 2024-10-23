//
//  ReleaseSlider.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 28/09/2024.
//

import Foundation
import SwiftUI

struct ReleaseSlider<T: Numeric>: View {
    var name: String
    @Binding var value: T
    var `in`: ClosedRange<Float>
    var unit: String? = nil
    var step: Float = 0.001
    /// one unit of input will result in `scaleFactor` units of change
    var scaleFactor: Float = 1.0
    
    @State private var sliderValue: Float = 0.0
    @State private var displayValue: String = ""
    @State private var isEditing = false
    @State private var prevSliderValue: Float = 0.0
    @State private var width: Float = 0.0
    
    #if !os(macOS)
    private let feedback = UISelectionFeedbackGenerator()
    #endif
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        var points = String(step).split(separator: ".")[1].count
        if points == 1 && String(step).split(separator: ".")[1] == "0" {
            points = 0
        }
        formatter.minimumFractionDigits = points
        formatter.maximumFractionDigits = points
        formatter.numberStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Text(self.name)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack {
                Slider(value: self.$sliderValue, in: self.in) { editing in
                    self.isEditing = editing
                    
                    if !self.isEditing {
                        DispatchQueue.main.async {
                            let scaled = self.updateUi(self.sliderValue) * self.scaleFactor
                            guard let scaled = scaled as NSNumber as? T else { return }
                            self.value = scaled
                        }
                    }
                }
                .onAppear {
                    #if !os(macOS)
                    self.feedback.prepare()
                    #endif
                    
                    guard let value = (self.value as? NSNumber)?.floatValue else { return }
                    self.updateUi(value / self.scaleFactor, valueChange: true)
                }
                .onChange(of: self.sliderValue) { _ in
                    guard self.sliderValue != self.prevSliderValue else { return }
                    
                    // jittery on macOS. if this is found out to be jittery on any iOS
                    // device this should be perma-falsed. a little hacky, but i feel
                    // like that's literally everything when it comes to SwiftUI
                    #if !os(macOS)
                    // only do if there's enough space for reasonable haptics
                    let numberOfPoints = (self.in.upperBound - self.in.lowerBound) / step
                    let snappySlider = self.width / numberOfPoints >= 3
                    #else
                    let snappySlider = false
                    #endif
                    
                    self.updateUi(self.sliderValue, updateUi: snappySlider)
                }
                .onChange(of: self.value) { _ in
                    guard let value = (self.value as? NSNumber)?.floatValue else { return }
                    self.updateUi(value / self.scaleFactor, valueChange: true)
                }
                .background(
                    GeometryReader { geometry in
                        HStack {}
                            .onAppear {
                                // this will have to be moved to somewhere other than onAppear if we
                                // start doing any dyanmic scaling for WHATEVER reason
                                self.width = Float(geometry.size.width)
                            }
                    }
                )
                Spacer()
                TextField("", text: self.$displayValue)
                    .allowsHitTesting(false)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(width: 75.0)
                if let unit = self.unit {
                    Text(unit)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @discardableResult
    private func updateUi(_ value: Float, valueChange: Bool = false, updateUi: Bool = true) -> Float {
        let result = round((value + self.in.lowerBound) / step) * step - self.in.lowerBound
        var stringUpdate = result
        
        if updateUi {
            self.sliderValue = result
        }
        
        if valueChange {
            self.prevSliderValue = value
            self.sliderValue = value
            stringUpdate = value
        }
        
        // haptics
        let hapticRange = (result - self.step / 2)...(result + self.step / 2)
        
        // must be at least 3px spacing between points for haptics to enable
        let numberOfPoints = (self.in.upperBound - self.in.lowerBound) / step
        let hapticsEnabled = self.width / numberOfPoints >= 3
        
        if !valueChange, hapticRange.contains(value), self.prevSliderValue != result, hapticsEnabled {
            self.prevSliderValue = result
            #if os(macOS)
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            #else
            self.feedback.selectionChanged()
            #endif
        }
        
        self.displayValue = self.numberFormatter.string(from: stringUpdate as NSNumber) ?? "N/A"
        
        return result
    }
}
