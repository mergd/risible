//
//  FeedPreviewSheet.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct FeedPreviewSheet: View {
    let feed: CuratedFeed
    let items: [RSSItemData]
    let isLoading: Bool
    let viewModel: DiscoverViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    @State private var showCategoryModal = false
    @State private var selectedCategory: Category?
    @State private var selectedRefreshInterval: TimeInterval = 3600
    @State private var enableNotifications = false
    @State private var isAdding = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading preview...")
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "No Articles",
                        systemImage: "newspaper",
                        description: Text("Unable to load feed preview")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(items, id: \.link) { item in
                                PreviewItemCard(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(feed.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCategoryModal = true
                    } label: {
                        if isAdding {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .disabled(isAdding)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCategoryModal = true
                    } label: {
                        if isAdding {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .disabled(isAdding)
                }
            }
            #endif
            .sheet(isPresented: $showCategoryModal) {
                CategorySelectionModal(
                    feed: feed,
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    selectedRefreshInterval: $selectedRefreshInterval,
                    enableNotifications: $enableNotifications,
                    isAdding: $isAdding,
                    onAdd: {
                        Task {
                            await addFeed()
                        }
                    },
                    onCancel: {
                        showCategoryModal = false
                    }
                )
            }
            .alert("Added!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(feed.name) has been added to your feeds")
            }
        }
    }
    
    private func addFeed() async {
        guard let category = selectedCategory else { return }
        
        isAdding = true
        
        do {
            try await viewModel.addFeed(
                feed,
                to: category,
                modelContext: modelContext,
                enableNotifications: enableNotifications,
                refreshInterval: selectedRefreshInterval
            )
            showSuccess = true
            showCategoryModal = false
        } catch {
            print("Error adding feed: \(error)")
        }
        
        isAdding = false
    }
}

struct CategorySelectionModal: View {
    let feed: CuratedFeed
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Binding var selectedRefreshInterval: TimeInterval
    @Binding var enableNotifications: Bool
    @Binding var isAdding: Bool
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showAdvanced = false
    
    private let refreshIntervals: [(label: String, value: TimeInterval)] = [
        ("15 minutes", 15 * 60),
        ("30 minutes", 30 * 60),
        ("1 hour", 3600),
        ("3 hours", 3 * 3600),
        ("6 hours", 6 * 3600),
        ("12 hours", 12 * 3600),
        ("24 hours", 24 * 3600),
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Add to Category") {
                    if categories.isEmpty {
                        Text("No categories available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Notify about new articles", isOn: $enableNotifications)
                }
                
                Section {
                    DisclosureGroup("Advanced Options", isExpanded: $showAdvanced) {
                        Picker("Check for new articles every", selection: $selectedRefreshInterval) {
                            ForEach(refreshIntervals, id: \.value) { interval in
                                Text(interval.label).tag(interval.value)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Add Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(selectedCategory == nil || isAdding)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview Item Card

struct PreviewItemCard: View {
    let item: RSSItemData
    @Environment(\.colorScheme) private var colorScheme
    
    private var systemGray6: Color {
        #if os(iOS)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .systemGray6)
        #endif
    }
    
    private var systemGray5: Color {
        #if os(iOS)
        Color(uiColor: .systemGray5)
        #else
        Color(nsColor: .systemGray5)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let imageURLString = item.imageURL,
               let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(systemGray6)
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(systemGray6)
                            .overlay {
                                Image(systemName: "photo.fill")
                                    .font(.title)
                                    .foregroundStyle(.tertiary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if let description = item.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Text(item.publishedDate.relativeTimeString())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? systemGray6.opacity(0.5) : .white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 8, x: 0, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(systemGray5.opacity(0.5), lineWidth: 0.5)
        }
    }
}

#Preview {
    FeedPreviewSheet(
        feed: CuratedFeed(
            name: "TechCrunch",
            description: "Tech news",
            url: "https://techcrunch.com/feed/",
            iconName: "laptopcomputer"
        ),
        items: [],
        isLoading: false,
        viewModel: DiscoverViewModel()
    )
    .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
}
