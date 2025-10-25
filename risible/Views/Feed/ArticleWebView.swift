//
//  ArticleWebView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI

#if os(iOS)
import SafariServices
#else
import WebKit
#endif

struct ArticleWebView: View {
    let url: String
    let title: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showSafari = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let articleURL = URL(string: url) {
                    SafariView(url: articleURL)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Invalid URL",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Unable to load article")
                    )
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if let articleURL = URL(string: url) {
                            ShareLink(item: articleURL) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .labelStyle(.iconOnly)
                            
                            Button {
                                UIApplication.shared.open(articleURL)
                            } label: {
                                Image(systemName: "safari")
                            }
                        }
                    }
                }
            }
            .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
            .presentationDragIndicator(.visible)
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        if let articleURL = URL(string: url) {
                            Button {
                                NSWorkspace.shared.open(articleURL)
                            } label: {
                                Label("Open in Browser", systemImage: "safari")
                            }
                            .help("Open in default browser")
                            .keyboardShortcut("o", modifiers: .command)
                            
                            ShareLink(item: articleURL) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
    }
}

// MARK: - Safari View

#if os(iOS)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor(Color.accentColor)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
#else
struct SafariView: View {
    let url: URL
    
    var body: some View {
        WebViewRepresentable(url: url)
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.preferredContentMode = .mobile
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
}
#endif

#Preview {
    ArticleWebView(url: "https://www.apple.com", title: "Apple")
}
