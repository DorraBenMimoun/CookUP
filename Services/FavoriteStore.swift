import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// Classe qui gère les favoris de l'utilisateur.
// Elle utilise UserDefaults (local) et Firestore (en ligne si l'utilisateur est connecté).
final class FavoriteStore: ObservableObject {

    // Instance unique (Singleton) pour accéder à FavoriteStore partout dans l'app.
    static let shared = FavoriteStore()

    // Liste des favoris (un Set pour éviter les doublons).
    @Published private(set) var favorites: Set<String>

    // Clé utilisée pour enregistrer les favoris dans UserDefaults.
    private let key = "favorite_meal_ids"

    // Référence à Firestore.
    private let db = Firestore.firestore()

    // Pour écouter les changements d’état de connexion Firebase Auth.
    private var authHandle: AuthStateDidChangeListenerHandle?

    private init() {

        // On commence par charger les favoris enregistrés localement.
        if let arr = UserDefaults.standard.stringArray(forKey: key) {
            self.favorites = Set(arr)
        } else {
            self.favorites = []
        }

        // On écoute si l’utilisateur se connecte ou se déconnecte.
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let u = user {
                // Si utilisateur connecté → charger ses favoris depuis Firestore.
                self.loadFromFirestore(uid: u.uid)
            } else {
                // Si déconnecté → on garde seulement les favoris locaux.
            }
        }
    }

    deinit {
        // Quand l'objet est détruit : on arrête d'écouter les connexions.
        if let h = authHandle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }

    // Vérifie si un élément est dans les favoris.
    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }

    // Ajoute ou retire un favori (toggle = inverse).
    func toggle(id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }

        // On sauvegarde localement.
        persistLocal()

        // On envoie vers Firestore si l'utilisateur est connecté.
        syncToFirestoreIfNeeded()
    }

    // Ajoute un favori.
    func add(id: String) {
        guard !favorites.contains(id) else { return }
        favorites.insert(id)
        persistLocal()
        syncToFirestoreIfNeeded()
    }

    // Supprime un favori.
    func remove(id: String) {
        guard favorites.contains(id) else { return }
        favorites.remove(id)
        persistLocal()
        syncToFirestoreIfNeeded()
    }

    // Sauvegarde les favoris en local (UserDefaults).
    private func persistLocal() {
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }

    // Charge les favoris depuis Firestore pour un utilisateur donné.
    private func loadFromFirestore(uid: String) {
        let doc = db.collection("users").document(uid)

        doc.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let err = error {
                print("Failed to load favorites from Firestore: \(err)")
                return
            }

            // Si on trouve un tableau "favorites" dans Firestore :
            if let data = snapshot?.data(),
               let arr = data["favorites"] as? [String] {

                DispatchQueue.main.async {
                    // On met à jour la liste en mémoire.
                    self.favorites = Set(arr)
                    // On les enregistre aussi localement.
                    self.persistLocal()
                }
            } else {
                // Si aucun favoris dans Firestore → on garde les favoris locaux.
                self.persistLocal()
            }
        }
    }

    // Envoie les favoris vers Firestore si l'utilisateur est connecté.
    private func syncToFirestoreIfNeeded() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let doc = db.collection("users").document(uid)
        let arr = Array(favorites)

        doc.setData(["favorites": arr], merge: true) { err in
            if let e = err {
                print("Failed to sync favorites to Firestore: \(e)")
            }
        }
    }
}
