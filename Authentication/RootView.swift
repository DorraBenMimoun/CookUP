//
//  RootView.swift
//  CookUP
//
//  Created by Tekup-mac-7 on 29/10/2025.
//

import SwiftUI


struct RootView: View {
    @State private var showSignInView: Bool = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .navigationTitle("CookUp")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Accueil", systemImage: "house.fill")
            }

            NavigationStack {
                IngredientSearchView()
            }
            .tabItem {
                Label("Ingrédients", systemImage: "leaf.fill")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favoris", systemImage: "heart.fill")
            }

            NavigationStack {
                SettingsView(showSignInView: $showSignInView)
            }
            .tabItem {
                Label("Réglages", systemImage: "gearshape.fill")
            }
        }
        // NOTE: Login is now optional. We no longer present the sign-in flow automatically
        // when the app appears. The `showSignInView` binding can still be triggered from
        // other views (for example the SettingsView "Log out" button) to present the
        // authentication UI when the user chooses to sign in or when they log out.
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        }
    }
}

#Preview {
    RootView()
}
