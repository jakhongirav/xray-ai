import SwiftUI

struct ChatView: View {
    @State private var messages: [String] = ["Hello! How can I help you?"]
    @State private var inputText: String = ""

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }
        messages.append(inputText)
        inputText = ""
    }
}

struct ChatBubble: View {
    var message: String

    var body: some View {
        HStack {
            Text(message)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .frame(maxWidth: 300, alignment: .leading)
            Spacer()
        }
    }
}

