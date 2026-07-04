import Foundation

/// Screens and tests depend on this protocol, not the concrete client,
/// so the network is trivial to mock.
public protocol RatesProviding {
    func latest(base: String) async throws -> RateBoard
}

/// Talks to the free, key-less Frankfurter API (ECB reference rates) and
/// returns a clean `RateBoard` — normalized at the boundary.
///
/// API: https://frankfurter.dev  (no API key required)
public struct FrankfurterClient: RatesProviding {
    public enum ClientError: Error, Equatable {
        case invalidBase
        case badResponse(status: Int)
        case emptyBoard
    }

    private let session: URLSession
    private let baseURL = URL(string: "https://api.frankfurter.dev/v1/latest")!

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func latest(base: String) async throws -> RateBoard {
        let code = base.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 3, code.allSatisfy(\.isLetter) else {
            throw ClientError.invalidBase
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "base", value: code)]

        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ClientError.badResponse(status: http.statusCode)
        }

        let raw = try JSONDecoder().decode(RawRatesResponse.self, from: data)
        guard let board = RateBoard(from: raw, requestedBase: code) else {
            throw ClientError.emptyBoard
        }
        return board
    }
}
