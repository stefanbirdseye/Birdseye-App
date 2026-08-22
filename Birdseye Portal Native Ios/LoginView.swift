import SwiftUI

struct LoginView: View {
    @Binding var flow: AppFlow

    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BrandLogoView(foregroundStyle: .birdseyeNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                Text("Log in")
                    .font(.largeTitle.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Username or e-mail *", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .focused($focusedField, equals: .username)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)

                    HStack(spacing: 8) {
                        Group {
                            if isPasswordVisible {
                                TextField("Password *", text: $password)
                            } else {
                                SecureField("Password *", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separator), lineWidth: 1)
                    }
                    .frame(minHeight: 44)
                }

                Button("Log In") {
                    focusedField = nil
                    flow = .main
                }
                .buttonStyle(.glassProminent)
                .tint(.birdseyeNavy)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 44)

                HStack(spacing: 12) {
                    Divider()
                    Text("or")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Divider()
                }

                Button {
                } label: {
                    Label("Continue with Google", systemImage: "g.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minHeight: 44)

                Button {
                } label: {
                    VStack(spacing: 4) {
                        Text("Have company credentials?")
                            .font(.headline)
                        Text("Sign in with your company SSO.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minHeight: 64)

                Button("Forgot Password?") {
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoginView(flow: .constant(.login))
}
