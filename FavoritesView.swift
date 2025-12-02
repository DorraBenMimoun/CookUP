import SwiftUI

struct FavoritesView: View {
    @StateObject private var store = FavoriteStore.shared
    @State private var meals: [Meal] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if meals.isEmpty {
                Text(store.favorites.isEmpty ? "Aucun favori pour l'instant." : "Détails des favoris indisponibles.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: meal.thumbnailURL) { phase in
                                    switch phase {
                                    case .empty:
                                        Color(.systemGray5)
                                            .frame(width: 72, height: 72)
                                            .cornerRadius(8)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipped()
                                            .cornerRadius(8)
                                    case .failure:
                                        Color(.systemGray4)
                                            .frame(width: 72, height: 72)
                                            .cornerRadius(8)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }

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

                                // quick toggle button
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
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Favoris")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await loadFavorites() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            Task { await loadFavorites() }
        }
        .onChange(of: store.favorites) { _ in
            Task { await loadFavorites() }
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let meal = meals[idx]
            let id = meal.idMeal ?? meal.id
            store.remove(id: id)
        }
    }

    private func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let ids = Array(store.favorites)
        guard !ids.isEmpty else {
            meals = []
            return
        }

        var results: [Meal] = []
        await withTaskGroup(of: Meal?.self) { group in
            for id in ids {
                group.addTask { try? await MealService.shared.lookupMeal(id: id) }
            }
            for await m in group {
                if let meal = m { results.append(meal) }
            }
        }

        // keep unique and stable order by title
        var seen = Set<String>()
        meals = results.filter { meal in
            let id = meal.idMeal ?? meal.id
            if seen.contains(id) { return false }
            seen.insert(id)
            return true
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FavoritesView() }
    }
}
