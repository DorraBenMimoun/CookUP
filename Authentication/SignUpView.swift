import SwiftUI

struct SignUpView: View {
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
                Task { await signUp() }
            } label: {
                if isLoading { ProgressView().frame(maxWidth: .infinity, minHeight: 44) }
                else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up")
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await AuthenticationManager.shared.createUser(email: email, password: password)
            // on success the auth listener will trigger FavoriteStore load
            DispatchQueue.main.async {
                showSignInView = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { SignUpView(showSignInView: .constant(true)) }
    }
}
