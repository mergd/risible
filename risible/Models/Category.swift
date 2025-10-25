//
//  Category.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade, inverse: \RSSFeed.category)
    var feeds: [RSSFeed] = []
    
    init(id: UUID = UUID(), name: String, colorHex: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
