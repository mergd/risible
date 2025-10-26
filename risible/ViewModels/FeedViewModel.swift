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
    var feedErrors: [String: FeedErrorInfo] = [:]
    
    private let rssService: RSSServiceProtocol
    
    init(rssService: RSSServiceProtocol = LocalRSSService()) {
        self.rssService = rssService
    }
    
    func refreshFeeds(for category: Category?, modelContext: ModelContext) async {
        isLoading = true
        feedErrors.removeAll()
        
        defer { isLoading = false }
        
        do {
            if let category = category {
                try await refreshCategory(category, modelContext: modelContext)
            } else {
                let descriptor = FetchDescriptor<Category>()
                let categories = try modelContext.fetch(descriptor)
                
                for category in categories {
                    try await refreshCategory(category, modelContext: modelContext)
                }
            }
        } catch {
            // Top-level error
        }
    }
    
    private func refreshCategory(_ category: Category, modelContext: ModelContext) async throws {
        for feed in category.feeds {
            if feed.isPaused {
                continue
            }
            
            do {
                let result = try await rssService.fetchFeed(url: feed.url)
                
                if feed.title.isEmpty || feed.title != result.title {
                    feed.title = result.title
                }
                
                for itemData in result.items.prefix(50) {
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
                
                feedErrors.removeValue(forKey: feed.url)
                
            } catch {
                feedErrors[feed.url] = FeedErrorInfo(
                    feedTitle: feed.displayName,
                    feedURL: feed.url,
                    error: error
                )
            }
        }
        
        try modelContext.save()
    }
}

struct FeedErrorInfo {
    let feedTitle: String
    let feedURL: String
    let error: Error
    
    var displayMessage: String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}
