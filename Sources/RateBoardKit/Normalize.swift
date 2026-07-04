import Foundation

public extension RateBoard {
    /// The single boundary where the raw wire payload is made well-formed.
    ///
    /// - Missing or unparseable fields fall back safely (base defaults to the
    ///   requested one, an unparseable date becomes "now" rather than a crash).
    /// - Non-finite or non-positive rates are dropped — the UI can trust every
    ///   row it receives.
    /// - Rates are sorted by currency code for stable, predictable rendering.
    /// - Returns `nil` only when there are no usable rates at all, so callers
    ///   can fall back to the offline cache.
    init?(from raw: RawRatesResponse, requestedBase: String, now: Date = Date()) {
        let cleaned = (raw.rates ?? [:])
            .filter { $0.value.isFinite && $0.value > 0 }
            .map { Rate(currency: $0.key.uppercased(), value: $0.value) }
            .sorted { $0.currency < $1.currency }

        guard !cleaned.isEmpty else { return nil }

        self.init(
            base: (raw.base ?? requestedBase).uppercased(),
            date: Self.parseDate(raw.date) ?? now,
            rates: cleaned
        )
    }

    /// Frankfurter dates are plain `yyyy-MM-dd` (no time, no zone). Parse in
    /// UTC so the calendar day never shifts with the device's timezone.
    static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
