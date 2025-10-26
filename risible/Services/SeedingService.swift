import Foundation
import SwiftData

final class SeedingService {
    static func seedDatabaseIfNeeded(modelContext: ModelContext) async {
        do {
            let categoryDescriptor = FetchDescriptor<Category>()
            let existingCategories = try modelContext.fetch(categoryDescriptor)
            
            if !existingCategories.isEmpty {
                return
            }
            
            seedCategories(modelContext: modelContext)
            await seedFeeds(modelContext: modelContext)
            
            try modelContext.save()
            
            await refreshAllFeedsAfterSeeding(modelContext: modelContext)
        } catch {
            print("Error seeding database: \(error)")
        }
    }
    
    private static func seedCategories(modelContext: ModelContext) {
        let categories = [
            Category(name: "Technology", colorHex: "#FF6B6B", sortOrder: 0),
            Category(name: "News", colorHex: "#4ECDC4", sortOrder: 1),
            Category(name: "Science", colorHex: "#45B7D1", sortOrder: 2),
            Category(name: "Design", colorHex: "#F7B731", sortOrder: 3),
        ]
        
        for category in categories {
            modelContext.insert(category)
        }
    }
    
    private static func seedFeeds(modelContext: ModelContext) async {
        let categoryDescriptor = FetchDescriptor<Category>()
        guard let categories = try? modelContext.fetch(categoryDescriptor) else { return }
        
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        
        let feeds: [(url: String, title: String, category: String)] = [
            ("https://feeds.arstechnica.com/arstechnica/index", "Ars Technica", "Technology"),
            ("https://www.theverge.com/rss/index.xml", "The Verge", "Technology"),
            ("https://feeds.bloomberg.com/markets/news.rss", "Bloomberg Markets", "News"),
            ("https://feeds.bbci.co.uk/news/rss.xml", "BBC News", "News"),
            ("https://www.nature.com/nature/current_issue/rss", "Nature", "Science"),
            ("https://feeds.arstechnica.com/arstechnica/science", "Ars Technica Science", "Science"),
            ("https://www.designernews.co/rss", "Designer News", "Design"),
            ("https://feeds.designmodo.com/designmodo/", "Design Modo", "Design"),
        ]
        
        for (url, title, categoryName) in feeds {
            if let category = categoryMap[categoryName] {
                let feed = RSSFeed(url: url, title: title)
                feed.category = category
                modelContext.insert(feed)
            }
        }
    }
    
    private static func refreshAllFeedsAfterSeeding(modelContext: ModelContext) async {
        let rssService = LocalRSSService()
        let feedDescriptor = FetchDescriptor<RSSFeed>()
        
        guard let feeds = try? modelContext.fetch(feedDescriptor) else { return }
        
        for feed in feeds {
            do {
                let result = try await rssService.fetchFeed(url: feed.url)
                
                feed.title = result.title
                
                for itemData in result.items.prefix(20) {
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
            } catch {
                print("Error refreshing feed \(feed.url) during seeding: \(error)")
            }
        }
        
        try? modelContext.save()
    }
}
