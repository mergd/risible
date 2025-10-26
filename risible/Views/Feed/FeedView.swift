//
//  FeedView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    @State private var viewModel = FeedViewModel()
    @State private var selectedCategoryIndex = 0
    @State private var showAddFeedSheet = false
    @State private var selectedCategory: Category?
    @State private var hiddenItemURLs: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                CategoryPill(
                                    title: "All",
                                    color: .blue,
                                    isSelected: selectedCategoryIndex == 0
                                ) {
                                    #if os(iOS)
                                    let selectionFeedback = UISelectionFeedbackGenerator()
                                    selectionFeedback.selectionChanged()
                                    #endif
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCategoryIndex = 0
                                    }
                                }
                                .id(0)
                                
                                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                                    CategoryPill(
                                        title: category.name,
                                        color: category.color,
                                        isSelected: selectedCategoryIndex == index + 1
                                    ) {
                                        #if os(iOS)
                                        let selectionFeedback = UISelectionFeedbackGenerator()
                                        selectionFeedback.selectionChanged()
                                        #endif
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategoryIndex = index + 1
                                        }
                                    }
                                    .id(index + 1)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: selectedCategoryIndex) { _, newValue in
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    
                    Button {
                        if selectedCategoryIndex == 0 {
                            selectedCategory = categories.first ?? createDefaultCategory()
                        } else {
                            selectedCategory = categories[safe: selectedCategoryIndex - 1]
                        }
                        showAddFeedSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(.blue)
                    .padding(.trailing, 16)
                }
                .background(.ultraThinMaterial)
                
                TabView(selection: $selectedCategoryIndex) {
                    CategoryFeedView(category: nil, viewModel: viewModel)
                        .tag(0)
                    
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryFeedView(category: category, viewModel: viewModel)
                            .tag(index + 1)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #else
                .tabViewStyle(.automatic)
                #endif
            }
            .navigationTitle("Risible")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showAddFeedSheet) {
                if let category = selectedCategory {
                    AddFeedSheet(category: category)
                }
            }
        }
    }
    
    private func createDefaultCategory() -> Category {
        let defaultCategory = Category(name: "Uncategorized", colorHex: "#999999")
        modelContext.insert(defaultCategory)
        return defaultCategory
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

struct CategoryPill: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.12))
                }
                .overlay {
                    if !isSelected {
                        Capsule()
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(CategoryPillButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel("\(title) category")
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
    }
}

struct CategoryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    FeedView()
        .modelContainer(for: [Category.self, RSSFeed.self, FeedItem.self], inMemory: true)
}
