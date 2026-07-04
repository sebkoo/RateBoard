import XCTest
@testable import RateBoardKit

// The three load-bearing pieces get the tests: the normalize boundary,
// the offline cache, and the white-label config.

final class NormalizeTests: XCTestCase {
    func testNormalizesAFullPayload() throws {
        let raw = try decode(#"{"amount":1.0,"base":"usd","date":"2026-07-03","rates":{"KRW":1372.4,"EUR":0.91}}"#)
        let board = try XCTUnwrap(RateBoard(from: raw, requestedBase: "USD"))

        XCTAssertEqual(board.base, "USD")
        XCTAssertEqual(board.rates.map(\.currency), ["EUR", "KRW"]) // sorted
        XCTAssertEqual(board.rates.first?.value, 0.91)
    }

    func testDropsJunkRatesAndKeepsGoodOnes() throws {
        let raw = try decode(#"{"base":"USD","date":"2026-07-03","rates":{"EUR":0.91,"BAD":-1,"ZRO":0}}"#)
        let board = try XCTUnwrap(RateBoard(from: raw, requestedBase: "USD"))

        XCTAssertEqual(board.rates.map(\.currency), ["EUR"]) // junk dropped, no crash
    }

    func testReturnsNilWhenNothingIsUsable() throws {
        let raw = try decode(#"{"base":"USD","rates":{}}"#)
        XCTAssertNil(RateBoard(from: raw, requestedBase: "USD")) // caller falls back to cache
    }

    func testParsesDateInUTC() throws {
        let date = try XCTUnwrap(RateBoard.parseDate("2026-07-03"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(calendar.component(.day, from: date), 3) // no timezone day-shift
    }

    func testConvertUsesTheBoardRate() throws {
        let board = RateBoard(base: "USD", date: Date(), rates: [Rate(currency: "EUR", value: 0.5)])
        XCTAssertEqual(board.convert(10, to: "eur"), 5.0)
        XCTAssertNil(board.convert(10, to: "XXX")) // unknown currency -> nil, not a crash
    }

    private func decode(_ json: String) throws -> RawRatesResponse {
        try JSONDecoder().decode(RawRatesResponse.self, from: Data(json.utf8))
    }
}

final class BoardCacheTests: XCTestCase {
    func testSaveThenLoadRoundTrips() async throws {
        let cache = BoardCache(directory: FileManager.default.temporaryDirectory,
                               filename: "test-\(UUID().uuidString).json")
        let board = RateBoard(base: "USD", date: Date(timeIntervalSince1970: 0),
                              rates: [Rate(currency: "EUR", value: 0.91)])

        try await cache.save(board, fetchedAt: Date(timeIntervalSince1970: 100))
        let loaded = await cache.load()
        let entry = try XCTUnwrap(loaded)

        XCTAssertEqual(entry.board, board)
        XCTAssertEqual(entry.age(now: Date(timeIntervalSince1970: 160)), 60) // caller judges staleness
        await cache.clear()
    }

    func testLoadReturnsNilOnMissOrCorruption() async {
        let cache = BoardCache(directory: FileManager.default.temporaryDirectory,
                               filename: "missing-\(UUID().uuidString).json")
        let entry = await cache.load()
        XCTAssertNil(entry) // a missing/corrupted cache is a miss, never a crash
    }
}

final class BrandConfigTests: XCTestCase {
    func testLoadsAFullBrandFile() {
        let json = ##"{"appName":"AcmePay Rates","primaryColorHex":"#FF5500","baseCurrency":"eur","pinnedCurrencies":["usd","krw"],"features":{"showConverter":false}}"##
        let config = BrandConfig.load(from: Data(json.utf8))

        XCTAssertEqual(config.appName, "AcmePay Rates")
        XCTAssertEqual(config.baseCurrency, "EUR")          // normalized to uppercase
        XCTAssertEqual(config.pinnedCurrencies, ["USD", "KRW"])
        XCTAssertFalse(config.features.showConverter)
        XCTAssertTrue(config.features.showLastUpdated)      // unspecified -> default
    }

    func testPartialOrBrokenConfigFallsBackToDefaults() {
        XCTAssertEqual(BrandConfig.load(from: Data("{}".utf8)).appName, "RateBoard")
        XCTAssertEqual(BrandConfig.load(from: Data("not json".utf8)).baseCurrency, "USD")
        XCTAssertEqual(BrandConfig.load(from: nil).pinnedCurrencies, ["EUR", "GBP", "JPY", "KRW"])
    }
}
