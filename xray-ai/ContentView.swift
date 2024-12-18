//
//  ContentView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 04/12/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        BaseView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HistoryManager())
    }
}
