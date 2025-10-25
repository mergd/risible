//
//  CuratedFeedsService.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation

// MARK: - Protocol

protocol CuratedFeedsServiceProtocol {
    func fetchCuratedFeeds() async -> [CuratedFeed]
}

// MARK: - Model

struct CuratedFeed: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let url: String
    let iconName: String // SF Symbol name
}

// MARK: - Local Implementation

final class LocalCuratedFeedsService: CuratedFeedsServiceProtocol {
    
    func fetchCuratedFeeds() async -> [CuratedFeed] {
        // Simulating async fetch
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return [
            CuratedFeed(
                name: "BBC News",
                description: "World news from the BBC",
                url: "http://feeds.bbci.co.uk/news/rss.xml",
                iconName: "globe"
            ),
            CuratedFeed(
                name: "Semafor",
                description: "Global news with diverse perspectives",
                url: "https://www.semafor.com/rss",
                iconName: "newspaper"
            ),
            CuratedFeed(
                name: "TechCrunch",
                description: "Technology news and analysis",
                url: "https://techcrunch.com/feed/",
                iconName: "laptopcomputer"
            ),
            CuratedFeed(
                name: "The Verge",
                description: "Technology, science, and culture",
                url: "https://www.theverge.com/rss/index.xml",
                iconName: "iphone"
            ),
            CuratedFeed(
                name: "Hacker News",
                description: "Tech news and discussions",
                url: "https://hnrss.org/frontpage",
                iconName: "terminal"
            ),
            CuratedFeed(
                name: "NASA",
                description: "Space exploration news",
                url: "https://www.nasa.gov/rss/dyn/breaking_news.rss",
                iconName: "moon.stars"
            ),
            CuratedFeed(
                name: "The Guardian",
                description: "International news and opinion",
                url: "https://www.theguardian.com/world/rss",
                iconName: "newspaper.fill"
            ),
            CuratedFeed(
                name: "Wired",
                description: "Tech, science, and culture insights",
                url: "https://www.wired.com/feed/rss",
                iconName: "bolt.fill"
            ),
            CuratedFeed(
                name: "Ars Technica",
                description: "In-depth tech analysis",
                url: "https://feeds.arstechnica.com/arstechnica/index",
                iconName: "cpu"
            ),
            CuratedFeed(
                name: "NPR News",
                description: "U.S. and world news",
                url: "https://feeds.npr.org/1001/rss.xml",
                iconName: "radio"
            ),
            CuratedFeed(
                name: "MIT Technology Review",
                description: "Emerging technology insights",
                url: "https://www.technologyreview.com/feed/",
                iconName: "lightbulb.fill"
            ),
            CuratedFeed(
                name: "The Atlantic",
                description: "Politics, culture, and ideas",
                url: "https://www.theatlantic.com/feed/all/",
                iconName: "book.fill"
            )
        ]
    }
}
