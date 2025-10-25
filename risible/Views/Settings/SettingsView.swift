//
//  SettingsView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    @State private var viewModel = SettingsViewModel()
    @State private var showAddCategory = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if categories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            Text("No categories yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(categories) { category in
                            NavigationLink(destination: CategoryEditView(category: category)) {
                                CategorySettingsRow(category: category)
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    
                    Button {
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                        showAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Organize your RSS feeds into custom categories")
                }
                
                Section {
                    HStack {
                        Label("Default Refresh", systemImage: "arrow.clockwise")
                        Spacer()
                        Text(formatInterval(AppSettings.shared.defaultRefreshInterval))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Last Opened", systemImage: "clock")
                        Spacer()
                        if let lastOpened = AppSettings.shared.lastOpenedDate {
                            Text(lastOpened, style: .relative)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("App Info")
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Label("About Risible", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    HStack {
                        Label("Version", systemImage: "app.badge")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet()
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        #if os(iOS)
        let notificationFeedback = UINotificationFeedbackGenerator()
        #endif
        
        for index in offsets {
            let category = categories[index]
            do {
                try viewModel.deleteCategory(category, modelContext: modelContext)
                #if os(iOS)
                notificationFeedback.notificationOccurred(.success)
                #endif
            } catch {
                print("Error deleting category: \(error)")
                #if os(iOS)
                notificationFeedback.notificationOccurred(.error)
                #endif
            }
        }
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        if hours == 1 {
            return "1 hour"
        } else {
            return "\(hours) hours"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
}
