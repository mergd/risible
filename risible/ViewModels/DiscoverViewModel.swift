//
//  DiscoverViewModel.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData

@Observable
final class DiscoverViewModel {
    var curatedFeeds: [CuratedFeed] = []
    var isLoading = false
    var previewFeed: CuratedFeed?
    var previewItems: [RSSItemData] = []
    var isLoadingPreview = false
    
    private let curatedService: CuratedFeedsServiceProtocol
    private let rssService: RSSServiceProtocol
    
    init(
        curatedService: CuratedFeedsServiceProtocol = LocalCuratedFeedsService(),
        rssService: RSSServiceProtocol = LocalRSSService()
    ) {
        self.curatedService = curatedService
        self.rssService = rssService
    }
    
    func loadCuratedFeeds() async {
        isLoading = true
        curatedFeeds = await curatedService.fetchCuratedFeeds()
        isLoading = false
    }
    
    func loadPreview(for feed: CuratedFeed) async {
        previewFeed = feed
        isLoadingPreview = true
        previewItems = []
        
        do {
            let result = try await rssService.fetchFeed(url: feed.url)
            previewItems = Array(result.items.prefix(10))
        } catch {
            print("Error loading preview: \(error)")
        }
        
        isLoadingPreview = false
    }
    
    func addFeed(_ curatedFeed: CuratedFeed, to category: Category, modelContext: ModelContext) async throws {
        // First, fetch the feed to get its title
        let result = try await rssService.fetchFeed(url: curatedFeed.url)
        
        // Check if feed already exists
        let feedURL = curatedFeed.url
        let descriptor = FetchDescriptor<RSSFeed>(
            predicate: #Predicate<RSSFeed> { feed in
                feed.url == feedURL
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        
        if existing.isEmpty {
            let newFeed = RSSFeed(url: curatedFeed.url, title: result.title)
            newFeed.category = category
            modelContext.insert(newFeed)
            
            // Add initial items
            for itemData in result.items.prefix(50) {
                let newItem = FeedItem(
                    title: itemData.title,
                    link: itemData.link,
                    itemDescription: itemData.description,
                    imageURL: itemData.imageURL,
                    publishedDate: itemData.publishedDate
                )
                newItem.feed = newFeed
                modelContext.insert(newItem)
            }
            
            try modelContext.save()
        }
    }
}
