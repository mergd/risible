//
//  FeedEditView.swift
//  risible
//
//  Created by William on 10/25/25.0.
//

import SwiftUI
import SwiftData

struct FeedEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let feed: RSSFeed
    
    @State private var viewModel = SettingsViewModel()
    @State private var nickname: String
    @State private var url: String
    @State private var customInterval: TimeInterval?
    @State private var isPaused: Bool
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(feed: RSSFeed) {
        self.feed = feed
        _nickname = State(initialValue: feed.nickname ?? "")
        _url = State(initialValue: feed.url)
        _customInterval = State(initialValue: feed.customRefreshInterval)
        _isPaused = State(initialValue: feed.isPaused)
    }
    
    var refreshIntervalDisplay: String {
        let interval = customInterval ?? AppSettings.shared.defaultRefreshInterval
        
        switch interval {
        case 1800:
            return "30 min"
        case 3600:
            return "1 hour"
        case 7200:
            return "2 hours"
        case 14400:
            return "4 hours"
        case 21600:
            return "6 hours"
        default:
            return "\(Int(interval / 3600)) hours"
        }
    }
    
    private var hasCustomInterval: Binding<Bool> {
        Binding(
            get: { customInterval != nil },
            set: { enabled in
                customInterval = enabled ? 3600 : nil
            }
        )
    }
    
    private var customIntervalValue: Binding<TimeInterval> {
        Binding(
            get: { customInterval ?? 3600 },
            set: { customInterval = $0 }
        )
    }
    
    var body: some View {
        Form {
            feedInformationSection
            customizationSection
            statusSection
            deleteSection
        }
        .navigationTitle("Edit Feed")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(isLoading)
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(isLoading)
            }
        }
        #endif
        .confirmationDialog("Delete Feed", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteFeed()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this feed? All articles will be removed.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
    }
    
    private var feedInformationSection: some View {
        Section("Feed Information") {
            LabeledContent("Title", value: feed.title)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("URL")
                    .foregroundStyle(.secondary)
                TextField("Feed URL", text: $url)
                    .textInputAutocapitalization(.never)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    #endif
            }
        }
    }
    
    private var customizationSection: some View {
        Section("Customization") {
            TextField("Nickname (optional)", text: $nickname)
                #if os(iOS)
                .textInputAutocapitalization(.words)
                #endif
            
            Toggle("Custom Refresh Interval", isOn: hasCustomInterval)
            
            if customInterval == nil {
                Text("Default: \(refreshIntervalDisplay)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if customInterval != nil {
                Picker("Interval", selection: customIntervalValue) {
                    Text("30 minutes").tag(1800.0)
                    Text("1 hour").tag(3600.0)
                    Text("2 hours").tag(7200.0)
                    Text("4 hours").tag(14400.0)
                    Text("6 hours").tag(21600.0)
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var statusSection: some View {
        Section {
            Toggle("Paused", isOn: $isPaused)
        } header: {
            Text("Status")
        } footer: {
            Text(isPaused ? "New entries will not be fetched" : "")
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete Feed")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func saveChanges() {
        isLoading = true
        Task {
            do {
                if url != feed.url {
                    try await viewModel.updateFeedURL(feed, newURL: url, modelContext: modelContext)
                }
                
                let finalNickname = nickname.isEmpty ? nil : nickname
                try viewModel.updateFeed(feed, nickname: finalNickname, customRefreshInterval: customInterval, modelContext: modelContext)
                
                if isPaused != feed.isPaused {
                    try viewModel.toggleFeedPauseState(feed, modelContext: modelContext)
                }
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func deleteFeed() {
        do {
            try viewModel.deleteFeed(feed, modelContext: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        FeedEditView(feed: RSSFeed(url: "https://example.com/feed", title: "Example Feed"))
            .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
    }
}
