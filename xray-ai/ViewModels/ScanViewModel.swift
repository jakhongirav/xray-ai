import CoreML
import PhotosUI
import SwiftUI
import Vision
import os

@MainActor
class ScanViewModel: ObservableObject {
    @Published var imageSelection: PhotosPickerItem? {
        didSet { loadImage() }
    }
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var classificationResult: String?
    @Published var confidence: Float?
    @Published var error: String?
    @Published var allPredictions: [(label: String, confidence: Float)] = []
    @Published var detailedAnalysis: XRayAnalysis?

    private var classificationRequest: VNCoreMLRequest?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "xray-ai", category: "ML Classification")

    init() {
        setupClassifier()
    }

    private func setupClassifier() {
        guard let modelURL = Bundle.main.url(forResource: "pneumonia", withExtension: "mlmodelc")
        else {
            error = "Failed to find the ML model"
            logger.error("❌ ML Model not found in bundle")
            return
        }

        do {
            let config = MLModelConfiguration()
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            let vnModel = try VNCoreMLModel(for: model)

            logger.info("✅ ML Model loaded successfully")

            classificationRequest = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.error = error.localizedDescription
                        self?.logger.error("❌ Classification error: \(error.localizedDescription)")
                    }
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                    !results.isEmpty else {
                    self?.logger.error("❌ No classification results")
                    return
                }

                DispatchQueue.main.async {
                    // Store all predictions for reference
                    self?.allPredictions = results.map { ($0.identifier, $0.confidence) }

                    // Log all predictions for debugging
                    self?.logger.info("📊 Classification Results:")
                    results.forEach { result in
                        self?.logger.info(
                            "   \(result.identifier): \(Int(result.confidence * 100))%")
                    }

                    // Get the top result
                    let topResult = results[0]
                    self?.classificationResult = topResult.identifier
                    self?.confidence = topResult.confidence

                    // Create detailed analysis
                    let analysis = XRayAnalysis.getAnalysis(
                        for: topResult.identifier,
                        confidence: topResult.confidence
                    )
                    
                    // Add other possibilities to the analysis
                    var analysisWithPossibilities = analysis
                    if results.count > 1 {
                        analysisWithPossibilities = XRayAnalysis(
                            classification: analysis.classification,
                            confidence: analysis.confidence,
                            description: analysis.description,
                            recommendations: analysis.recommendations,
                            severity: analysis.severity,
                            otherPossibilities: Array(results.dropFirst().prefix(3))
                                .map { ($0.identifier, $0.confidence) }
                        )
                    }
                    
                    self?.detailedAnalysis = analysisWithPossibilities
                    self?.isAnalyzing = false
                }
            }
        } catch {
            self.error = error.localizedDescription
            logger.error("❌ Failed to setup classifier: \(error.localizedDescription)")
        }
    }

    private func loadImage() {
        guard let imageSelection else { return }

        isAnalyzing = true
        classificationResult = nil
        confidence = nil
        error = nil
        allPredictions.removeAll()
        detailedAnalysis = nil

        Task {
            do {
                guard let data = try await imageSelection.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: data)
                else {
                    error = "Failed to load the selected image"
                    isAnalyzing = false
                    return
                }

                selectedImage = uiImage
                classifyImage(uiImage)
            } catch {
                self.error = error.localizedDescription
                isAnalyzing = false
            }
        }
    }

    private func classifyImage(_ image: UIImage) {
        guard let request = classificationRequest else { return }

        guard let ciImage = CIImage(image: image) else {
            error = "Failed to create CIImage"
            isAnalyzing = false
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        Task {
            do {
                try handler.perform([request])
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
}
