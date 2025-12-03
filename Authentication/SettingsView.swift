//
//  SettingsView.swift
//  CookUP
//
//  Created by Tekup-mac-7 on 29/10/2025.
//

import SwiftUI
import Combine
@MainActor
final class SettingsViewModel: ObservableObject {
    func signOut() throws{
        try AuthenticationManager.shared.signOut()
        
    }
}
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log out"){
                Task {
                    do {
                        try viewModel.signOut()
                        showSignInView = true
                    }catch {
                        print(error)
                    }
                }
            }
        }
        .navigationTitle("Settings")

    }
}

#Preview {
    SettingsView(showSignInView: .constant(false))
}
extension SettingsView{
}
