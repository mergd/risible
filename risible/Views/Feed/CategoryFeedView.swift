//
//  CategoryFeedView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct CategoryFeedView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category?
    
    @State private var viewModel = FeedViewModel()
    @State private var isRefreshing = false
    
    private var feedItems: [FeedItem] {
        let descriptor: FetchDescriptor<FeedItem>
        
        if let category = category {
            let categoryID = category.id
            descriptor = FetchDescriptor<FeedItem>(
                predicate: #Predicate<FeedItem> { item in
                    item.feed?.category?.id == categoryID
                },
                sortBy: [SortDescriptor(\FeedItem.publishedDate, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<FeedItem>(
                sortBy: [SortDescriptor(\FeedItem.publishedDate, order: .reverse)]
            )
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var body: some View {
        AdaptiveFeedLayout(
            feedItems: feedItems,
            category: category,
            isRefreshing: isRefreshing,
            refreshAction: {
                #if os(iOS)
                let feedbackGenerator = UINotificationFeedbackGenerator()
                #endif
                
                isRefreshing = true
                await viewModel.refreshFeeds(for: category, modelContext: modelContext)
                isRefreshing = false
                
                #if os(iOS)
                feedbackGenerator.notificationOccurred(.success)
                #endif
            }
        )
    }
}

struct AdaptiveFeedLayout: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let feedItems: [FeedItem]
    let category: Category?
    let isRefreshing: Bool
    let refreshAction: () async -> Void
    
    private var columns: [GridItem] {
        #if os(macOS)
        return [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]
        #else
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        } else {
            return [GridItem(.flexible())]
        }
        #endif
    }
    
    var body: some View {
        ZStack {
            if feedItems.isEmpty {
                EmptyFeedView(category: category)
                    .transition(.opacity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(feedItems.prefix(50)) { item in
                            FeedItemCard(item: item)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                #if os(iOS)
                .refreshable {
                    await refreshAction()
                }
                #endif
            }
            
            #if os(macOS)
            if !feedItems.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await refreshAction()
                            }
                        } label: {
                            Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                                .symbolEffect(.rotate, isActive: isRefreshing)
                        }
                        .help("Refresh feeds")
                        .disabled(isRefreshing)
                    }
                    .padding()
                    Spacer()
                }
            }
            #endif
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: feedItems.isEmpty)
    }
}

struct EmptyFeedView: View {
    let category: Category?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: category == nil ? "newspaper.fill" : "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .symbolEffect(.bounce, value: category)
            
            VStack(spacing: 8) {
                Text("No Articles Yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if category == nil {
                    Text("Discover and add feeds to start reading!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text("Add RSS feeds to \"\(category?.name ?? "this category")\" in Settings")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            #if os(iOS)
            if category == nil {
                NavigationLink(destination: DiscoverView()) {
                    Label("Browse Feeds", systemImage: "safari.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No articles available")
        .accessibilityHint(category == nil ? "Go to Discover tab to add feeds" : "Go to Settings to add feeds to this category")
    }
}

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    CategoryFeedView(category: nil)
        .modelContainer(container)
}
