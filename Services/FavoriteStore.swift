import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// FavoriteStore now supports optional remote sync with Firestore.
/// Behavior:
/// - If a user is authenticated, favorites are loaded from Firestore (document `users/{uid}` field `favorites`).
/// - Mutations (add/remove/toggle) will update Firestore when a user is signed-in, and always persist locally to UserDefaults as fallback.
final class FavoriteStore: ObservableObject {
    static let shared = FavoriteStore()

    @Published private(set) var favorites: Set<String>

    private let key = "favorite_meal_ids"
    private let db = Firestore.firestore()

    private var authHandle: AuthStateDidChangeListenerHandle?

    private init() {
        if let arr = UserDefaults.standard.stringArray(forKey: key) {
            self.favorites = Set(arr)
        } else {
            self.favorites = []
        }

        // Listen to auth state changes to load remote favorites when a user signs in
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let u = user {
                self.loadFromFirestore(uid: u.uid)
            } else {
                // signed out: keep local favorites but do not overwrite remote
                // Optionally clear in-memory favorites if you prefer:
                // DispatchQueue.main.async { self.favorites = [] }
            }
        }
    }

    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }

    func toggle(id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        persistLocal()
        syncToFirestoreIfNeeded()
    }

    func add(id: String) {
        guard !favorites.contains(id) else { return }
        favorites.insert(id)
        persistLocal()
        syncToFirestoreIfNeeded()
    }

    func remove(id: String) {
        guard favorites.contains(id) else { return }
        favorites.remove(id)
        persistLocal()
        syncToFirestoreIfNeeded()
    }

    // MARK: - Persistence
    private func persistLocal() {
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }

    private func loadFromFirestore(uid: String) {
        let doc = db.collection("users").document(uid)
        doc.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let err = error {
                print("Failed to load favorites from Firestore: \(err)")
                return
            }
            if let data = snapshot?.data(), let arr = data["favorites"] as? [String] {
                DispatchQueue.main.async {
                    self.favorites = Set(arr)
                    self.persistLocal()
                }
            } else {
                // No remote favorites yet; ensure local persisted
                self.persistLocal()
            }
        }
    }

    private func syncToFirestoreIfNeeded() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = db.collection("users").document(uid)
        let arr = Array(favorites)
        doc.setData(["favorites": arr], merge: true) { err in
            if let e = err { print("Failed to sync favorites to Firestore: \(e)") }
        }
    }
}
