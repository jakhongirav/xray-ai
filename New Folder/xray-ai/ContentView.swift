//
//  ContentView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 04/12/24.
//

import SwiftUI

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var messages: [String] = ["Welcome to X-Ray AI! How can I assist you?"]

    var body: some View {
        NavigationStack {
            VStack {
                // Chat Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(messages, id: \.self) { message in
                            ChatBubble(message: message, isUser: message == messages.last)
                        }
                    }
                    .padding()
                }

                // Input Bar
                HStack {
                    TextField("Type a message...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("X-Ray AI")
        }
    }

    func sendMessage() {
        guard !userInput.isEmpty else { return }
        messages.append(userInput)
        userInput = ""
    }
}

struct ChatBubble: View {
    var message: String
    var isUser: Bool

    var body: some View {
        HStack {
            if !isUser {
                Spacer()
            }
            Text(message)
                .padding()
                .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .black)
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        }
        .padding(isUser ? .leading : .trailing, 50)
    }
}

#Preview {
    ContentView()
}
