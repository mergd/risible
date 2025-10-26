//
//  RSSFeed.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData

@Model
final class RSSFeed {
    var id: UUID
    var url: String
    var title: String
    var nickname: String?
    var customRefreshInterval: TimeInterval?
    var enableNotifications: Bool = false
    
    @Relationship(deleteRule: .nullify)
    var category: Category?
    
    @Relationship(deleteRule: .cascade, inverse: \FeedItem.feed)
    var items: [FeedItem] = []
    
    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        nickname: String? = nil,
        customRefreshInterval: TimeInterval? = nil,
        enableNotifications: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.nickname = nickname
        self.customRefreshInterval = customRefreshInterval
        self.enableNotifications = enableNotifications
    }
    
    var displayName: String {
        nickname ?? title
    }
}
