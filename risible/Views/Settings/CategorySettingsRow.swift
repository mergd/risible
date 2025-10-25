//
//  CategorySettingsRow.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI

struct CategorySettingsRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)
                
                Text("\(category.feeds.count) feed\(category.feeds.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List {
        CategorySettingsRow(
            category: Category(name: "Technology", colorHex: "#007AFF")
        )
    }
}
