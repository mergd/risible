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
    
    let category: Category
    
    @State private var viewModel = SettingsViewModel()
    @State private var url = ""
    @State private var errorMessage: String?
    @State private var showPreview = false
    
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
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Feed")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoadingPreview {
                        ProgressView()
                    } else {
                        Button("Next") {
                            Task {
                                await loadPreview()
                            }
                        }
                        .disabled(url.isEmpty)
                    }
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
                    if viewModel.isLoadingPreview {
                        ProgressView()
                    } else {
                        Button("Next") {
                            Task {
                                await loadPreview()
                            }
                        }
                        .disabled(url.isEmpty)
                    }
                }
            }
            #endif
        }
        .sheet(isPresented: $showPreview) {
            URLFeedPreviewSheet(
                feedURL: url,
                feedTitle: nil,
                items: viewModel.previewItems,
                isLoading: viewModel.isLoadingPreview,
                viewModel: viewModel,
                onRefresh: {
                    await viewModel.loadPreview(for: url)
                }
            )
        }
    }
    
    private func loadPreview() async {
        errorMessage = nil
        await viewModel.loadPreview(for: url)
        
        if !viewModel.previewItems.isEmpty || !viewModel.isLoadingPreview {
            showPreview = true
        } else {
            errorMessage = "Unable to load feed. Please check the URL."
        }
    }
}

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    AddFeedSheet(category: Category(name: "Technology", colorHex: "#007AFF"))
        .modelContainer(container)
}
