//
//  FeedViewModel.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData

@Observable
final class FeedViewModel {
    var selectedCategory: Category?
    var isLoading = false
    var errorMessage: String?
    
    private let rssService: RSSServiceProtocol
    
    init(rssService: RSSServiceProtocol = LocalRSSService()) {
        self.rssService = rssService
    }
    
    func refreshFeeds(for category: Category?, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            if let category = category {
                // Refresh specific category
                try await refreshCategory(category, modelContext: modelContext)
            } else {
                // Refresh all feeds
                let descriptor = FetchDescriptor<Category>()
                let categories = try modelContext.fetch(descriptor)
                
                for category in categories {
                    try await refreshCategory(category, modelContext: modelContext)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func refreshCategory(_ category: Category, modelContext: ModelContext) async throws {
        for feed in category.feeds {
            do {
                let result = try await rssService.fetchFeed(url: feed.url)
                
                // Update feed title if needed
                if feed.title.isEmpty || feed.title != result.title {
                    feed.title = result.title
                }
                
                // Add new items
                for itemData in result.items.prefix(50) { // Keep only latest 50
                    // Check if item already exists
                    let feedID = feed.id
                    let itemLink = itemData.link
                    let existingDescriptor = FetchDescriptor<FeedItem>(
                        predicate: #Predicate<FeedItem> { item in
                            item.link == itemLink && item.feed?.id == feedID
                        }
                    )
                    
                    let existing = try modelContext.fetch(existingDescriptor)
                    
                    if existing.isEmpty {
                        let newItem = FeedItem(
                            title: itemData.title,
                            link: itemData.link,
                            itemDescription: itemData.description,
                            imageURL: itemData.imageURL,
                            publishedDate: itemData.publishedDate
                        )
                        newItem.feed = feed
                        modelContext.insert(newItem)
                    }
                }
                
                // Clean up old items (keep only 100 most recent per feed)
                let feedID = feed.id
                let itemsDescriptor = FetchDescriptor<FeedItem>(
                    predicate: #Predicate<FeedItem> { item in
                        item.feed?.id == feedID
                    },
                    sortBy: [SortDescriptor(\FeedItem.publishedDate, order: .reverse)]
                )
                
                let allItems = try modelContext.fetch(itemsDescriptor)
                if allItems.count > 100 {
                    for item in allItems.dropFirst(100) {
                        modelContext.delete(item)
                    }
                }
                
            } catch {
                print("Error refreshing feed \(feed.url): \(error)")
                // Continue with other feeds
            }
        }
        
        try modelContext.save()
    }
}
