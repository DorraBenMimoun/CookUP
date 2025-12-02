import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @Binding var showSignInView: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            if let err = errorMessage {
                Text(err).foregroundColor(.red).font(.caption)
            }

            Button {
                Task {
                    await signIn()
                }
            } label: {
                if isLoading { ProgressView().frame(maxWidth: .infinity, minHeight: 44) }
                else {
                    Text("Log In")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Log In")
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await AuthenticationManager.shared.signInUser(email: email, password: password)
            // FavoriteStore listens to auth state changes and will load favorites
            DispatchQueue.main.async {
                showSignInView = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { LoginView(showSignInView: .constant(true)) }
    }
}
