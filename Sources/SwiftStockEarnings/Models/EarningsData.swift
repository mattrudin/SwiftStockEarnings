import Foundation

public enum MarketTiming {
    case beforeMarket
    case afterMarket
    case unknown
}

public struct EarningsData {
    public let date: Date
    public let marketTiming: MarketTiming
    public let projectedEarningsWindowStart: Date
    public let projectedEarningsWindowEnd: Date
    
    public init(
        date: Date,
        marketTiming: MarketTiming,
        projectedEarningsWindowStart: Date,
        projectedEarningsWindowEnd: Date
    ) {
        self.date = date
        self.marketTiming = marketTiming
        self.projectedEarningsWindowStart = projectedEarningsWindowStart
        self.projectedEarningsWindowEnd = projectedEarningsWindowEnd
    }
}

public enum EarningsError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noDataFound
} 