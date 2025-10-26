//
//  risibleApp.swift
//  risible
//
//  Created by William on 10/24/25.
//

import SwiftUI
import SwiftData

@main
struct risibleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            RSSFeed.self,
            FeedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    AppSettings.shared.updateLastOpenedDate()
                    
                    Task {
                        await SeedingService.seedDatabaseIfNeeded(modelContext: sharedModelContainer.mainContext)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Navigate") {
                Button("Feed") {
                    NotificationCenter.default.post(name: .navigateToFeed, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Discover") {
                    NotificationCenter.default.post(name: .navigateToDiscover, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Divider()
                
                Button("Settings") {
                    NotificationCenter.default.post(name: .navigateToSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandMenu("Feeds") {
                Button("Refresh All Feeds") {
                    NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Add Feed...") {
                    NotificationCenter.default.post(name: .showAddFeed, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Add Category...") {
                    NotificationCenter.default.post(name: .showAddCategory, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
                .frame(width: 600, height: 500)
                .modelContainer(sharedModelContainer)
        }
        #endif
    }
}

extension Notification.Name {
    static let navigateToFeed = Notification.Name("navigateToFeed")
    static let navigateToDiscover = Notification.Name("navigateToDiscover")
    static let navigateToSettings = Notification.Name("navigateToSettings")
    static let refreshAllFeeds = Notification.Name("refreshAllFeeds")
    static let showAddFeed = Notification.Name("showAddFeed")
    static let showAddCategory = Notification.Name("showAddCategory")
}
