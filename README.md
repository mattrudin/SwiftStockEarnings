# SwiftStockEarnings

A Swift package for fetching and parsing stock earnings data from the web.

## Features

- Fetch earnings data for any stock symbol
- Parse next earnings date
- Determine market timing (Before Market, After Market)
- Get projected earnings window
- Built-in network client with default implementation

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftStockEarnings.git", from: "0.1.0")
]
```

Or add it directly in Xcode by going to File > Add Packages and entering the repository URL.

## Usage

### Basic Usage

```swift
import SwiftStockEarnings

// Create an instance
let earnings = SwiftStockEarnings()

// Fetch earnings data for a stock symbol
Task {
    let earningsData = await earnings.fetchEarningsData(for: "AAPL")
    
    // Access the data
    if let nextEarningsDate = earningsData.date {
        print("Next earnings date: \(nextEarningsDate)")
    }
    
    switch earningsData.marketTiming {
    case .beforeMarket:
        print("Earnings will be released before market open")
    case .afterMarket:
        print("Earnings will be released after market close")
    case .unknown:
        print("Market timing is unknown")
    }
    
    if let windowStart = earningsData.projectedEarningsWindowStart,
       let windowEnd = earningsData.projectedEarningsWindowEnd {
        print("Projected earnings window: \(windowStart) to \(windowEnd)")
    }

    if earningsData.isConfirmed {
        print("Earnings date is confirmed")
    } else {
        print("Earnings date is not confirmed")
    }
}
```

### Custom Network Client

You can provide your own network client implementation by conforming to the `EarningsNetworkClient` protocol:

```swift
let customClient = YourCustomNetworkClient()
let earnings = SwiftStockEarnings(networkClient: customClient)
```

## Data Model

The package returns an `EarningsData` struct containing:

- `date`: The next earnings date (optional)
- `marketTiming`: When the earnings will be released (before market, after market, or unknown)
- `projectedEarningsWindowStart`: Start of the projected earnings window (optional)
- `projectedEarningsWindowEnd`: End of the projected earnings window (optional)
- `isConfirmed`: Boolean indicating whether the earnings date is confirmed (the logic behind this: if both earnings-window are present, then the earnings date is not confirmed)


## Error Handling

The package handles errors gracefully by returning an empty `EarningsData` struct if any errors occur during fetching or parsing.

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.5+

## License

MIT License

Copyright (c) 2025 Matthias Rudin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 