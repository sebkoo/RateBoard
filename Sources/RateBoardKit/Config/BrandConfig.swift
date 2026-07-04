import Foundation

/// The white-label heart of RateBoard.
///
/// Everything a company would customize lives in one JSON file — name, colors,
/// base currency, which currencies to pin, and which features to turn on. Fork
/// the repo, edit `Brand.json`, ship your own branded rates app. No code edits.
///
/// Every field has a sensible default, so a partial (or missing) config can
/// never crash the app — the same defensive posture as the data boundary.
public struct BrandConfig: Codable, Equatable {
    public var appName: String
    public var primaryColorHex: String
    public var baseCurrency: String
    public var pinnedCurrencies: [String]
    public var features: Features

    public struct Features: Codable, Equatable {
        public var showConverter: Bool
        public var showLastUpdated: Bool

        public init(showConverter: Bool = true, showLastUpdated: Bool = true) {
            self.showConverter = showConverter
            self.showLastUpdated = showLastUpdated
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.showConverter = try c.decodeIfPresent(Bool.self, forKey: .showConverter) ?? true
            self.showLastUpdated = try c.decodeIfPresent(Bool.self, forKey: .showLastUpdated) ?? true
        }
    }

    public init(
        appName: String = "RateBoard",
        primaryColorHex: String = "#1F3A5F",
        baseCurrency: String = "USD",
        pinnedCurrencies: [String] = ["EUR", "GBP", "JPY", "KRW"],
        features: Features = Features()
    ) {
        self.appName = appName
        self.primaryColorHex = primaryColorHex
        self.baseCurrency = baseCurrency
        self.pinnedCurrencies = pinnedCurrencies
        self.features = features
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = BrandConfig()
        self.appName = try c.decodeIfPresent(String.self, forKey: .appName) ?? fallback.appName
        self.primaryColorHex = try c.decodeIfPresent(String.self, forKey: .primaryColorHex) ?? fallback.primaryColorHex
        self.baseCurrency = (try c.decodeIfPresent(String.self, forKey: .baseCurrency) ?? fallback.baseCurrency).uppercased()
        self.pinnedCurrencies = (try c.decodeIfPresent([String].self, forKey: .pinnedCurrencies) ?? fallback.pinnedCurrencies).map { $0.uppercased() }
        self.features = try c.decodeIfPresent(Features.self, forKey: .features) ?? fallback.features
    }

    /// Load a brand config from JSON data, falling back to defaults on any
    /// failure — a broken config file downgrades gracefully, never crashes.
    public static func load(from data: Data?) -> BrandConfig {
        guard let data, let config = try? JSONDecoder().decode(BrandConfig.self, from: data) else {
            return BrandConfig()
        }
        return config
    }
}
