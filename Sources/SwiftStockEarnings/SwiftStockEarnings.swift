// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftSoup

public struct SwiftStockEarnings {
    private let networkClient: EarningsNetworkClient
    
    public init(networkClient: EarningsNetworkClient = DefaultEarningsNetworkClient()) {
        self.networkClient = networkClient
    }
    
    public func fetchEarningsData(for symbol: String) async -> EarningsData {
        do {
            let html = try await networkClient.fetchHTML(for: symbol)
            let doc = try SwiftSoup.parse(html)
            return parseEarningsData(from: doc)
        } catch {
            return EarningsData()
        }
    }
    
    private func parseEarningsData(from doc: Document) -> EarningsData {
        // Parse earnings date
        let date: Date? = {
            guard let dateText = try? doc.select("td:contains(Next Earnings Date:)").first()?.text() else {
                return nil
            }
            
            // Prefer date after 'OS Estimate:' if present
            let osEstimatePattern = #"OS Estimate:\s*([A-Za-z]{3,}\.? \d{1,2}, \d{4})"#
            if let osEstimateMatch = dateText.range(of: osEstimatePattern, options: .regularExpression) {
                let matchStr = String(dateText[osEstimateMatch])
                if let dateMatch = matchStr.range(of: #"[A-Za-z]{3,}\.? \d{1,2}, \d{4}"#, options: .regularExpression) {
                    var dateStr = String(matchStr[dateMatch])
                    // Fix: Ersetze 'Sept.' durch 'Sep.' für DateFormatter-Kompatibilität
                    dateStr = dateStr.replacingOccurrences(of: "Sept.", with: "Sep.")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM. d, yyyy"
                    dateFormatter.timeZone = TimeZone.current
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    // Try abbreviated month first
                    if let date = dateFormatter.date(from: dateStr) {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        components.hour = 12
                        components.minute = 0
                        components.second = 0
                        return Calendar.current.date(from: components)
                    } else {
                        // Try full month name
                        dateFormatter.dateFormat = "MMMM d, yyyy"
                        if let date = dateFormatter.date(from: dateStr) {
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                            components.hour = 12
                            components.minute = 0
                            components.second = 0
                            return Calendar.current.date(from: components)
                        }
                    }
                }
            }
            // Fallback: first date in string (abbreviated or full month)
            if let dateMatch = dateText.range(of: #"[A-Za-z]{3,}\.? \d{1,2}, \d{4}"#, options: .regularExpression) {
                var dateStr = String(dateText[dateMatch])
                // Fix: Ersetze 'Sept.' durch 'Sep.' für DateFormatter-Kompatibilität
                dateStr = dateStr.replacingOccurrences(of: "Sept.", with: "Sep.")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM. d, yyyy"
                dateFormatter.timeZone = TimeZone.current
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = dateFormatter.date(from: dateStr) {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    components.second = 0
                    return Calendar.current.date(from: components)
                } else {
                    dateFormatter.dateFormat = "MMMM d, yyyy"
                    if let date = dateFormatter.date(from: dateStr) {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        components.hour = 12
                        components.minute = 0
                        components.second = 0
                        return Calendar.current.date(from: components)
                    }
                }
            }
            return nil
        }()
        
        // Parse projected window
        let (windowStart, windowEnd): (Date?, Date?) = {
            guard let windowText = try? doc.select("td:contains(OS Projected Window:)").first()?.text() else {
                return (nil, nil)
            }
            // Updated regex to support abbreviated and full month names
            let windowPattern = #"OS Projected Window: ([A-Za-z]{3,}\.? \d{1,2}, \d{4}) to ([A-Za-z]{3,}\.? \d{1,2}, \d{4})"#
            let regex = try? NSRegularExpression(pattern: windowPattern)
            if let match = regex?.firstMatch(in: windowText, options: [], range: NSRange(windowText.startIndex..., in: windowText)),
               match.numberOfRanges == 3,
               let startRange = Range(match.range(at: 1), in: windowText),
               let endRange = Range(match.range(at: 2), in: windowText) {
                let startStr = String(windowText[startRange])
                let endStr = String(windowText[endRange])
                let windowFormatter = DateFormatter()
                windowFormatter.timeZone = TimeZone.current
                windowFormatter.locale = Locale(identifier: "en_US_POSIX")
                // Helper to try both abbreviated and full month
                let createLocalDate: (String) -> Date? = { dateStr in
                    var dateStrFixed = dateStr.replacingOccurrences(of: "Sept.", with: "Sep.")
                    windowFormatter.dateFormat = "MMM. d, yyyy"
                    if let date = windowFormatter.date(from: dateStrFixed) {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        components.hour = 12
                        components.minute = 0
                        components.second = 0
                        return Calendar.current.date(from: components)
                    } else {
                        windowFormatter.dateFormat = "MMMM d, yyyy"
                        if let date = windowFormatter.date(from: dateStrFixed) {
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                            components.hour = 12
                            components.minute = 0
                            components.second = 0
                            return Calendar.current.date(from: components)
                        }
                    }
                    return nil
                }
                return (
                    createLocalDate(startStr),
                    createLocalDate(endStr)
                )
            }
            return (nil, nil)
        }()
        
        // Determine market timing
        let marketTiming: MarketTiming = {
            // 1. Versuche wie bisher über <font>-Tag zu extrahieren
            if let timingElements = try? doc.select("span.stock_title font") {
                for element in timingElements {
                    if let timingText = try? element.text().trimmingCharacters(in: .whitespacesAndNewlines) {
                        if timingText == "AC" {
                            return .afterMarket
                        } else if timingText == "BO" {
                            return .beforeMarket
                        }
                    }
                }
            }
            // 2. Fallback: Suche direkt im relevanten Text nach AC/BO
            if let dateText = try? doc.select("td:contains(Next Earnings Date:)").first()?.text() {
                let pattern = #"(AC|BO)\b"#
                if let match = dateText.range(of: pattern, options: .regularExpression) {
                    let timing = String(dateText[match])
                    if timing == "AC" {
                        return .afterMarket
                    } else if timing == "BO" {
                        return .beforeMarket
                    }
                }
            }
            return .unknown
        }()
        
        return EarningsData(
            date: date,
            marketTiming: marketTiming,
            projectedEarningsWindowStart: windowStart,
            projectedEarningsWindowEnd: windowEnd,
            isConfirmed: windowStart == nil && windowEnd == nil && date != nil
        )
    }
}
