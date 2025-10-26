//
//  DiscoverView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var showPreview = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.curatedFeeds.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading feeds...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.curatedFeeds.isEmpty {
                    ContentUnavailableView {
                        Label("No Feeds Available", systemImage: "safari")
                    } description: {
                        Text("Check back later for curated feeds")
                    }
                } else {
                    #if os(iOS)
                    ScrollView {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popular Feeds")
                                    .font(.title2.weight(.bold))
                                Text("Discover high-quality RSS feeds from trusted sources")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.curatedFeeds) { feed in
                                    CuratedFeedCard(feed: feed, viewModel: viewModel) {
                                        Task {
                                            await viewModel.loadPreview(for: feed)
                                            showPreview = true
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable {
                        await viewModel.loadCuratedFeeds()
                    }
                    #else
                    ScrollView {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popular Feeds")
                                    .font(.title2.weight(.bold))
                                Text("Discover high-quality RSS feeds from trusted sources")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.curatedFeeds) { feed in
                                    CuratedFeedCard(feed: feed, viewModel: viewModel) {
                                        Task {
                                            await viewModel.loadPreview(for: feed)
                                            showPreview = true
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("Discover")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                if viewModel.curatedFeeds.isEmpty {
                    await viewModel.loadCuratedFeeds()
                }
            }
            .sheet(isPresented: $showPreview) {
                if let feed = viewModel.previewFeed {
                    FeedPreviewSheet(
                        feed: feed,
                        items: viewModel.previewItems,
                        isLoading: viewModel.isLoadingPreview,
                        viewModel: viewModel
                    )
                }
            }
        }
    }
}

#Preview {
    let schema = Schema([Category.self, RSSFeed.self, FeedItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    DiscoverView()
        .modelContainer(container)
}
