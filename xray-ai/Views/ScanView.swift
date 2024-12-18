//
//  ScanView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 16/12/24.
//

import SwiftUI

struct ScanView: View {
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack {
            Text("Scan View")
                .font(.largeTitle)
                .padding()
            // Add more UI components for the ScanView here
        }
    }
}

#Preview {
    ScanView(showMenu: .constant(false))
}
