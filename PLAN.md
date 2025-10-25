# Risible - RSS Feed Reader Implementation Plan

## Architecture Overview

**Data Layer**: SwiftData models for local persistence (easily swappable for backend later)

**State Management**: @Observable view models with @Environment for app-wide state

**UI Structure**: TabView with 3 tabs (Feed, Discover, Settings)

## 1. Data Models & Storage

Create SwiftData models in `Models/` directory:

**Category.swift**

- id, name, color, sortOrder
- Relationship: hasMany RSSFeed

**RSSFeed.swift**

- id, url, title, nickname (optional), customRefreshInterval (optional)
- Relationship: belongsTo Category, hasMany FeedItem

**FeedItem.swift**

- id, title, link, description, imageURL, publishedDate
- Relationship: belongsTo RSSFeed
- Computed property: isNew (compare publishedDate with UserDefaults lastOpenedDate)

**AppSettings.swift** (UserDefaults wrapper)

- lastOpenedDate
- defaultRefreshInterval

## 2. Services Layer

Create protocol-based services in `Services/` for easy backend swap:

**RSSService.swift**

- Protocol: `RSSServiceProtocol`
- Implementation: `LocalRSSService` (uses XMLParser for RSS/Atom feeds)
- Methods: `fetchFeed(url:)` returns array of FeedItem
- Design for future `RemoteRSSService` implementation

**CuratedFeedsService.swift**

- Protocol: `CuratedFeedsServiceProtocol`
- Implementation: `LocalCuratedFeedsService` (hardcoded list)
- Returns: Array of curated feed suggestions (BBC, Semafor, etc.)
- Design for future backend fetch

## 3. View Models

**FeedViewModel.swift** (@Observable)

- Selected category (binding for horizontal scroll)
- Fetch feed items for category
- Pull-to-refresh logic
- Track loading states

**DiscoverViewModel.swift** (@Observable)

- Load curated feeds
- Preview feed items for exploration
- Add feed to category logic

**SettingsViewModel.swift** (@Observable)

- Category CRUD operations
- Feed management within categories
- Color picker for categories

## 4. Main UI Structure

**RisibleApp.swift**

- Set up SwiftData container
- Initialize app-wide environment objects
- Track app lifecycle for lastOpenedDate

**MainTabView.swift**

- TabView with 3 tabs
- Custom tab bar styling (modern iOS design)

## 5. Feed Tab Implementation

**FeedView.swift**

- Top: Horizontal scrolling category pills (similar to TikTok FYP)
- "All" shows combined feed from all categories
- TabView with .tabViewStyle(.page) for swipeable categories
- Pull-to-refresh with refreshable modifier

**CategoryFeedView.swift**

- LazyVStack of feed items for single category
- Only show latest ~50 items per feed
- Badge for "new" items (since lastOpenedDate)

**FeedItemCard.swift**

- AsyncImage for OG image with placeholder
- Title, source, publish date
- Visual "new" indicator
- Tap gesture opens web view

**ArticleWebView.swift**

- Sheet presentation with .presentationDetents([.medium, .large])
- SFSafariViewController wrapped in UIViewControllerRepresentable
- Top bar with X button, share button, open in Safari button
- Telegram-style dismissible drawer

## 6. Discover Tab Implementation

**DiscoverView.swift**

- Scrollable list of curated feed sources
- Beautiful card design for each source

**CuratedFeedCard.swift**

- Source name, description, icon/logo
- Tap opens preview

**FeedPreviewSheet.swift**

- Show latest stories from feed
- - button in top corner
- Category picker sheet
- Add to selected category

## 7. Settings Tab Implementation

**SettingsView.swift**

- Section: Categories management
- Section: App preferences
- Clean iOS Settings app style

**CategorySettingsRow.swift**

- Category name, color indicator
- Tap to edit
- Swipe to delete

**CategoryEditView.swift**

- Edit name, color picker
- List of RSS feeds in category
- Add new feed button
- Edit feed (nickname, custom interval)

**FeedEditView.swift**

- Feed URL (not editable after creation)
- Nickname override
- Custom refresh interval
- Delete feed option

## 8. Shared Components

**Components/ColorPicker.swift**

- Preset color palette (iOS system colors)
- Custom color picker

**Components/LoadingView.swift**

- Reusable loading indicator

**Extensions/Color+Hex.swift**

- Store colors as hex in SwiftData

**Extensions/Date+Relative.swift**

- "2h ago", "1d ago" formatting

## File Structure

```
risible/
├── RisibleApp.swift
├── Models/
│   ├── Category.swift
│   ├── RSSFeed.swift
│   ├── FeedItem.swift
│   └── AppSettings.swift
├── Services/
│   ├── RSSService.swift
│   └── CuratedFeedsService.swift
├── ViewModels/
│   ├── FeedViewModel.swift
│   ├── DiscoverViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Feed/
│   │   ├── FeedView.swift
│   │   ├── CategoryFeedView.swift
│   │   ├── FeedItemCard.swift
│   │   └── ArticleWebView.swift
│   ├── Discover/
│   │   ├── DiscoverView.swift
│   │   ├── CuratedFeedCard.swift
│   │   └── FeedPreviewSheet.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── CategorySettingsRow.swift
│       ├── CategoryEditView.swift
│       └── FeedEditView.swift
├── Components/
│   ├── ColorPicker.swift
│   └── LoadingView.swift
└── Extensions/
    ├── Color+Hex.swift
    └── Date+Relative.swift
```

## Implementation Notes

- Use AsyncImage with placeholder for feed images
- Implement proper error handling for network failures
- Keep last 50-100 items per feed (auto-cleanup old items)
- Store lastOpenedDate in UserDefaults on app foreground
- RSS parsing supports both RSS 2.0 and Atom formats
- All services use protocols for easy backend swap later
- Modern iOS design with SF Symbols, system colors, smooth animations
