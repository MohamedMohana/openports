import Combine
import Foundation

/// Manages port favorites
@MainActor
public final class FavoritesManager: ObservableObject {
    public static let shared = FavoritesManager()

    private let defaults = UserDefaults.standard
    private let favoritesKey = "favoritePorts"

    @Published public private(set) var favorites: Set<Int> = []

    public init() {
        loadFavorites()
    }

    private func loadFavorites() {
        if let data = defaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            favorites = decoded
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            defaults.set(encoded, forKey: favoritesKey)
        }
    }

    public func toggleFavorite(_ port: Int) {
        if favorites.contains(port) {
            favorites.remove(port)
        } else {
            favorites.insert(port)
        }
        saveFavorites()
    }

    public func isFavorite(_ port: Int) -> Bool {
        favorites.contains(port)
    }
}
