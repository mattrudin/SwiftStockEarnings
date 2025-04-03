import Testing
import Foundation
@testable import SwiftStockEarnings

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

@Test func testLiveAAPLEarningsData() async throws {
    let earningsData = try await SwiftStockEarnings.fetchEarningsData(for: "AAPL")
    
    // Verify that we got valid data
    #expect(earningsData.date > Date()) // Date should be in the future
    #expect(earningsData.projectedEarningsWindowStart <= earningsData.date) // Window start should be before or on earnings date
    #expect(earningsData.projectedEarningsWindowEnd >= earningsData.date) // Window end should be after or on earnings date
    #expect(earningsData.marketTiming == .afterMarket) // AAPL typically reports after market
    
    // Print the results for manual verification
    print("AAPL Earnings Data:")
    print("Date: \(earningsData.date)")
    print("Market Timing: \(earningsData.marketTiming)")
    print("Window: \(earningsData.projectedEarningsWindowStart) - \(earningsData.projectedEarningsWindowEnd)")
}
