//  SideMenu.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 12/12/24.
//

import SwiftUI

struct SideMenu: View {
    @Binding var showMenu: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var historyManager: HistoryManager
    @State private var selectedHistoryItem: HistoryItem?
    @State private var searchText = ""

    var filteredHistory: [(String, [HistoryItem])] {
        let grouped = historyManager.groupedByDate()
        guard !searchText.isEmpty else { return grouped }

        return grouped.compactMap { date, items in
            let filteredItems = items.filter { item in
                item.diagnosis.localizedCaseInsensitiveContains(searchText)
                    || item.recommendations.joined().localizedCaseInsensitiveContains(searchText)
            }
            return filteredItems.isEmpty ? nil : (date, filteredItems)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section with search and navigation
            VStack(alignment: .leading, spacing: 15) {
                // Search field
                TextField("Search history...", text: $searchText)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                // Navigation buttons
                VStack(alignment: .leading, spacing: 10) {
//                    TabButton(
//                        title: "Chat", image: "ellipsis.message", selectedTab: $selectedTab,
//                        destination: HomeView(showMenu: .constant(false))
//                    )
                    TabButton(
                        title: "X-ray", image: "photo", selectedTab: $selectedTab,
                        destination: ScanView(showMenu: .constant(false))
                    )
                }
                .padding()
                .padding(.top, 35)
            }

            Divider()
                .padding(.vertical)

            // Scrollable history section
            ScrollView(.vertical, showsIndicators: false) {
                if filteredHistory.isEmpty {
                    Text("No history found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(filteredHistory, id: \.0) { date, items in
                        VStack(alignment: .leading) {
                            Text(date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ForEach(items) { item in
                                Button {
                                    selectedHistoryItem = item
                                    selectedTab = "X-ray"
                                    withAnimation {
                                        showMenu.toggle()
                                    }
                                } label: {
                                    HistoryItemView(item: item)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        historyManager.deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }

            Spacer(minLength: 0)

            // Fixed profile section at bottom
            VStack(spacing: 0) {
                Divider()
                    .padding(.vertical)

                HStack {
                    Button {
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .imageScale(.large)
                            VStack(alignment: .leading) {
                                Text("John Doe")
                                    .font(.callout)
                                Text("View Profile")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    Spacer()
                    Button {
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    func TabButton<Destination: View>(
        title: String, image: String, selectedTab: Binding<String>, destination: Destination
    ) -> some View {
        Button {
            withAnimation {
                selectedTab.wrappedValue = title
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .imageScale(.large)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                selectedTab.wrappedValue == title
                    ? Color(
                        uiColor: UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark
                                ? UIColor.systemGray5
                                : UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
                        })
                    : Color.clear
            )
            .foregroundColor(selectedTab.wrappedValue == title ? .blue : .primary)
            .cornerRadius(10)
        }
    }
}

struct HistoryItemView: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.diagnosis)
                .font(.subheadline)
                .foregroundColor(.primary)

            HStack {
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.severity)
                    .font(.caption)
                    .foregroundColor(item.severityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.severityColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Extending View to get Screen Rect...
extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }

    func safeArea() -> UIEdgeInsets {
        let null = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return null
        }

        guard let safeArea = screen.windows.first?.safeAreaInsets else {
            return null
        }

        return safeArea
    }
}

// Preview
struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SideMenu(showMenu: .constant(true), selectedTab: .constant("Home"))
                .environmentObject(HistoryManager())
        }
    }
}
