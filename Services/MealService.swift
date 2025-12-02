import Foundation

enum MealServiceError: Error {
    case invalidURL
    case requestFailed
    case decodingError(Error)
}

final class MealService {
    static let shared = MealService()
    private init() {}

    /// Search meals by name using TheMealDB
    func searchMeals(query: String) async throws -> [Meal] {
        guard var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/search.php") else {
            throw MealServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "s", value: query)]
        guard let url = components.url else { throw MealServiceError.invalidURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }

        do {
            let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
            return decoded.meals ?? []
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }

    /// Search using multiple keywords in parallel and return deduplicated meals
    func searchMeals(keywords: [String]) async throws -> [Meal] {
        var allMeals: [Meal] = []
        // Use TaskGroup to parallelize
        try await withThrowingTaskGroup(of: [Meal].self) { group in
            for kw in keywords {
                group.addTask {
                    return try await self.searchMeals(query: kw)
                }
            }

            for try await result in group {
                allMeals.append(contentsOf: result)
            }
        }

        // Deduplicate by idMeal
        var seen: Set<String> = []
        let deduped = allMeals.filter { meal in
            let id = meal.idMeal ?? meal.id
            if seen.contains(id) { return false }
            seen.insert(id)
            return true
        }
        return deduped
    }

    /// Filter meals by category using filter.php?c=Category
    func filterMeals(byCategory category: String) async throws -> [Meal] {
        guard var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/filter.php") else {
            throw MealServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "c", value: category)]
        guard let url = components.url else { throw MealServiceError.invalidURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }

        do {
            // Response shape for filter.php is similar: meals -> [ { idMeal, strMeal, strMealThumb } ]
            let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
            return decoded.meals ?? []
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }

    /// Get a single random meal using random.php
    func randomMeal() async throws -> Meal {
        guard let url = URL(string: "https://www.themealdb.com/api/json/v1/1/random.php") else {
            throw MealServiceError.invalidURL
        }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }
        do {
            let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
            if let first = decoded.meals?.first {
                return first
            }
            throw MealServiceError.requestFailed
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }

    /// Fetch multiple random meals (deduplicated)
    func randomMeals(count: Int) async throws -> [Meal] {
        var results: [Meal] = []
        try await withThrowingTaskGroup(of: Meal.self) { group in
            for _ in 0..<count {
                group.addTask { try await self.randomMeal() }
            }

            for try await meal in group {
                results.append(meal)
            }
        }

        // dedupe by id
        var seen = Set<String>()
        return results.filter { meal in
            let id = meal.idMeal ?? meal.id
            if seen.contains(id) { return false }
            seen.insert(id)
            return true
        }
    }

    /// Lookup a meal by id using lookup.php?i=ID and return full details
    func lookupMeal(id: String) async throws -> Meal? {
        guard var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/lookup.php") else {
            throw MealServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "i", value: id)]
        guard let url = components.url else { throw MealServiceError.invalidURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }

        do {
            let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
            return decoded.meals?.first
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }

    /// List all available ingredients using list.php?i=list
    func listIngredients() async throws -> [Ingredient] {
        guard let url = URL(string: "https://www.themealdb.com/api/json/v1/1/list.php?i=list") else {
            throw MealServiceError.invalidURL
        }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }

        do {
            let decoded = try JSONDecoder().decode(IngredientResponse.self, from: data)
            return decoded.meals ?? []
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }

    /// Filter meals by ingredient using filter.php?i=INGREDIENT
    func filterMeals(byIngredient ingredient: String) async throws -> [Meal] {
        guard var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/filter.php") else {
            throw MealServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "i", value: ingredient)]
        guard let url = components.url else { throw MealServiceError.invalidURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MealServiceError.requestFailed
        }

        do {
            let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
            return decoded.meals ?? []
        } catch {
            throw MealServiceError.decodingError(error)
        }
    }
}
