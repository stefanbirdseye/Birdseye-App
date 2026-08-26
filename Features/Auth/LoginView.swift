import SwiftUI

struct LoginView: View {

    @Binding var flow: AppFlow

    @Environment(\.colorScheme) private var colorScheme

    @State private var username = "maya@northstar.com"
    @State private var password = "birdseye-demo"
    @State private var showPassword = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    private var canSubmit: Bool {
        !username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty && !password.isEmpty
    }

    var body: some View {

        NavigationStack {

            ZStack {

                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    VStack(spacing: 28) {

                        Form {

                            Section {

                                HStack(spacing: 12) {

                                    Image(systemName: "person")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)

                                    TextField(
                                        "Username or email",
                                        text: $username
                                    )
                                    .keyboardType(.emailAddress)
                                    .textContentType(.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .username)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                                }

                                HStack(spacing: 12) {

                                    Image(systemName: "lock")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)

                                    Group {

                                        if showPassword {

                                            TextField(
                                                "Password",
                                                text: $password
                                            )

                                        } else {

                                            SecureField(
                                                "Password",
                                                text: $password
                                            )
                                        }
                                    }
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                    }

                                    Button {
                                        HapticFeedback.lightImpact()
                                        showPassword.toggle()
                                    } label: {

                                        Image(
                                            systemName: showPassword
                                                ? "eye.slash"
                                                : "eye"
                                        )
                                        .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle())
                                    .accessibilityLabel(
                                        showPassword
                                            ? "Hide password"
                                            : "Show password"
                                    )
                                }

                            } header: {

                                Text("Welcome back")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                            }
                        }
                        .frame(height: 170)
                        .scrollDisabled(true)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)

                        VStack(spacing: 10) {

                            Button(action: submit) {

                                Text("Log In")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                            .disabled(!canSubmit)

                            HStack(spacing: 12) {

                                Rectangle()
                                    .fill(.separator)
                                    .frame(height: 0.5)

                                Text("or")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Rectangle()
                                    .fill(.separator)
                                    .frame(height: 0.5)
                            }

                            Button {
                            } label: {

                                Text("Continue with Google")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)

                            Button {
                            } label: {

                                Text("Sign in with company SSO")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)

                            Button {
                            } label: {

                                Text("Forgot password?")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            .frame(minHeight: 44)
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)

                    Spacer()
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .toolbar {

                ToolbarItem(placement: .principal) {

                    BrandLogoView(
                        foregroundStyle: colorScheme == .dark
                            ? .white
                            : .birdseyeNavy
                    )
                    .frame(width: 116, height: 19)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(.blue)
        }
    }

    private func submit() {

        guard canSubmit else {
            return
        }

        HapticFeedback.success()
        focusedField = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            flow = .main
        }
    }
}

#Preview {
    LoginView(flow: .constant(.login))
}
