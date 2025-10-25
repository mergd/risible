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
    @State private var customInterval: TimeInterval?
    @State private var showDeleteConfirmation = false
    
    init(feed: RSSFeed) {
        self.feed = feed
        _nickname = State(initialValue: feed.nickname ?? "")
        _customInterval = State(initialValue: feed.customRefreshInterval)
    }
    
    var body: some View {
        Form {
            Section("Feed Information") {
                LabeledContent("Title", value: feed.title)
                
                LabeledContent("URL") {
                    Text(feed.url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Section("Customization") {
                TextField("Nickname (optional)", text: $nickname)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                
                Toggle("Custom Refresh Interval", isOn: Binding(
                    get: { customInterval != nil },
                    set: { enabled in
                        customInterval = enabled ? 3600 : nil
                    }
                ))
                
                if customInterval != nil {
                    Picker("Interval", selection: Binding(
                        get: { customInterval ?? 3600 },
                        set: { customInterval = $0 }
                    )) {
                        Text("30 minutes").tag(1800.0)
                        Text("1 hour").tag(3600.0)
                        Text("2 hours").tag(7200.0)
                        Text("4 hours").tag(14400.0)
                        Text("6 hours").tag(21600.0)
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Feed")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Edit Feed")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
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
    }
    
    private func saveChanges() {
        do {
            let finalNickname = nickname.isEmpty ? nil : nickname
            try viewModel.updateFeed(feed, nickname: finalNickname, customRefreshInterval: customInterval, modelContext: modelContext)
            dismiss()
        } catch {
            print("Error saving feed: \(error)")
        }
    }
    
    private func deleteFeed() {
        do {
            try viewModel.deleteFeed(feed, modelContext: modelContext)
            dismiss()
        } catch {
            print("Error deleting feed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        FeedEditView(feed: RSSFeed(url: "https://example.com/feed", title: "Example Feed"))
            .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
    }
}
