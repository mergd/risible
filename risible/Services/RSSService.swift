//
//  RSSService.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation

// MARK: - Protocol

protocol RSSServiceProtocol {
    func fetchFeed(url: String) async throws -> RSSFeedResult
}

// MARK: - Result Types

struct RSSFeedResult {
    let title: String
    let items: [RSSItemData]
}

struct RSSItemData {
    let title: String
    let link: String
    let description: String?
    let imageURL: String?
    let publishedDate: Date
}

// MARK: - Errors

enum RSSServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError
    case noData
    case timeout
    case noConnection
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid feed URL"
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    return "Feed request timed out - server took too long to respond"
                case .notConnectedToInternet:
                    return "No internet connection"
                case .cancelled:
                    return "Feed request was cancelled"
                case .badURL, .unsupportedURL:
                    return "Invalid feed URL"
                case .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
                    return "Server security certificate is invalid"
                default:
                    return "Network error: \(urlError.localizedDescription)"
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Unable to parse feed - the feed format may not be supported"
        case .noData:
            return "No data received from server"
        case .timeout:
            return "Feed request timed out"
        case .noConnection:
            return "No internet connection available"
        case .cancelled:
            return "Feed request was cancelled"
        }
    }
}

// MARK: - Local Implementation

final class LocalRSSService: NSObject, RSSServiceProtocol {
    private let urlSession: URLSession
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)
        super.init()
    }
    
    func fetchFeed(url: String) async throws -> RSSFeedResult {
        guard let feedURL = URL(string: url) else {
            throw RSSServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await urlSession.data(from: feedURL)
            guard !data.isEmpty else {
                throw RSSServiceError.noData
            }
            return try await parseFeed(data: data)
        } catch let error as URLError {
            switch error.code {
            case .cancelled:
                throw RSSServiceError.cancelled
            case .timedOut:
                throw RSSServiceError.timeout
            case .notConnectedToInternet:
                throw RSSServiceError.noConnection
            default:
                throw RSSServiceError.networkError(error)
            }
        } catch {
            throw RSSServiceError.networkError(error)
        }
    }
    
    private func parseFeed(data: Data) async throws -> RSSFeedResult {
        return try await withCheckedThrowingContinuation { continuation in
            let parser = RSSParser()
            parser.parse(data: data) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - RSS Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private var feedTitle: String = ""
    private var items: [RSSItemData] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentImageURL: String?
    private var currentPubDate = ""
    
    private var isParsingItem = false
    private var completion: ((Result<RSSFeedResult, Error>) -> Void)?
    
    func parse(data: Data, completion: @escaping (Result<RSSFeedResult, Error>) -> Void) {
        self.completion = completion
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            let result = RSSFeedResult(title: feedTitle.decodingHTMLEntities(), items: items)
            #if DEBUG
            print("✅ RSS Parse Success - Feed: \(feedTitle), Items: \(items.count)")
            if !items.isEmpty {
                print("   First item: \(items[0].title)")
                print("   First item link: \(items[0].link)")
            }
            #endif
            completion(.success(result))
        } else {
            completion(.failure(RSSServiceError.parsingError))
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" || elementName == "entry" {
            isParsingItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentImageURL = nil
            currentPubDate = ""
        }
        
        // Handle various image tags
        if isParsingItem {
            // Media RSS
            if elementName == "media:content" || elementName == "media:thumbnail" {
                currentImageURL = attributeDict["url"]
            }
            // Enclosure
            if elementName == "enclosure", attributeDict["type"]?.starts(with: "image/") == true {
                currentImageURL = attributeDict["url"]
            }
        }
        
        // Atom link
        if elementName == "link", isParsingItem {
            if let href = attributeDict["href"] {
                currentLink = href
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if isParsingItem {
            switch currentElement {
            case "title":
                currentTitle += trimmed
            case "link":
                if currentLink.isEmpty { // RSS style link
                    currentLink += trimmed
                }
            case "description", "summary", "content:encoded", "content":
                currentDescription += trimmed
            case "pubDate", "published", "updated":
                currentPubDate += trimmed
            case "media:thumbnail", "media:content":
                break // Already handled in attributes
            default:
                break
            }
        } else {
            if currentElement == "title" {
                feedTitle += trimmed
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            isParsingItem = false
            
            // Create item
            if !currentTitle.isEmpty && !currentLink.isEmpty {
                let date = parseDate(from: currentPubDate) ?? Date()
                let item = RSSItemData(
                    title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines).decodingHTMLEntities(),
                    link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: currentDescription.isEmpty ? nil : currentDescription.trimmingCharacters(in: .whitespacesAndNewlines).stripHTMLTags(),
                    imageURL: currentImageURL,
                    publishedDate: date
                )
                items.append(item)
                #if DEBUG
                print("   📰 Added item: \(item.title) → \(item.link)")
                #endif
            } else {
                #if DEBUG
                if currentTitle.isEmpty || currentLink.isEmpty {
                    print("   ⚠️ Skipped item - Title: \(!currentTitle.isEmpty), Link: \(!currentLink.isEmpty)")
                }
                #endif
            }
        }
    }
    
    private func parseDate(from string: String) -> Date? {
        let formatters: [DateFormatter] = {
            let rfc822 = DateFormatter()
            rfc822.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            rfc822.locale = Locale(identifier: "en_US_POSIX")
            
            return [rfc822]
        }()
        
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - String Extension

extension String {
    func stripHTMLTags() -> String {
        var result = self
        
        // Remove script and style tags with their content
        result = result.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
        result = result.replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove all HTML tags
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML entities
        result = result.decodingHTMLEntities()
        
        // Clean up whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with single space
        result = result.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        
        return result
    }
}
