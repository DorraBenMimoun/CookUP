//
//  AuthenticationView.swift
//  CookUP
//
//  Created by Tekup-mac-7 on 29/10/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @Binding var showSignInView: Bool
    var body: some View {
        VStack(spacing: 12) {
            NavigationLink {
                LoginView(showSignInView: $showSignInView)
            } label: {
                Text("Log In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            NavigationLink {
                SignUpView(showSignInView: $showSignInView)
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Account")
    }
}

#Preview {
    NavigationStack{
        AuthenticationView(showSignInView: .constant(false))
        
    }
}
