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
            guard let dateText = try? doc.select("td:contains(Next Earnings Date:)").first()?.text(),
                  let dateMatch = dateText.range(of: "\\w+ \\d{1,2}, \\d{4}", options: .regularExpression) else {
                return nil
            }
            
            let dateStr = String(dateText[dateMatch])
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            // Create date at noon in local timezone
            if let date = dateFormatter.date(from: dateStr) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                components.hour = 12
                components.minute = 0
                components.second = 0
                return Calendar.current.date(from: components)
            }
            return nil
        }()
        
        // Parse projected window
        let (windowStart, windowEnd): (Date?, Date?) = {
            guard let windowText = try? doc.select("td:contains(OS Projected Window:)").first()?.text(),
                  let windowMatch = windowText.range(of: "OS Projected Window: \\w+ \\d{1,2}, \\d{4} to \\w+ \\d{1,2}, \\d{4}", options: .regularExpression) else {
                return (nil, nil)
            }
            
            let windowStr = String(windowText[windowMatch])
            let windowComponents = windowStr.components(separatedBy: " to ")
            guard windowComponents.count == 2,
                  let startStr = windowComponents[0].components(separatedBy: "OS Projected Window: ").last else {
                return (nil, nil)
            }
            
            let endStr = windowComponents[1]
            let windowFormatter = DateFormatter()
            windowFormatter.dateFormat = "MMMM d, yyyy"
            windowFormatter.timeZone = TimeZone.current
            windowFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            // Create dates at noon in local timezone
            let createLocalDate: (String) -> Date? = { dateStr in
                if let date = windowFormatter.date(from: dateStr) {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    components.second = 0
                    return Calendar.current.date(from: components)
                }
                return nil
            }
            
            return (
                createLocalDate(startStr),
                createLocalDate(endStr)
            )
        }()
        
        // Determine market timing
        let marketTiming: MarketTiming = {
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
            return .unknown
        }()
        
        return EarningsData(
            date: date,
            marketTiming: marketTiming,
            projectedEarningsWindowStart: windowStart,
            projectedEarningsWindowEnd: windowEnd
        )
    }
}
