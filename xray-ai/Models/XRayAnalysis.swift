import Foundation
import SwiftUI

struct XRayAnalysis {
    let classification: String
    let confidence: Float
    let description: String
    let recommendations: [String]
    let severity: Severity
    let otherPossibilities: [(label: String, confidence: Float)]

    enum Severity: String {
        case normal = "Normal"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"

        var color: Color {
            switch self {
            case .normal: return .green
            case .mild: return .yellow
            case .moderate: return .orange
            case .severe: return .red
            }
        }
    }

    static func getAnalysis(for classification: String, confidence: Float) -> XRayAnalysis {
        // First, normalize the classification string
        let normalizedClass = classification.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalizedClass {
        case "normal", "healthy", "no finding":
            return XRayAnalysis(
                classification: "Normal",
                confidence: confidence,
                description: """
                    The X-ray appears normal with no significant abnormalities detected. 
                    The lung fields are clear, properly inflated, and show normal vascular markings. 
                    No signs of infection, inflammation, or other pathological conditions are present.
                    """,
                recommendations: [
                    "Continue regular health check-ups",
                    "Maintain good respiratory health practices",
                    "Practice preventive measures (hand washing, avoiding sick contacts)",
                    "Stay up to date with vaccinations",
                ],
                severity: .normal,
                otherPossibilities: []
            )

        case "viral pneumonia", "pneumonia-viral":
            return XRayAnalysis(
                classification: "Viral Pneumonia",
                confidence: confidence,
                description: """
                    Findings suggest viral pneumonia. The X-ray shows characteristic patterns including:
                    • Bilateral interstitial infiltrates
                    • Ground-glass opacities
                    • Possible bronchial wall thickening
                    • Diffuse, patchy distribution
                    """,
                recommendations: [
                    "Seek immediate medical attention",
                    "Rest and maintain good hydration",
                    "Monitor temperature and breathing",
                    "Consider antiviral medication if appropriate",
                    "Follow-up chest X-ray recommended in 2-3 weeks",
                ],
                severity: confidence > 0.85 ? .moderate : .mild,
                otherPossibilities: []
            )

        case "bacterial pneumonia", "pneumonia-bacterial":
            return XRayAnalysis(
                classification: "Bacterial Pneumonia",
                confidence: confidence,
                description: """
                    Findings indicate bacterial pneumonia. Key features include:
                    • Lobar consolidation
                    • Possible pleural effusion
                    • Dense opacification
                    • Often unilateral involvement
                    """,
                recommendations: [
                    "Immediate antibiotic treatment required",
                    "Regular monitoring of vital signs",
                    "Complete full course of prescribed antibiotics",
                    "Follow-up chest X-ray in 1-2 weeks",
                    "Deep breathing exercises when appropriate",
                ],
                severity: confidence > 0.85 ? .severe : .moderate,
                otherPossibilities: []
            )

        case "covid-19", "covid":
            return XRayAnalysis(
                classification: "COVID-19",
                confidence: confidence,
                description: """
                    Signs consistent with COVID-19 pneumonia detected. Typical features include:
                    • Bilateral ground-glass opacities
                    • Peripheral and basal predominance
                    • Multiple patchy consolidations
                    • 'Crazy-paving' pattern
                    """,
                recommendations: [
                    "Immediate isolation required",
                    "Contact healthcare provider for treatment plan",
                    "Monitor oxygen saturation levels regularly",
                    "Follow COVID-19 protocols and guidelines",
                    "Consider additional testing (PCR test)",
                    "Alert recent contacts",
                ],
                severity: confidence > 0.85 ? .severe : .moderate,
                otherPossibilities: []
            )

        default:
            return XRayAnalysis(
                classification: "Inconclusive",
                confidence: confidence,
                description: """
                    The analysis is inconclusive. This could be due to:
                    • Image quality issues
                    • Unusual presentation
                    • Overlapping patterns
                    • Need for additional views
                    """,
                recommendations: [
                    "Consider retaking the X-ray",
                    "Consult with a healthcare provider",
                    "Consider additional imaging (CT scan)",
                    "Provide complete medical history",
                ],
                severity: .moderate,
                otherPossibilities: []
            )
        }
    }
}
