//
//  CategoryEditView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    
    @State private var viewModel = SettingsViewModel()
    @State private var name: String
    @State private var colorHex: String
    @State private var showAddFeed = false
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _colorHex = State(initialValue: category.colorHex)
    }
    
    var body: some View {
        Form {
            Section("Category Details") {
                TextField("Name", text: $name)
                
                CategoryColorPicker(selectedColorHex: $colorHex)
            }
            
            Section("Feeds") {
                if category.feeds.isEmpty {
                    Text("No feeds in this category")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(category.feeds) { feed in
                        NavigationLink(destination: FeedEditView(feed: feed)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feed.displayName)
                                    .font(.body)
                                
                                Text(feed.url)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete(perform: deleteFeeds)
                }
                
                Button {
                    showAddFeed = true
                } label: {
                    Label("Add Feed", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Edit Category")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            }
        }
        #endif
        .sheet(isPresented: $showAddFeed) {
            AddFeedSheet(category: category)
        }
    }
    
    private func saveChanges() {
        do {
            try viewModel.updateCategory(category, name: name, colorHex: colorHex, modelContext: modelContext)
            dismiss()
        } catch {
            print("Error saving category: \(error)")
        }
    }
    
    private func deleteFeeds(at offsets: IndexSet) {
        for index in offsets {
            let feed = category.feeds[index]
            do {
                try viewModel.deleteFeed(feed, modelContext: modelContext)
            } catch {
                print("Error deleting feed: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryEditView(category: Category(name: "Technology", colorHex: "#007AFF"))
            .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
    }
}
