import Testing
import Foundation
@testable import SwiftStockEarnings

@Suite("Earnings Data Tests")
struct EarningsDataTests {
    // Mock HTML data for different test scenarios
    private let mockHTMLAfterMarket = """
    <html>
        <body>
            <table>
                <tr>
                    <td>Next Earnings Date: <span class="stock_title"><b>May 1, 2025<font size="-1">AC</font></b></span></td>
                </tr>
                <tr>
                    <td>OS Projected Window: April 28, 2025 to May 3, 2025</td>
                </tr>
            </table>
        </body>
    </html>
    """

    private let mockHTMLBeforeMarket = """
    <html>
        <body>
            <table>
                <tr>
                    <td>Next Earnings Date: <span class="stock_title"><b>May 1, 2025<font size="-1">BO</font></b></span></td>
                </tr>
                <tr>
                    <td>OS Projected Window: April 28, 2025 to May 3, 2025</td>
                </tr>
            </table>
        </body>
    </html>
    """

    private let mockHTMLUnknownTiming = """
    <html>
        <body>
            <table>
                <tr>
                    <td>Next Earnings Date: <span class="stock_title"><b>May 1, 2025</b></span></td>
                </tr>
                <tr>
                    <td>OS Projected Window: April 28, 2025 to May 3, 2025</td>
                </tr>
            </table>
        </body>
    </html>
    """

    private let mockHTMLInvalidDate = """
    <html>
        <body>
            <table>
                <tr>
                    <td>Next Earnings Date: <span class="stock_title"><b>Invalid Date<font size="-1">AC</font></b></span></td>
                </tr>
                <tr>
                    <td>OS Projected Window: Invalid Start to Invalid End</td>
                </tr>
            </table>
        </body>
    </html>
    """

    private class MockEarningsNetworkClient: EarningsNetworkClient {
        private let mockHTML: String
        
        init(mockHTML: String) {
            self.mockHTML = mockHTML
        }
        
        func fetchHTML(for symbol: String) async throws -> String {
            return mockHTML
        }
    }

    // Live-Data-Test, therefore has to be skipped in PROD
    func skip_testLiveAAPLEarningsData() async {
        // Arrange
        let earnings = SwiftStockEarnings()
        
        // Act
        let earningsData = await earnings.fetchEarningsData(for: "AAPL")
        
        // Assert
        if let date = earningsData.date {
            #expect(date > Date()) // Date should be in the future
        }
        
        if let startDate = earningsData.projectedEarningsWindowStart,
           let endDate = earningsData.projectedEarningsWindowEnd,
           let earningsDate = earningsData.date {
            #expect(startDate <= earningsDate) // Window start should be before or on earnings date
            #expect(endDate >= earningsDate) // Window end should be after or on earnings date
        }
        
        #expect(earningsData.marketTiming == .afterMarket) // AAPL typically reports after market
        
        // Print the results for manual verification
        print("AAPL Earnings Data:")
        print("Date: \(earningsData.date?.description ?? "nil")")
        print("Market Timing: \(earningsData.marketTiming)")
        print("Window Start: \(earningsData.projectedEarningsWindowStart?.description ?? "nil")")
        print("Window End: \(earningsData.projectedEarningsWindowEnd?.description ?? "nil")")
    }

    @Test("After Market Timing Test")
    func testAfterMarketTiming() async {
        // Arrange
        let mockClient = MockEarningsNetworkClient(mockHTML: mockHTMLAfterMarket)
        let earnings = SwiftStockEarnings(networkClient: mockClient)
        
        // Act
        let earningsData = await earnings.fetchEarningsData(for: "TEST")
        
        // Assert
        #expect(earningsData.marketTiming == .afterMarket)
        #expect(earningsData.date != nil)
        #expect(earningsData.projectedEarningsWindowStart != nil)
        #expect(earningsData.projectedEarningsWindowEnd != nil)
        #expect(earningsData.isConfirmed == false)
    }

    @Test("Before Market Timing Test")
    func testBeforeMarketTiming() async {
        // Arrange
        let mockClient = MockEarningsNetworkClient(mockHTML: mockHTMLBeforeMarket)
        let earnings = SwiftStockEarnings(networkClient: mockClient)
        
        // Act
        let earningsData = await earnings.fetchEarningsData(for: "TEST")
        
        // Assert
        #expect(earningsData.marketTiming == .beforeMarket)
        #expect(earningsData.date != nil)
        #expect(earningsData.projectedEarningsWindowStart != nil)
        #expect(earningsData.projectedEarningsWindowEnd != nil)
        #expect(earningsData.isConfirmed == false)
    }

    @Test("Unknown Market Timing Test")
    func testUnknownMarketTiming() async {
        // Arrange
        let mockClient = MockEarningsNetworkClient(mockHTML: mockHTMLUnknownTiming)
        let earnings = SwiftStockEarnings(networkClient: mockClient)
        
        // Act
        let earningsData = await earnings.fetchEarningsData(for: "TEST")
        
        // Assert
        #expect(earningsData.marketTiming == .unknown)
        #expect(earningsData.date != nil)
        #expect(earningsData.projectedEarningsWindowStart != nil)
        #expect(earningsData.projectedEarningsWindowEnd != nil)
        #expect(earningsData.isConfirmed == false)
    }

    @Test("Invalid Date Parsing Test")
    func testInvalidDateParsing() async {
        // Arrange
        let mockClient = MockEarningsNetworkClient(mockHTML: mockHTMLInvalidDate)
        let earnings = SwiftStockEarnings(networkClient: mockClient)
        
        // Act
        let earningsData = await earnings.fetchEarningsData(for: "TEST")
        
        // Assert
        #expect(earningsData.date == nil)
        #expect(earningsData.projectedEarningsWindowStart == nil)
        #expect(earningsData.projectedEarningsWindowEnd == nil)
        #expect(earningsData.marketTiming == .afterMarket) // AC is still present in the HTML
        #expect(earningsData.isConfirmed == false)
    }

    @Test("Is Confirmed Property Test")
    func testIsConfirmedProperty() async {
        // Arrange
        let mockHTMLWithWindow = """
        <html>
            <body>
                <table>
                    <tr>
                        <td>Next Earnings Date: <span class="stock_title"><b>May 1, 2025</b></span></td>
                    </tr>
                    <tr>
                        <td>OS Projected Window: April 28, 2025 to May 3, 2025</td>
                    </tr>
                </table>
            </body>
        </html>
        """

        let mockHTMLWithoutWindow = """
        <html>
            <body>
                <table>
                    <tr>
                        <td>Next Earnings Date: <span class="stock_title"><b>May 1, 2025</b></span></td>
                    </tr>
                </table>
            </body>
        </html>
        """

        let mockClientWithWindow = MockEarningsNetworkClient(mockHTML: mockHTMLWithWindow)
        let mockClientWithoutWindow = MockEarningsNetworkClient(mockHTML: mockHTMLWithoutWindow)
        let earningsWithWindow = SwiftStockEarnings(networkClient: mockClientWithWindow)
        let earningsWithoutWindow = SwiftStockEarnings(networkClient: mockClientWithoutWindow)
        
        // Act
        let earningsDataWithWindow = await earningsWithWindow.fetchEarningsData(for: "TEST")
        let earningsDataWithoutWindow = await earningsWithoutWindow.fetchEarningsData(for: "TEST")
        
        // Assert
        #expect(earningsDataWithWindow.isConfirmed == false)
        #expect(earningsDataWithoutWindow.isConfirmed == true)
    }
}
