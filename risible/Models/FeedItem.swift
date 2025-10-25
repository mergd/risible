//
//  FeedItem.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData

@Model
final class FeedItem {
    var id: UUID
    var title: String
    var link: String
    var itemDescription: String?
    var imageURL: String?
    var publishedDate: Date
    
    @Relationship(deleteRule: .nullify)
    var feed: RSSFeed?
    
    init(
        id: UUID = UUID(),
        title: String,
        link: String,
        itemDescription: String? = nil,
        imageURL: String? = nil,
        publishedDate: Date
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.itemDescription = itemDescription
        self.imageURL = imageURL
        self.publishedDate = publishedDate
    }
    
    var isNew: Bool {
        guard let lastOpenedDate = AppSettings.shared.lastOpenedDate else {
            return true
        }
        return publishedDate > lastOpenedDate
    }
}
