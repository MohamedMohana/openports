import Foundation
import Combine

/// Manages port favorites
public class FavoritesManager: ObservableObject {
    public static let shared = FavoritesManager()
    
    private let defaults = UserDefaults.standard
    private let favoritesKey = "favoritePorts"
    
    @Published private(set) favorites: Set<Int> = [] {
        didSet {
        }
    }
    
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
        return favorites.contains(port)
    }
}
