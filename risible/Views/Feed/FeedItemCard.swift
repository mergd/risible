//
//  FeedItemCard.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI

struct FeedItemCard: View {
    let item: FeedItem
    @Binding var hiddenItemURLs: Set<String>
    @State private var showArticle = false
    @Environment(\.colorScheme) private var colorScheme
    
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
            showArticle = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                if let imageURLString = item.imageURL,
                   let imageURL = URL(string: imageURLString) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(systemGray6)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(systemGray6)
                                .overlay {
                                    Image(systemName: "photo.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.tertiary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 220)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        if item.isNew {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                        }
                        
                        HStack(spacing: 4) {
                            Text(item.feed?.displayName ?? "Unknown")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            
                            if item.feed?.isPaused == true {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Text(item.publishedDate.relativeTimeString())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text(item.title)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let description = item.itemDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(16)
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? systemGray6.opacity(0.5) : .white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(systemGray5.opacity(0.5), lineWidth: 0.5)
            }
        }
        .buttonStyle(FeedCardButtonStyle())
        .onLongPressGesture {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            withAnimation(.easeInOut(duration: 0.2)) {
                hiddenItemURLs.insert(item.link)
            }
        }
        .sheet(isPresented: $showArticle) {
            ArticleWebView(url: item.link, title: item.title)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.isNew ? "New article. " : "")\(item.title)")
        .accessibilityHint("Double tap to read article")
        .accessibilityAddTraits(.isButton)
    }
}

struct FeedCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    FeedItemCard(
        item: FeedItem(
            title: "Sample Article Title Goes Here",
            link: "https://example.com",
            itemDescription: "This is a sample description for the article that provides some context about what the article contains.",
            imageURL: nil,
            publishedDate: Date().addingTimeInterval(-3600)
        ),
        hiddenItemURLs: .constant(Set())
    )
    .padding()
}
