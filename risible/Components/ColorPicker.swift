//
//  CategoryColorPicker.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI

struct ColorPickerRow: View {
    @Binding var selectedColor: Color
    @Binding var selectedColorHex: String
    
    var body: some View {
        ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
            .onChange(of: selectedColor) { oldValue, newValue in
                selectedColorHex = newValue.toHex()
            }
    }
}

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var selectedColorHex: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Pick a Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedColorHex = selectedColor.toHex()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ColorPickerRow(selectedColor: .constant(.blue), selectedColorHex: .constant("#007AFF"))
}
