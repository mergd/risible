//
//  ArticleWebView.swift
//  risible
//
//  Created by William on 10/25/25.
//

import SwiftUI
import WebKit

struct ArticleWebView: View {
    let url: String
    let title: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if let articleURL = URL(string: url) {
                        ShareLink(item: articleURL) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.accentColor)
                        }
                        .labelStyle(.iconOnly)
                        
                        Link(destination: articleURL) {
                            Image(systemName: "safari")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
            .borderTop()
            
            if let articleURL = URL(string: url) {
                WebViewRepresentable(url: articleURL)
                    .cornerRadius(12)
                    .padding(12)
                    .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Invalid URL",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Unable to load article")
                )
            }
        }
        .navigationBarHidden(true)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.preferredContentMode = .mobile
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.userContentController.addUserScript(injectionScript())
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func injectionScript() -> WKUserScript {
        let css = """
        * {
            box-sizing: border-box;
        }
        body {
            margin: 0;
            padding: 16px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            line-height: 1.6;
        }
        img {
            display: block !important;
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
            margin: 12px 0 !important;
            border-radius: 8px !important;
            -webkit-user-select: none !important;
            pointer-events: auto !important;
        }
        img[src*="og-image"],
        img[property="og:image"] {
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
        }
        picture {
            display: block !important;
            max-width: 100% !important;
        }
        picture img {
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
        }
        figure {
            margin: 12px 0 !important;
            padding: 0 !important;
            width: 100% !important;
            max-width: 100% !important;
        }
        figure img {
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
        }
        a > img {
            display: block !important;
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
        }
        h1, h2.entry-title, h2.post-title, [data-testid="article-title"] {
            display: none !important;
        }
        article, main, .article-content, .post-content {
            max-width: 100% !important;
            width: 100% !important;
        }
        """
        
        let jsCode = """
        var style = document.createElement('style');
        style.textContent = `\(css)`;
        document.head.appendChild(style);
        
        document.addEventListener('DOMContentLoaded', function() {
            var images = document.querySelectorAll('img');
            images.forEach(function(img) {
                img.style.width = '100%';
                img.style.maxWidth = '100%';
                img.style.height = 'auto';
                img.style.display = 'block';
                img.style.margin = '12px 0';
                img.style.borderRadius = '8px';
            });
        });
        """
        
        return WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

extension View {
    func borderTop() -> some View {
        self.overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview {
    ArticleWebView(url: "https://www.apple.com", title: "Apple")
}
