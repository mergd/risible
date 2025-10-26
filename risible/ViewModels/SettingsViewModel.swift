//
//  SettingsViewModel.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData

@Observable
final class SettingsViewModel {
    var errorMessage: String?
    var previewItems: [RSSItemData] = []
    var isLoadingPreview = false
    
    private let rssService: RSSServiceProtocol
    
    init(rssService: RSSServiceProtocol = LocalRSSService()) {
        self.rssService = rssService
    }
    
    func createCategory(name: String, colorHex: String, modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\Category.sortOrder, order: .reverse)]
        )
        let categories = try modelContext.fetch(descriptor)
        let maxOrder = categories.first?.sortOrder ?? -1
        
        let category = Category(name: name, colorHex: colorHex, sortOrder: maxOrder + 1)
        modelContext.insert(category)
        try modelContext.save()
    }
    
    func updateCategory(_ category: Category, name: String, colorHex: String, modelContext: ModelContext) throws {
        category.name = name
        category.colorHex = colorHex
        try modelContext.save()
    }
    
    func deleteCategory(_ category: Category, modelContext: ModelContext) throws {
        modelContext.delete(category)
        try modelContext.save()
    }
    
    func addFeed(url: String, nickname: String?, to category: Category, modelContext: ModelContext) async throws {
        // Validate URL
        guard URL(string: url) != nil else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        // Check if feed already exists
        let descriptor = FetchDescriptor<RSSFeed>(
            predicate: #Predicate<RSSFeed> { feed in
                feed.url == url
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            throw NSError(domain: "Feed already exists", code: 0)
        }
        
        // Create feed with temporary title
        let feed = RSSFeed(url: url, title: "Loading...", nickname: nickname)
        feed.category = category
        modelContext.insert(feed)
        try modelContext.save()
        
        // Fetch feed to get real title and items
        let rssService = LocalRSSService()
        do {
            let result = try await rssService.fetchFeed(url: url)
            feed.title = result.title
            
            // Add initial items
            for itemData in result.items.prefix(50) {
                let item = FeedItem(
                    title: itemData.title,
                    link: itemData.link,
                    itemDescription: itemData.description,
                    imageURL: itemData.imageURL,
                    publishedDate: itemData.publishedDate
                )
                item.feed = feed
                modelContext.insert(item)
            }
            
            try modelContext.save()
        } catch {
            // If fetch fails, keep the feed but show error
            throw error
        }
    }
    
    func updateFeed(_ feed: RSSFeed, nickname: String?, customRefreshInterval: TimeInterval?, modelContext: ModelContext) throws {
        feed.nickname = nickname
        feed.customRefreshInterval = customRefreshInterval
        try modelContext.save()
    }
    
    func updateFeedURL(_ feed: RSSFeed, newURL: String, modelContext: ModelContext) async throws {
        guard URL(string: newURL) != nil else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let feedID = feed.id
        let descriptor = FetchDescriptor<RSSFeed>(
            predicate: #Predicate<RSSFeed> { existingFeed in
                existingFeed.url == newURL && existingFeed.id != feedID
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            throw NSError(domain: "Feed URL already exists", code: 0)
        }
        
        feed.url = newURL
        
        let rssService = LocalRSSService()
        let result = try await rssService.fetchFeed(url: newURL)
        feed.title = result.title
        
        try modelContext.save()
    }
    
    func toggleFeedPauseState(_ feed: RSSFeed, modelContext: ModelContext) throws {
        feed.isPaused.toggle()
        try modelContext.save()
    }
    
    func deleteFeed(_ feed: RSSFeed, modelContext: ModelContext) throws {
        modelContext.delete(feed)
        try modelContext.save()
    }
    
    func loadPreview(for url: String) async {
        isLoadingPreview = true
        previewItems = []
        
        do {
            let result = try await rssService.fetchFeed(url: url)
            previewItems = Array(result.items.prefix(10))
        } catch {
            print("Error loading preview: \(error)")
        }
        
        isLoadingPreview = false
    }
    
    func addFeed(
        url: String,
        nickname: String?,
        to category: Category,
        modelContext: ModelContext,
        enableNotifications: Bool = false,
        refreshInterval: TimeInterval? = nil
    ) async throws {
        // Validate URL
        guard URL(string: url) != nil else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        // Check if feed already exists
        let descriptor = FetchDescriptor<RSSFeed>(
            predicate: #Predicate<RSSFeed> { feed in
                feed.url == url
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            throw NSError(domain: "Feed already exists", code: 0)
        }
        
        // Create feed with temporary title
        let feed = RSSFeed(
            url: url,
            title: "Loading...",
            nickname: nickname,
            enableNotifications: enableNotifications
        )
        if let refreshInterval = refreshInterval {
            feed.customRefreshInterval = refreshInterval
        }
        feed.category = category
        modelContext.insert(feed)
        try modelContext.save()
        
        // Fetch feed to get real title and items
        do {
            let result = try await rssService.fetchFeed(url: url)
            feed.title = result.title
            
            // Add initial items
            for itemData in result.items.prefix(50) {
                let item = FeedItem(
                    title: itemData.title,
                    link: itemData.link,
                    itemDescription: itemData.description,
                    imageURL: itemData.imageURL,
                    publishedDate: itemData.publishedDate
                )
                item.feed = feed
                modelContext.insert(item)
            }
            
            try modelContext.save()
        } catch {
            throw error
        }
    }
}
