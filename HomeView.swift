import SwiftUI

@MainActor
struct HomeView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "Tous"
    @State private var meals: [Meal] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Category model used by the UI (small subset of TheMealDB response)
    struct CategoryItem: Identifiable, Hashable {
        let id: String
        let title: String
        let thumbURL: URL?
        let description: String?
    }

    // Categories provided by the user (kept as-is from their JSON). "Tous" added first.
    let categories: [CategoryItem] = {
        let raw: [[String: String]] = [
            ["idCategory":"0","strCategory":"Tous","strCategoryThumb":"","strCategoryDescription":"Toutes les recettes (aléatoire)"],
            ["idCategory":"1","strCategory":"Beef","strCategoryThumb":"https://www.themealdb.com/images/category/beef.png","strCategoryDescription":"Beef is the culinary name for meat from cattle..."],
            ["idCategory":"2","strCategory":"Chicken","strCategoryThumb":"https://www.themealdb.com/images/category/chicken.png","strCategoryDescription":"Chicken is a type of domesticated fowl..."],
            ["idCategory":"3","strCategory":"Dessert","strCategoryThumb":"https://www.themealdb.com/images/category/dessert.png","strCategoryDescription":"Dessert is a course that concludes a meal..."],
            ["idCategory":"4","strCategory":"Lamb","strCategoryThumb":"https://www.themealdb.com/images/category/lamb.png","strCategoryDescription":"Lamb, hogget, and mutton are the meat of domestic sheep..."],
            ["idCategory":"5","strCategory":"Miscellaneous","strCategoryThumb":"https://www.themealdb.com/images/category/miscellaneous.png","strCategoryDescription":"General foods that don't fit into another category"],
            ["idCategory":"6","strCategory":"Pasta","strCategoryThumb":"https://www.themealdb.com/images/category/pasta.png","strCategoryDescription":"Pasta is a staple food of traditional Italian cuisine..."],
            ["idCategory":"7","strCategory":"Pork","strCategoryThumb":"https://www.themealdb.com/images/category/pork.png","strCategoryDescription":"Pork is the culinary name for meat from a domestic pig..."],
            ["idCategory":"8","strCategory":"Seafood","strCategoryThumb":"https://www.themealdb.com/images/category/seafood.png","strCategoryDescription":"Seafood is any form of sea life regarded as food by humans."],
            ["idCategory":"9","strCategory":"Side","strCategoryThumb":"https://www.themealdb.com/images/category/side.png","strCategoryDescription":"A side dish that accompanies the entrée or main course."],
            ["idCategory":"10","strCategory":"Starter","strCategoryThumb":"https://www.themealdb.com/images/category/starter.png","strCategoryDescription":"An entrée in modern French table service served before the main course."],
            ["idCategory":"11","strCategory":"Vegan","strCategoryThumb":"https://www.themealdb.com/images/category/vegan.png","strCategoryDescription":"Veganism is both the practice of abstaining from the use of animal products..."],
            ["idCategory":"12","strCategory":"Vegetarian","strCategoryThumb":"https://www.themealdb.com/images/category/vegetarian.png","strCategoryDescription":"Vegetarianism is the practice of abstaining from the consumption of meat..."],
            ["idCategory":"13","strCategory":"Breakfast","strCategoryThumb":"https://www.themealdb.com/images/category/breakfast.png","strCategoryDescription":"Breakfast is the first meal of a day."],
            ["idCategory":"14","strCategory":"Goat","strCategoryThumb":"https://www.themealdb.com/images/category/goat.png","strCategoryDescription":"The domestic goat or simply goat is a subspecies of C. aegagrus domesticated..."],
        ]

        return raw.compactMap { dict in
            let id = dict["idCategory"] ?? UUID().uuidString
            let title = dict["strCategory"] ?? "Catégorie"
            let desc = dict["strCategoryDescription"]
            let thumbStr = dict["strCategoryThumb"] ?? ""
            let thumb = URL(string: thumbStr)
            return CategoryItem(id: id, title: title, thumbURL: thumb, description: desc)
        }
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Banner
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color("AccentColor"), Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 180)
                        .shadow(radius: 6)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bienvenue sur CookUp")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Trouvez des recettes inspirantes pour chaque repas.")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                }
                .padding(.horizontal)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Rechercher une recette, ingrédient...", text: $searchText, onCommit: {
                        Task { await performSearch() }
                    })
                    .textFieldStyle(.plain)
                    if isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal)

                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category.title
                                Task { await performCategorySearch(category: category.title) }
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        if let url = category.thumbURL {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    Color(.systemGray5)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                case .failure:
                                                    Color(.systemGray4)
                                                @unknown default:
                                                    Color(.systemGray5)
                                                }
                                            }
                                            .frame(width: 72, height: 72)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            // Fallback icon for "Tous"
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 72, height: 72)
                                                .overlay(Image(systemName: "shuffle")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white))
                                        }
                                    }
                                    Text(category.title)
                                        .font(.caption)
                                        .foregroundColor(selectedCategory == category.title ? .accentColor : .primary)
                                }
                                .padding(8)
                                .background(selectedCategory == category.title ? Color.accentColor.opacity(0.12) : Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Results list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Résultats")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    if meals.isEmpty {
                        Text("Aucune recette pour le moment. Tapez une recherche et appuyez sur Entrée.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(meals) { meal in
                            NavigationLink {
                                MealDetailLoader(mealSummary: meal)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(url: meal.thumbnailURL) { phase in
                                        switch phase {
                                        case .empty:
                                            Color(.systemGray5)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        case .failure:
                                            Color(.systemGray4)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }

                                    VStack(alignment: .leading) {
                                        Text(meal.title)
                                            .font(.headline)
                                        Text(meal.strCategory ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
        }
        .task {
            // On first launch show random meals (Tous behaviour)
            await performCategorySearch(category: "Tous")
        }
    }

    private func performSearch(query: String? = nil) async {
        let q = (query ?? searchText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            meals = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let results = try await MealService.shared.searchMeals(query: q)
            self.meals = results
            if results.isEmpty {
                self.errorMessage = "Aucune recette trouvée pour \"\(q)\""
            }
        } catch {
            self.errorMessage = "Erreur lors de la recherche: \(error.localizedDescription)"
            self.meals = []
        }
        isLoading = false
    }

    private func performCategorySearch(category: String) async {
        isLoading = true
        errorMessage = nil
        searchText = ""

        do {
            if category == "Tous" {
                // fetch several random meals to populate the "All" view
                let randoms = try await MealService.shared.randomMeals(count: 8)
                self.meals = randoms
                if randoms.isEmpty {
                    self.errorMessage = "Aucune recette aléatoire trouvée"
                }
            } else {
                // use filter endpoint for categories
                let filtered = try await MealService.shared.filterMeals(byCategory: category)
                self.meals = filtered
                if filtered.isEmpty {
                    self.errorMessage = "Aucune recette trouvée pour la catégorie \(category)"
                }
            }
        } catch {
            self.errorMessage = "Erreur lors de la recherche de catégorie: \(error.localizedDescription)"
            self.meals = []
        }
        isLoading = false
    }
}

struct RecipeCardView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                )
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 200)
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct MealDetailView: View {
    let meal: Meal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let url = meal.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color(.systemGray5)
                                .frame(height: 220)
                        case .success(let image):
                            ZStack(alignment: .topTrailing) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 260)
                                    .clipped()

                                // Favorite heart button
                                FavoriteHeartButton(meal: meal)
                                    .padding(12)
                            }
                        case .failure:
                            Color(.systemGray4)
                                .frame(height: 220)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Text(meal.title)
                    .font(.title.bold())
                    .padding(.horizontal)

                if let category = meal.strCategory {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                if let instructions = meal.strInstructions {
                    Text(instructions)
                        .padding(.horizontal)
                }

                if !meal.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ingrédients")
                            .font(.headline)
                            .padding(.top)
                        ForEach(Array(meal.ingredients.enumerated()), id: \ .offset) { _, pair in
                            HStack {
                                Text(pair.name)
                                Spacer()
                                Text(pair.measure)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
        }
        .navigationTitle(meal.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Small reusable favorite button
struct FavoriteHeartButton: View {
    let meal: Meal
    @StateObject private var store = FavoriteStore.shared

    var body: some View {
        Group {
            if let id = meal.idMeal {
                Button {
                    store.toggle(id: id)
                } label: {
                    Image(systemName: store.isFavorite(id: id) ? "heart.fill" : "heart")
                        .foregroundColor(store.isFavorite(id: id) ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())
                }
            }
        }
    }
}

/// Loader view: when we only have a summary (from filter.php) we fetch full details by id
struct MealDetailLoader: View {
    let mealSummary: Meal
    @State private var fullMeal: Meal?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let m = fullMeal {
                MealDetailView(meal: m)
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Chargement...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Détails indisponibles")
            }
        }
        .task {
            await loadFull()
        }
    }

    private func loadFull() async {
        isLoading = true
        errorMessage = nil
        // try to lookup by idMeal
        guard let id = mealSummary.idMeal else {
            errorMessage = "Identifiant de recette manquant"
            isLoading = false
            return
        }
        do {
            if let fetched = try await MealService.shared.lookupMeal(id: id) {
                self.fullMeal = fetched
            } else {
                self.errorMessage = "Aucun détail trouvé pour cette recette"
            }
        } catch {
            self.errorMessage = "Erreur: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

#Preview {
    HomeView()
}
