// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftSoup

public struct SwiftStockEarnings {
    private static let baseURL = "https://www.optionslam.com/earnings/stocks/"
    
    public static func fetchEarningsData(for symbol: String) async throws -> EarningsData {
        guard let url = URL(string: baseURL + symbol) else {
            throw EarningsError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw EarningsError.parsingError("Could not decode HTML data")
        }
        
        let doc = try SwiftSoup.parse(html)
        
        // Find the earnings date - it's in the text after "Next Earnings Date:"
        let dateText = try doc.select("td:contains(Next Earnings Date:)").first()?.text() ?? ""
        let datePattern = "Estimated on ([A-Za-z]+ \\d+, \\d{4})"
        guard let dateMatch = dateText.range(of: datePattern, options: .regularExpression),
              let dateStr = dateText[dateMatch].components(separatedBy: "Estimated on ").last else {
            throw EarningsError.parsingError("Could not find earnings date")
        }
        
        // Parse the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        guard let date = dateFormatter.date(from: dateStr) else {
            throw EarningsError.parsingError("Could not parse date: \(dateStr)")
        }
        
        // Find the projected window
        let windowText = try doc.select("td:contains(OS Projected Window:)").first()?.text() ?? ""
        let windowPattern = "OS Projected Window: ([A-Za-z]+ \\d+, \\d{4}) to ([A-Za-z]+ \\d+, \\d{4})"
        guard let windowMatch = windowText.range(of: windowPattern, options: .regularExpression) else {
            throw EarningsError.parsingError("Could not find earnings window")
        }
        
        let windowStr = String(windowText[windowMatch])
        let windowComponents = windowStr.components(separatedBy: " to ")
        guard windowComponents.count == 2,
              let startStr = windowComponents[0].components(separatedBy: "OS Projected Window: ").last,
              let endStr = windowComponents[1].components(separatedBy: " ").first else {
            throw EarningsError.parsingError("Could not parse earnings window")
        }
        
        // Parse the window dates
        let windowFormatter = DateFormatter()
        windowFormatter.dateFormat = "MMMM d, yyyy"
        
        guard let startDate = windowFormatter.date(from: startStr),
              let endDate = windowFormatter.date(from: endStr) else {
            throw EarningsError.parsingError("Could not parse window dates")
        }
        
        // Determine market timing - on optionslam.com, AC means After Close (after market)
        let marketTiming: MarketTiming = {
            if let timingText = try? doc.select("td:contains(AC)").first()?.text(),
               timingText.contains("AC") {
                return .afterMarket
            }
            return .unknown
        }()
        
        return EarningsData(
            date: date,
            marketTiming: marketTiming,
            projectedEarningsWindowStart: startDate,
            projectedEarningsWindowEnd: endDate
        )
    }
}
