#!/usr/bin/env swift
import Foundation

// Fetch and parse HN RSS feed
let hnURL = "https://hnrss.org/frontpage"

if let url = URL(string: hnURL) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ Network error: \(error)")
            exit(1)
        }
        
        guard let data = data, !data.isEmpty else {
            print("❌ No data received")
            exit(1)
        }
        
        // Parse XML
        let parser = XMLParser(data: data)
        var itemCount = 0
        var currentElement = ""
        var currentTitle = ""
        var currentLink = ""
        
        parser.delegate = XMLParserDelegateImpl()
        
        if parser.parse() {
            print("✅ XML parsing succeeded")
        } else {
            print("❌ XML parsing failed: \(parser.parserError?.localizedDescription ?? "Unknown error")")
            exit(1)
        }
    }
    
    task.resume()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))
} else {
    print("❌ Invalid URL")
    exit(1)
}

class XMLParserDelegateImpl: NSObject, XMLParserDelegate {
    var itemCount = 0
    var currentElement = ""
    var currentTitle = ""
    var currentLink = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            itemCount += 1
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if currentElement == "title" {
            currentTitle += trimmed
        } else if currentElement == "link" {
            currentLink += trimmed
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if !currentTitle.isEmpty {
                print("   📰 Item: \(currentTitle) → \(currentLink)")
            }
            currentTitle = ""
            currentLink = ""
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Total items found: \(itemCount)")
    }
}

