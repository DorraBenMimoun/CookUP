import Foundation

// Response wrapper for ingredient list
struct IngredientResponse: Decodable {
    let meals: [Ingredient]?
}

struct Ingredient: Decodable, Identifiable {
    var id: String { idIngredient ?? UUID().uuidString }
    let idIngredient: String?
    let strIngredient: String?
    let strDescription: String?
    let strThumb: String?
    let strType: String?
}
