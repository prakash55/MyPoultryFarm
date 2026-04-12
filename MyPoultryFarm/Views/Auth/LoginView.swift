//
//  LoginView.swift
//  MyPoultryFarm
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image("chicken_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.green)

                        Text("MyPoultryFarm")
                            .font(.largeTitle.bold())

                        Text("Sign in to your account")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // MARK: - Auth Method Picker
                    Picker("Login Method", selection: $viewModel.selectedAuthMethod) {
                        Text("Email").tag(LoginMethod.email)
                        Text("Phone").tag(LoginMethod.phone)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // MARK: - Input Fields
                    VStack(spacing: 16) {
                        switch viewModel.selectedAuthMethod {
                        case .email:
                            emailLoginFields
                        case .phone:
                            phoneLoginFields
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Login Button
                    loginButton
                        .padding(.horizontal)

                    // MARK: - Divider
                    dividerLine

                    // MARK: - Google Sign In
                    googleSignInButton
                        .padding(.horizontal)

                    // MARK: - Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Signing in…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Email Fields

    private var emailLoginFields: some View {
        Group {
            TextField("Email", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Password", text: $viewModel.loginPassword)
                .textContentType(.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Phone Fields

    private var phoneLoginFields: some View {
        Group {
            HStack {
                TextField("Phone Number", text: $viewModel.loginPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button("Send OTP") {
                    viewModel.sendPhoneOTP()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            TextField("OTP", text: $viewModel.loginOTP)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            switch viewModel.selectedAuthMethod {
            case .email:
                viewModel.loginWithEmail()
            case .phone:
                viewModel.loginWithPhone()
            }
        } label: {
            Text("Sign In")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .cornerRadius(10)
        }
    }

    // MARK: - Divider

    private var dividerLine: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.quaternary)
            Text("OR")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal)
    }

    // MARK: - Google Sign In

    private var googleSignInButton: some View {
        Button {
            viewModel.loginWithGoogle()
        } label: {
            HStack {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Continue with Google")
                    .font(.headline)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
