//
//  AddCategorySheet.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = SettingsViewModel()
    @State private var name = ""
    @State private var colorHex = "#007AFF"
    @State private var selectedColor = Color(hex: "#007AFF") ?? .blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $name)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    
                    ColorPickerRow(selectedColor: $selectedColor, selectedColorHex: $colorHex)
                }
            }
            .navigationTitle("New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            #endif
        }
    }
    
    private func addCategory() {
        do {
            try viewModel.createCategory(name: name, colorHex: colorHex, modelContext: modelContext)
            dismiss()
        } catch {
            print("Error creating category: \(error)")
        }
    }
}

#Preview {
    AddCategorySheet()
        .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
}
