//
//  xray_aiApp.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 04/12/24.
//

import SwiftUI

@main
struct xray_aiApp: App {
    @StateObject private var historyManager = HistoryManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyManager)
        }
    }
}
