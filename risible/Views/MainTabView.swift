//
//  MainTabView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = 0
    let appSettings = AppSettings.shared
    
    var body: some View {
        if !appSettings.hasCompletedOnboarding {
            OnboardingView {
                appSettings.hasCompletedOnboarding = true
            }
        } else {
            mainContent
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        #if os(iPadOS)
        if horizontalSizeClass == .regular {
            iPadSidebarView(selectedTab: $selectedTab)
        } else {
            iPhoneTabView(selectedTab: $selectedTab)
        }
        #elseif os(macOS)
        macOSSidebarView(selectedTab: $selectedTab)
        #else
        iPhoneTabView(selectedTab: $selectedTab)
        #endif
    }
}

struct iPhoneTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper.fill")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#if os(iPadOS)
struct iPadSidebarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Feed", systemImage: "newspaper.fill")
                    .tag(0)
                
                Label("Discover", systemImage: "safari.fill")
                    .tag(1)
                
                Label("Settings", systemImage: "gear")
                    .tag(2)
            }
            .navigationTitle("Risible")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            switch selectedTab {
            case 0:
                FeedView()
            case 1:
                DiscoverView()
            case 2:
                SettingsView()
            default:
                FeedView()
            }
        }
    }
}
#endif

#if os(macOS)
struct macOSSidebarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Navigation") {
                    Label("Feed", systemImage: "newspaper.fill")
                        .tag(0)
                    
                    Label("Discover", systemImage: "safari.fill")
                        .tag(1)
                    
                    Label("Settings", systemImage: "gear")
                        .tag(2)
                }
            }
            .navigationTitle("Risible")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    FeedView()
                case 1:
                    DiscoverView()
                case 2:
                    SettingsView()
                default:
                    FeedView()
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }
}
#endif

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    MainTabView()
        .modelContainer(container)
}
