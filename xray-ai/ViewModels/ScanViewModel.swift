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
        subsystem: Bundle.main.bundleIdentifier ?? "xray-ai",
        category: "ML Classification"
    )

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

            // Log model metadata
            let description = model.modelDescription
            logger.info("📋 Model Metadata:")
            logger.info("Input Description: \(description.inputDescriptionsByName)")
            logger.info("Output Description: \(description.outputDescriptionsByName)")

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
                    !results.isEmpty
                else {
                    self?.logger.error("❌ No classification results")
                    print("❌ No classification results")
                    return
                }

                DispatchQueue.main.async {
                    // Print raw results for debugging
                    print("\n🔍 ML CLASSIFICATION RESULTS:")
                    print("--------------------------------")
                    results.forEach { result in
                        print(
                            "Label: '\(result.identifier)' - Confidence: \(Int(result.confidence * 100))%"
                        )
                    }
                    print("--------------------------------\n")

                    // Store all predictions
                    self?.allPredictions = results.map { ($0.identifier, $0.confidence) }

                    // Get the top result
                    let topResult = results[0]
                    print(
                        "📝 Top Result: '\(topResult.identifier)' (\(Int(topResult.confidence * 100))%)"
                    )

                    // Map the ML model's output to our expected categories
                    let mappedClass = self?.mapClassification(topResult.identifier)
                    print("🎯 Mapped to: '\(mappedClass ?? "unknown")'")

                    self?.classificationResult = mappedClass
                    self?.confidence = topResult.confidence

                    // Create detailed analysis
                    if let mappedClass = mappedClass {
                        let analysis = XRayAnalysis.getAnalysis(
                            for: mappedClass,
                            confidence: topResult.confidence
                        )

                        // Add other possibilities
                        var analysisWithPossibilities = analysis
                        if results.count > 1 {
                            let mappedPossibilities = Array(results.dropFirst().prefix(3))
                                .map {
                                    (
                                        self?.mapClassification($0.identifier) ?? $0.identifier,
                                        $0.confidence
                                    )
                                }

                            analysisWithPossibilities = XRayAnalysis(
                                classification: analysis.classification,
                                confidence: analysis.confidence,
                                description: analysis.description,
                                recommendations: analysis.recommendations,
                                severity: analysis.severity,
                                otherPossibilities: mappedPossibilities
                            )
                        }

                        self?.detailedAnalysis = analysisWithPossibilities
                        print("📊 Final Analysis: \(analysisWithPossibilities.classification)")
                    }

                    self?.isAnalyzing = false
                }
            }
        } catch {
            self.error = error.localizedDescription
            logger.error("❌ Failed to setup classifier: \(error.localizedDescription)")
        }
    }

    private func mapClassification(_ original: String) -> String {
        NSLog("🔄 Mapping classification:")
        NSLog("Input: '\(original)'")
        
        let result: String
        switch original {
        case "COVID-19":
            result = "COVID-19"
        case "Normal":
            result = "Normal"
        case "Pneumonia-Bacterial":
            result = "Bacterial Pneumonia"
        case "Pneumonia-Viral":
            result = "Viral Pneumonia"
        default:
            NSLog("⚠️ WARNING: Unexpected classification: '\(original)'")
            result = original
        }
        
        NSLog("Output: '\(result)'")
        return result
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
        guard let request = classificationRequest else {
            NSLog("⚠️ Classification request is nil")
            return 
        }

        guard let ciImage = CIImage(image: image) else {
            NSLog("⚠️ Failed to create CIImage")
            error = "Failed to create CIImage"
            isAnalyzing = false
            return
        }

        NSLog("📸 Starting classification...")
        let handler = VNImageRequestHandler(ciImage: ciImage)

        Task {
            do {
                try handler.perform([request])
                
                // Get raw results immediately after perform
                if let observations = request.results as? [VNClassificationObservation] {
                    NSLog("🔍 RAW RESULTS FROM MODEL:")
                    NSLog("Number of classifications: \(observations.count)")
                    observations.forEach { observation in
                        NSLog("- \(observation.identifier): \(observation.confidence)")
                    }
                } else {
                    NSLog("⚠️ No observations found or wrong type")
                }
                
            } catch {
                NSLog("❌ Classification error: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
}
