import Foundation

/// Offline-first, file-backed cache for the last good `RateBoard`.
///
/// An `actor`, so concurrent readers/writers are safe by construction — no
/// locks, no races. The store policy is deliberately simple and honest:
///
/// - `save` persists the board with the moment it was fetched.
/// - `load` returns whatever we have, plus its age, and lets the caller decide
///   what "too stale" means (a field app on a low-connectivity site may happily
///   show yesterday's rates with a "last updated" label).
public actor BoardCache {
    public struct Entry: Codable, Equatable {
        public let board: RateBoard
        public let fetchedAt: Date

        public func age(now: Date = Date()) -> TimeInterval {
            now.timeIntervalSince(fetchedAt)
        }
    }

    private let fileURL: URL

    /// - Parameter directory: where the cache file lives. Defaults to the
    ///   user's caches directory; tests pass a temporary directory.
    public init(directory: URL? = nil, filename: String = "rateboard-cache.json") {
        let dir = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.fileURL = dir.appendingPathComponent(filename)
    }

    public func save(_ board: RateBoard, fetchedAt: Date = Date()) throws {
        let entry = Entry(board: board, fetchedAt: fetchedAt)
        let data = try JSONEncoder().encode(entry)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Returns the cached entry, or `nil` when nothing (or something
    /// unreadable) is on disk — a corrupted cache is treated as a miss,
    /// never a crash.
    public func load() -> Entry? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Entry.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
