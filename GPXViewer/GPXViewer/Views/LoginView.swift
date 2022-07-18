import SwiftUI

class AccountViewState: ObservableObject {
    @Published var hasAccount = true
}

struct LoginView: View {
    @ObservedObject private var accountState: AccountViewState = AccountViewState()
    var body: some View {
        if accountState.hasAccount {
            ExistingUserLoginView(accountState: accountState)
        } else {
            NewUserSignUpView(accountState: accountState)
        }
    }
}
struct ExistingUserLoginView: View {
    @EnvironmentObject var trackStore: ServiceDataSource

    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @ObservedObject var accountState: AccountViewState
    var body: some View {
        VStack {
            LoginViewHeader(text: "Welcome Back!")
            TextField("Email Address", text: $emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Button("Login") {
                do {
                    try trackStore.login(email: "cool@exampleromaw.com", password: "secret42")
                } catch {
                    print("Error setting up the login request \(error)")
                }
            }
            Spacer()
            Text("Don't have a login?")
            Button("Sign up") {
                accountState.hasAccount = false
            }
        }
        .padding()

    }
}
struct LoginViewHeader: View {
    let text: String
    var body: some View {
        VStack {
            Text(text)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom, 20)
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .padding(.bottom, 75)
        }
    }
}

struct NewUserSignUpView: View {
    @EnvironmentObject var trackStore: ServiceDataSource

    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @ObservedObject var accountState: AccountViewState
    var body: some View {
        VStack {
            LoginViewHeader(text: "Welcome!")
            TextField("Email Address", text: $emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Button("Sign up") {
                print("now log in")
            }
            Spacer()
            Text("Already have a login?")
            Button("Log in") {
                accountState.hasAccount = true
            }
        }
        .padding()

    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
