import SwiftUI

struct LoginView: View {
    @EnvironmentObject var trackStore: ServiceDataSource
    var body: some View {
        if trackStore.hasAccount {
            ExistingUserLoginView()
        } else {
            NewUserSignUpView()
        }
    }
}
struct ExistingUserLoginView: View {
    @EnvironmentObject var trackStore: ServiceDataSource

    @State private var emailAddress: String = ""
    @State private var password: String = ""
    var body: some View {
        VStack {
            LoginViewHeader(text: "Welcome Back!")
            MyTextField(placeholder: "Email Address", textValue: $emailAddress, type: .emailAddress)
            MyTextField(placeholder: "Password", textValue: $password, type: .password)
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
                trackStore.hasAccount = false
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

struct MyTextField: View {
    let placeholder: String
    @Binding var textValue: String
    let type: UITextContentType
    var isSecure: Bool {
        type == .password || type == .newPassword
    }

    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $textValue)
                .textContentType(type)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
        } else {
            TextField(placeholder, text: $textValue)
                .textContentType(type)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
        }
    }
}

struct NewUserSignUpView: View {
    @EnvironmentObject var trackStore: ServiceDataSource

    @State private var name: String = ""
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    var body: some View {
        VStack {
            LoginViewHeader(text: "Welcome!")
            MyTextField(placeholder: "Name", textValue: $name, type: .name)
            MyTextField(placeholder: "Email Address", textValue: $emailAddress, type: .emailAddress)
            MyTextField(placeholder: "Password", textValue: $password, type: .password)
            MyTextField(placeholder: "Confirm Password", textValue: $confirmPassword, type: .password)
            if (trackStore.loginErrorString != nil) {
                Text("some error").foregroundColor(.red)
            }
            Button("Sign up") {
                do {
                    try trackStore.signUp(
                        name: name,
                        email: emailAddress,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                } catch {
                    print("Error setting up the login request \(error)")
                }
            }
            Spacer()
            Text("Already have a login?")
            Button("Log in") {
                trackStore.hasAccount = true
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
