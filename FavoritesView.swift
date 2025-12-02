import SwiftUI

struct FavoritesView: View {
    // Le store qui contient la liste des favoris.
    @StateObject private var store = FavoriteStore.shared
    
    // Tableau contenant les repas favoris (détails complets).
    @State private var meals: [Meal] = []
    
    // Pour afficher un indicateur de chargement.
    @State private var isLoading: Bool = false
    
    // Pour afficher un message d’erreur si nécessaire.
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            // Si on est en chargement → affiche un spinner.
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Si pas de repas chargés :
            } else if meals.isEmpty {
                // Si aucun ID favori → message "aucun favori".
                // Sinon → les détails n'ont pas pu être chargés.
                Text(store.favorites.isEmpty ? "Aucun favori pour l'instant." : "Détails des favoris indisponibles.")
                    .foregroundColor(.secondary)
                    .padding()

            } else {
                // Si on a des repas → affiche la liste.
                List {
                    ForEach(meals) { meal in

                        // Quand on clique → on va vers la page de détail du repas.
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {

                            HStack(spacing: 12) {

                                // Image du repas chargée depuis internet.
                                AsyncImage(url: meal.thumbnailURL) { phase in
                                    switch phase {
                                    case .empty:
                                        // Image pas encore chargée → afficher un gris.
                                        Color(.systemGray5)
                                            .frame(width: 72, height: 72)
                                            .cornerRadius(8)

                                    case .success(let image):
                                        // Image chargée avec succès.
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipped()
                                            .cornerRadius(8)

                                    case .failure:
                                        // Si l'image n'a pas pu se charger.
                                        Color(.systemGray4)
                                            .frame(width: 72, height: 72)
                                            .cornerRadius(8)

                                    @unknown default:
                                        EmptyView()
                                    }
                                }

                                // Titre et catégorie du repas.
                                VStack(alignment: .leading) {
                                    Text(meal.title)
                                        .font(.headline)
                                    if let cat = meal.strCategory {
                                        Text(cat)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                // Bouton "cœur" pour ajouter/retirer des favoris.
                                let id = meal.idMeal ?? meal.id
                                Button {
                                    store.toggle(id: id)
                                } label: {
                                    Image(systemName: store.isFavorite(id: id) ? "heart.fill" : "heart")
                                        .foregroundColor(store.isFavorite(id: id) ? .red : .gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    // Permet de supprimer un élément avec un swipe.
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }

        // Titre dans la barre de navigation.
        .navigationTitle("Favoris")

        // Bouton pour recharger la liste manuellement.
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await loadFavorites() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }

        // Quand la vue apparaît → on charge la liste des favoris.
        .onAppear {
            Task { await loadFavorites() }
        }

        // Quand la liste des IDs favoris change → recharger les détails des repas.
        .onChange(of: store.favorites) { _ in
            Task { await loadFavorites() }
        }
    }

    // Fonction appelée lorsqu’on supprime un repas dans la liste.
    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let meal = meals[idx]
            let id = meal.idMeal ?? meal.id
            store.remove(id: id) // Retire depuis FavoriteStore.
        }
    }

    // Charge les repas favoris depuis l'API.
    private func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Récupère les ID favoris.
        let ids = Array(store.favorites)

        // Si aucun favori → la liste est vide.
        guard !ids.isEmpty else {
            meals = []
            return
        }

        var results: [Meal] = []

        // Lancer plusieurs requêtes en parallèle pour récupérer chaque repas.
        await withTaskGroup(of: Meal?.self) { group in
            for id in ids {
                group.addTask {
                    try? await MealService.shared.lookupMeal(id: id)
                }
            }

            // Récupère les résultats des requêtes.
            for await m in group {
                if let meal = m { results.append(meal) }
            }
        }

        // Filtrer les doublons → n’afficher chaque repas qu’une seule fois.
        var seen = Set<String>()
        meals = results.filter { meal in
            let id = meal.idMeal ?? meal.id
            if seen.contains(id) { return false }
            seen.insert(id)
            return true
        }
    }
}

// Aperçu dans Xcode.
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FavoritesView() }
    }
}
