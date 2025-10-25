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
    @State private var nickname = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Feed Details") {
                    TextField("Feed URL", text: $url)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                    
                    TextField("Nickname (optional)", text: $nickname)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
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
                    .disabled(isAdding)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isAdding {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task {
                                await addFeed()
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
                    .disabled(isAdding)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isAdding {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task {
                                await addFeed()
                            }
                        }
                        .disabled(url.isEmpty)
                    }
                }
            }
            #endif
        }
    }
    
    private func addFeed() async {
        isAdding = true
        errorMessage = nil
        
        do {
            let finalNickname = nickname.isEmpty ? nil : nickname
            try await viewModel.addFeed(url: url, nickname: finalNickname, to: category, modelContext: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isAdding = false
    }
}

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    AddFeedSheet(category: Category(name: "Technology", colorHex: "#007AFF"))
        .modelContainer(container)
}
