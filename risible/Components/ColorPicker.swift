//
//  CategoryColorPicker.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI

struct CategoryColorPicker: View {
    @Binding var selectedColorHex: String
    
    private let presetColors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Green", "#34C759"),
        ("Teal", "#5AC8FA"),
        ("Indigo", "#5856D6"),
        ("Cyan", "#32ADE6"),
        ("Mint", "#00C7BE"),
        ("Brown", "#A2845E")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                ForEach(presetColors, id: \.hex) { color in
                    Button {
                        selectedColorHex = color.hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: color.hex) ?? .blue)
                                .frame(width: 44, height: 44)
                            
                            if selectedColorHex == color.hex {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
    }
}

#Preview {
    CategoryColorPicker(selectedColorHex: .constant("#007AFF"))
}
