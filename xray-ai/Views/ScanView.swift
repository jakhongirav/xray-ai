//
//  ScanView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 16/12/24.
//

import PhotosUI
import SwiftUI
import Vision

struct ScanView: View {
    @Binding var showMenu: Bool
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var analysis: XRayAnalysis?
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject private var historyManager: HistoryManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            mainContent
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("X-ray Analysis")
        .sheet(isPresented: $showImagePicker) {
            PhotosPicker(selection: $viewModel.imageSelection,
                        matching: .images,
                        photoLibrary: .shared()) {
                Label("Select X-ray Image", systemImage: "photo")
            }
        }
        .onChange(of: viewModel.detailedAnalysis) { oldValue, newValue in
            if let newAnalysis = newValue {
                analysis = newAnalysis
                // Save to history
                historyManager.addItem(
                    diagnosis: newAnalysis.classification,
                    confidence: Double(newAnalysis.confidence),
                    severity: newAnalysis.severity,
                    recommendations: newAnalysis.recommendations
                )
            }
        }
        .onChange(of: viewModel.selectedImage) { oldValue, newValue in
            selectedImage = newValue
        }
    }

    private var mainContent: some View {
        VStack {
            imageSection
            selectImageButton
            analysisLoadingIndicator
            if let analysis = analysis {
                analysisResultCard(analysis: analysis)
            }
            Spacer()
        }
    }

    private var imageSection: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    .padding()
            } else {
                ImagePlaceholder()
            }
        }
    }

    private var selectImageButton: some View {
        Button {
            showImagePicker = true
        } label: {
            Label("Select X-ray Image", systemImage: "photo")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }

    private var analysisLoadingIndicator: some View {
        Group {
            if analysis == nil && selectedImage != nil {
                ProgressView("Analyzing X-ray...")
                    .padding()
            }
        }
    }

    private func analysisResultCard(analysis: XRayAnalysis) -> some View {
        VStack(spacing: 16) {
            // Header
            analysisHeader(analysis: analysis)

            // Description
            analysisDescription(analysis: analysis)

            // Recommendations
            recommendationsSection(recommendations: analysis.recommendations)

            // Other Possibilities
            if !analysis.otherPossibilities.isEmpty {
                otherPossibilitiesSection(possibilities: analysis.otherPossibilities)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }

    private func analysisHeader(analysis: XRayAnalysis) -> some View {
        VStack(spacing: 8) {
            Text(analysis.classification)
                .font(.title2)
                .bold()
                .foregroundColor(.primary)

            Text("Confidence: \(Int(analysis.confidence * 100))%")
                .foregroundColor(.secondary)

            Text(analysis.severity.rawValue)
                .font(.headline)
                .foregroundColor(analysis.severity.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(analysis.severity.color.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.bottom, 8)
    }

    private func analysisDescription(analysis: XRayAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis")
                .font(.headline)
            Text(analysis.description)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    private func recommendationsSection(recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.headline)
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text(recommendation)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func otherPossibilitiesSection(possibilities: [(label: String, confidence: Float)])
        -> some View
    {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other Possibilities")
                .font(.headline)
            ForEach(possibilities, id: \.label) { prediction in
                HStack {
                    Text(prediction.label)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(prediction.confidence * 100))%")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(uiColor: .secondarySystemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                    Text("Select an X-ray image")
                        .font(.headline)
                }
                .foregroundColor(.secondary)
            )
            .padding()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    NavigationView {
        ScanView(showMenu: .constant(false))
            .environmentObject(HistoryManager())
    }
}
