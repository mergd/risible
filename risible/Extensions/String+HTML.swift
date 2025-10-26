import Foundation

extension String {
    func decodingHTMLEntities() -> String {
        var result = self
        
        let entities: [String: String] = [
            "&quot;": "\"",
            "&apos;": "'",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&nbsp;": " ",
            "&#8220;": "\"",
            "&#8221;": "\"",
            "&#8216;": "'",
            "&#8217;": "'",
            "&#8212;": "—",
            "&#8211;": "–",
            "&#8230;": "…",
            "&#8209;": "‐",
            "&#174;": "®",
            "&#169;": "©",
            "&#8482;": "™",
            "&#160;": " ",
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result
    }
}
