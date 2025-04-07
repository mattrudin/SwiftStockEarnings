import Foundation

public protocol EarningsNetworkClient {
    func fetchHTML(for symbol: String) async throws -> String
}

public class DefaultEarningsNetworkClient: EarningsNetworkClient {
    private let baseURL = "https://www.optionslam.com/earnings/stocks/"
    
    public init() {}
    
    public func fetchHTML(for symbol: String) async throws -> String {
        guard let url = URL(string: baseURL + symbol) else {
            throw EarningsError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw EarningsError.noDataFound
        }
        
        return html
    }
} 