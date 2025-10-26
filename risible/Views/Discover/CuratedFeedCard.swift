//
//  CuratedFeedCard.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct CuratedFeedCard: View {
    let feed: CuratedFeed
    let viewModel: DiscoverViewModel
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var addedFeeds: [RSSFeed]
    
    init(feed: CuratedFeed, viewModel: DiscoverViewModel, action: @escaping () -> Void) {
        self.feed = feed
        self.viewModel = viewModel
        self.action = action
        
        let feedURL = feed.url
        let descriptor = FetchDescriptor<RSSFeed>(
            predicate: #Predicate<RSSFeed> { rssFeed in
                rssFeed.url == feedURL
            }
        )
        _addedFeeds = Query(descriptor)
    }
    
    private var isFeedAdded: Bool {
        !addedFeeds.isEmpty
    }
    
    private var trailingIconName: String {
        isFeedAdded ? "checkmark.circle.fill" : "chevron.right"
    }
    
    private var trailingIconSize: CGFloat {
        isFeedAdded ? 16 : 13
    }
    
    private var trailingIconColor: Color {
        isFeedAdded ? .green : .secondary
    }
    
    private var accessibilityHint: String {
        isFeedAdded ? "Already added" : "Double tap to preview this feed"
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? systemGray6.opacity(0.5) : .white
    }
    
    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.06
    }
    
    private var iconColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo, .teal]
        let hash = feed.name.hash
        return colors[abs(hash) % colors.count]
    }
    
    private var systemGray6: Color {
        #if os(iOS)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .systemGray6)
        #endif
    }
    
    private var systemGray5: Color {
        #if os(iOS)
        Color(uiColor: .systemGray5)
        #else
        Color(nsColor: .systemGray5)
        #endif
    }
    
    var body: some View {
        Button {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            action()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconColor.gradient)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: feed.iconName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(feed.name)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(feed.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 12)
                
                Image(systemName: trailingIconName)
                    .font(.system(size: trailingIconSize, weight: .semibold))
                    .foregroundStyle(trailingIconColor)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(shadowOpacity), radius: 8, x: 0, y: 3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(systemGray5.opacity(0.5), lineWidth: 0.5)
            }
        }
        .buttonStyle(DiscoverCardButtonStyle())
        .disabled(isFeedAdded)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feed.name). \(feed.description)")
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
}

struct DiscoverCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    CuratedFeedCard(
        feed: CuratedFeed(
            name: "TechCrunch",
            description: "Technology news and analysis",
            url: "https://techcrunch.com/feed/",
            iconName: "laptopcomputer"
        ),
        viewModel: DiscoverViewModel(),
        action: {}
    )
    .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
    .padding()
}
