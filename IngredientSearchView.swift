import SwiftUI

struct IngredientSearchView: View {
    @State private var ingredients: [Ingredient] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var filtered: [Ingredient] {
        guard !searchText.isEmpty else { return ingredients }
        return ingredients.filter {
            ($0.strIngredient ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView("Chargement des ingrédients...")
                    .frame(maxWidth: .infinity)
            } else if let err = errorMessage {
                Text(err).foregroundColor(.red)
            } else if ingredients.isEmpty {
                Text("Aucun ingrédient disponible.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filtered) { ing in
                    NavigationLink {
                        IngredientResultsView(ingredientName: ing.strIngredient ?? "")
                    } label: {
                        HStack(spacing: 12) {
                            if let thumb = ing.strThumb, let url = URL(string: thumb) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Color(.systemGray5)
                                            .frame(width: 56, height: 56)
                                            .cornerRadius(8)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipped()
                                            .cornerRadius(8)
                                    case .failure:
                                        Color(.systemGray4)
                                            .frame(width: 56, height: 56)
                                            .cornerRadius(8)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 56, height: 56)
                            }

                            VStack(alignment: .leading) {
                                Text(ing.strIngredient ?? "Ingrédient")
                                    .font(.headline)
                                if let desc = ing.strDescription, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Ingrédients")
        .onAppear { Task { await loadIngredients() } }
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await loadIngredients() } } label: { Image(systemName: "arrow.clockwise") } } }
    }

    private func loadIngredients() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let list = try await MealService.shared.listIngredients()
            // sort alphabetically
            ingredients = list.sorted { ($0.strIngredient ?? "").localizedCaseInsensitiveCompare($1.strIngredient ?? "") == .orderedAscending }
        } catch {
            errorMessage = "Erreur lors du chargement des ingrédients: \(error.localizedDescription)"
            ingredients = []
        }
    }
}

// Results view listing meals that use the selected ingredient
struct IngredientResultsView: View {
    let ingredientName: String
    @State private var meals: [Meal] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Recherche de recettes pour \(ingredientName)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                Text(err).foregroundColor(.red).padding()
            } else if meals.isEmpty {
                Text("Aucune recette trouvée pour \(ingredientName)")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(meals) { meal in
                    NavigationLink { MealDetailLoader(mealSummary: meal) } label: {
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
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(ingredientName)
        .task { await loadResults() }
    }

    private func loadResults() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let results = try await MealService.shared.filterMeals(byIngredient: ingredientName)
            meals = results
        } catch {
            errorMessage = "Erreur lors de la recherche de recettes: \(error.localizedDescription)"
            meals = []
        }
    }
}

struct IngredientSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { IngredientSearchView() }
    }
}
