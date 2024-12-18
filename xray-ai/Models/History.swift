import Foundation
import SwiftUI

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let diagnosis: String
    let confidence: Double
    let severity: String
    let severityColor: Color
    let date: Date
    let recommendations: [String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case id, diagnosis, confidence, severity, date, recommendations
        case severityColor = "severity_color"
    }

    init(
        id: UUID, diagnosis: String, confidence: Double, severity: XRayAnalysis.Severity,
        date: Date, recommendations: [String]
    ) {
        self.id = id
        self.diagnosis = diagnosis
        self.confidence = confidence
        self.severity = severity.rawValue
        self.severityColor = severity.color
        self.date = date
        self.recommendations = recommendations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        diagnosis = try container.decode(String.self, forKey: .diagnosis)
        confidence = try container.decode(Double.self, forKey: .confidence)
        severity = try container.decode(String.self, forKey: .severity)
        date = try container.decode(Date.self, forKey: .date)
        recommendations = try container.decode([String].self, forKey: .recommendations)

        // Convert color components to Color
        let colorData = try container.decode(Data.self, forKey: .severityColor)
        let components = try JSONDecoder().decode([CGFloat].self, from: colorData)
        severityColor = Color(
            .sRGB, red: components[0], green: components[1], blue: components[2],
            opacity: components[3])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(diagnosis, forKey: .diagnosis)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(severity, forKey: .severity)
        try container.encode(date, forKey: .date)
        try container.encode(recommendations, forKey: .recommendations)

        // Convert Color to encodable format
        let uiColor = UIColor(severityColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let components = [red, green, blue, alpha]
        let colorData = try JSONEncoder().encode(components)
        try container.encode(colorData, forKey: .severityColor)
    }
}

class HistoryManager: ObservableObject {
    @Published var items: [HistoryItem] = []
    private let userDefaults = UserDefaults.standard
    private let storageKey = "xray_history"

    init() {
        loadHistory()
    }

    func addItem(
        diagnosis: String, confidence: Double, severity: XRayAnalysis.Severity,
        recommendations: [String]
    ) {
        let newItem = HistoryItem(
            id: UUID(),
            diagnosis: diagnosis,
            confidence: confidence,
            severity: severity,
            date: Date(),
            recommendations: recommendations
        )
        items.insert(newItem, at: 0)
        saveHistory()
    }

    func deleteItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func deleteItems(at offsets: IndexSet, in date: String) {
        let groupedItems = groupedByDate()
        if let group = groupedItems.first(where: { $0.0 == date }) {
            let itemsToDelete = offsets.map { group.1[$0] }
            items.removeAll { item in
                itemsToDelete.contains { $0.id == item.id }
            }
            saveHistory()
        }
    }

    func searchHistory(query: String) -> [HistoryItem] {
        guard !query.isEmpty else { return items }
        return items.filter { item in
            item.diagnosis.localizedCaseInsensitiveContains(query)
                || item.recommendations.joined().localizedCaseInsensitiveContains(query)
        }
    }

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: storageKey),
            let decodedItems = try? JSONDecoder().decode([HistoryItem].self, from: data)
        else {
            return
        }
        items = decodedItems
    }

    private func saveHistory() {
        guard let encodedData = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(encodedData, forKey: storageKey)
    }

    func groupedByDate() -> [(String, [HistoryItem])] {
        let grouped = Dictionary(grouping: items) { item in
            item.formattedDate
        }
        return grouped.sorted { $0.key > $1.key }
    }
}
