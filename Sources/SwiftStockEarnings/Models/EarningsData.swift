import Foundation

public enum MarketTiming {
    case beforeMarket
    case afterMarket
    case unknown
}

public struct EarningsData {
    public let date: Date?
    public let marketTiming: MarketTiming
    public let projectedEarningsWindowStart: Date?
    public let projectedEarningsWindowEnd: Date?
    public let isConfirmed: Bool
    
    public init(
        date: Date? = nil,
        marketTiming: MarketTiming = .unknown,
        projectedEarningsWindowStart: Date? = nil,
        projectedEarningsWindowEnd: Date? = nil,
        isConfirmed: Bool = false
    ) {
        self.date = date
        self.marketTiming = marketTiming
        self.projectedEarningsWindowStart = projectedEarningsWindowStart
        self.projectedEarningsWindowEnd = projectedEarningsWindowEnd
        self.isConfirmed = isConfirmed
    }
}

public enum EarningsError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noDataFound
} 