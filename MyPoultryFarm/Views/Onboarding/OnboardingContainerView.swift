//
//  OnboardingContainerView.swift
//  MyPoultryFarm
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var prefillName: String = ""
    var onFinished: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Progress bar
                ProgressView(value: viewModel.stepProgress)
                    .tint(.green)
                    .padding(.horizontal)
                    .padding(.top)

                HStack {
                    Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // MARK: - Content
                Group {
                    switch viewModel.currentStep {
                    case .profile:
                        ProfileSetupView(viewModel: viewModel)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    case .farms:
                        FarmSetupView(viewModel: viewModel)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)

                // MARK: - Navigation buttons
                HStack(spacing: 16) {
                    if !viewModel.isFirstStep {
                        Button {
                            viewModel.back()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                        }
                    }

                    Button {
                        if viewModel.isLastStep {
                            viewModel.finish()
                        } else {
                            viewModel.next()
                        }
                    } label: {
                        HStack {
                            Text(viewModel.isLastStep ? "Finish Setup" : "Continue")
                            if !viewModel.isLastStep {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup Your Farm")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Saving your farms…")
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .onAppear {
                viewModel.onComplete = onFinished
                if !prefillName.isEmpty && viewModel.fullName.isEmpty {
                    viewModel.fullName = prefillName
                }
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    OnboardingContainerView(onFinished: {})
}
