//
//  HomeView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 09/12/24.
//

import SwiftUI

struct HomeView: View {
    @Binding var showMenu: Bool

    @State private var chatMessages: [ChatMessage] = ChatMessage.sampleMessages
    @State private var messageText: String = ""

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(chatMessages, id: \.id) { message in
                            messageView(message: message)
                        }
                    }
                }
                HStack {
                    TextField("Enter the message", text: $messageText)
                        .padding()
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    Button {
                        sendMessage()
                    } label: {
                        Text("Send")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    func messageView(message: ChatMessage) -> some View {
        HStack {
            if message.sender == .me {
                Spacer()
            }
            Text(message.content)
                .foregroundColor(message.sender == .me ? .white : .secondary)
                .padding()
                .background(message.sender == .me ? Color.accentColor : Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(16)
            if message.sender == .ai {
                Spacer()
            }
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            content: messageText,
            dateCreated: Date(),
            sender: .me
        )
        chatMessages.append(newMessage)
        messageText = ""
    }
}

struct ChatMessage {
    let id: String
    let content: String
    let dateCreated: Date
    let sender: MessageSender
}

enum MessageSender {
    case me
    case ai
}

extension ChatMessage {
    static let sampleMessages = [
        ChatMessage(
            id: UUID().uuidString, content: "Sample message from me", dateCreated: Date(),
            sender: .me),
        ChatMessage(
            id: UUID().uuidString, content: "Sample message from AI", dateCreated: Date(),
            sender: .ai),
        ChatMessage(
            id: UUID().uuidString, content: "Second message from me", dateCreated: Date(),
            sender: .me),
        ChatMessage(
            id: UUID().uuidString, content: "Second message from AI", dateCreated: Date(),
            sender: .ai),
    ]
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(showMenu: .constant(false))
    }
}
