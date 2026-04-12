//
//  SignUpView.swift
//  MyPoultryFarm
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.green)

                    Text("Create Account")
                        .font(.largeTitle.bold())

                    Text("Join MyPoultryFarm today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // MARK: - Auth Method Picker
                Picker("Sign Up Method", selection: $viewModel.selectedAuthMethod) {
                    Text("Email").tag(LoginMethod.email)
                    Text("Phone").tag(LoginMethod.phone)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Input Fields
                VStack(spacing: 16) {
                    // Name field (shared)
                    TextField("Full Name", text: $viewModel.signUpName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    switch viewModel.selectedAuthMethod {
                    case .email:
                        emailSignUpFields
                    case .phone:
                        phoneSignUpFields
                    }
                }
                .padding(.horizontal)

                // MARK: - Sign Up Button
                signUpButton
                    .padding(.horizontal)

                // MARK: - Divider
                dividerLine

                // MARK: - Google Sign Up
                googleSignUpButton
                    .padding(.horizontal)

                // MARK: - Sign In Link
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign In") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Creating account…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Email Fields

    private var emailSignUpFields: some View {
        Group {
            TextField("Email", text: $viewModel.signUpEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Password", text: $viewModel.signUpPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Confirm Password", text: $viewModel.signUpConfirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Phone Fields

    private var phoneSignUpFields: some View {
        Group {
            HStack {
                TextField("Phone Number", text: $viewModel.signUpPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button("Send OTP") {
                    viewModel.sendSignUpPhoneOTP()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            TextField("OTP", text: $viewModel.signUpOTP)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Sign Up Button

    private var signUpButton: some View {
        Button {
            switch viewModel.selectedAuthMethod {
            case .email:
                viewModel.signUpWithEmail()
            case .phone:
                viewModel.signUpWithPhone()
            }
        } label: {
            Text("Create Account")
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

    // MARK: - Google Sign Up

    private var googleSignUpButton: some View {
        Button {
            viewModel.signUpWithGoogle()
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
    NavigationStack {
        SignUpView(viewModel: AuthViewModel())
    }
}
