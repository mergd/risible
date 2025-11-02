//
//  AddFeedSheet.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct AddFeedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let category: Category
    
    @State private var viewModel = SettingsViewModel()
    @State private var url = ""
    @State private var nickname = ""
    @State private var selectedRefreshInterval: TimeInterval = 3600
    @State private var enableNotifications = false
    @State private var isSubmitting = false
    @State private var feedTitle: String?
    @State private var feedDescription: String?
    @State private var feedLoaded = false
    @State private var showPreviewSheet = false
    
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    private var systemGray6: Color {
        #if os(iOS)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .systemGray6)
        #endif
    }
    
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
                Section("Feed URL") {
                    TextField("Feed URL", text: $url)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                        .onSubmit {
                            if !url.isEmpty && !feedLoaded && !viewModel.isLoadingPreview {
                                Task {
                                    await previewFeed()
                                }
                            }
                        }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                if viewModel.isLoadingPreview {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                
                if feedLoaded, let title = feedTitle {
                    Section("Feed Preview") {
                        Button(action: { showPreviewSheet = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if let description = feedDescription {
                                        Text(description)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section("Category") {
                        if categories.isEmpty {
                            Text("No categories available")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Category", selection: Binding(
                                get: { category },
                                set: { _ in }
                            )) {
                                ForEach(categories) { cat in
                                    Text(cat.name).tag(cat)
                                }
                            }
                        }
                    }
                    
                    Section("Feed Details") {
                        TextField("Nickname (optional)", text: $nickname)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            #endif
                    }
                    
                    Section("Notifications") {
                        Toggle("Notify about new articles", isOn: $enableNotifications)
                    }
                    
                    Section {
                        DisclosureGroup("Advanced Options") {
                            Picker("Check for new articles every", selection: $selectedRefreshInterval) {
                                ForEach(refreshIntervals, id: \.value) { interval in
                                    Text(interval.label).tag(interval.value)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Add Feed")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            #endif
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if feedLoaded {
                        Button(action: {
                            Task {
                                await submitFeed()
                            }
                        }) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSubmitting || categories.isEmpty)
                    }
                }
                .padding()
                .background {
                    VStack(spacing: 0) {
                        Divider()
                        Color(colorScheme == .dark ? systemGray6.opacity(0.5) : .white)
                    }
                }
            }
            .sheet(isPresented: $showPreviewSheet) {
                URLFeedPreviewSheet(
                    feedURL: url,
                    feedTitle: feedTitle,
                    items: viewModel.previewItems,
                    isLoading: viewModel.isLoadingPreview,
                    viewModel: viewModel,
                    onRefresh: {
                        await previewFeed()
                    }
                )
            }
        }
    }
    
    private func previewFeed() async {
        viewModel.errorMessage = nil
        await viewModel.loadPreview(for: url)
        
        if viewModel.errorMessage == nil && !viewModel.previewItems.isEmpty {
            feedLoaded = true
            if let firstItem = viewModel.previewItems.first {
                feedTitle = firstItem.title.prefix(50).description
            }
        }
    }
    
    private func submitFeed() async {
        isSubmitting = true
        
        do {
            try await viewModel.addFeed(
                url: url,
                nickname: nickname.isEmpty ? nil : nickname,
                to: category,
                modelContext: modelContext,
                enableNotifications: enableNotifications,
                refreshInterval: selectedRefreshInterval
            )
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    AddFeedSheet(category: Category(name: "Technology", colorHex: "#007AFF"))
        .modelContainer(container)
}
