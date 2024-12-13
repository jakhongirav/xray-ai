//  SideMenu.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 12/12/24.
//

import SwiftUI

struct SideMenu: View {
    @Binding var showMenu: Bool
    @State var messageText: String = ""
    @State private var selectedTab: String = "Chat"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                TextField("Enter the message", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        Divider()
                        VStack(alignment: .leading, spacing: 45) {
                            // Tab buttons...
                            TabButton(title: "Chat", image: "ellipsis.message", selectedTab: $selectedTab, destination: HomeView(showMenu: .constant(false)))
                            TabButton(title: "X-ray", image: "apple.image.playground", selectedTab: $selectedTab, destination: ScanView())
                        }
                        .padding()
                        .padding(.leading)
                        .padding(.top,35)
                        Divider()
                    }
                }
                Divider()
                
                // Profile...
                HStack {
                    Button {} label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .imageScale(.large)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.vertical)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Jile L").font(.subheadline).foregroundColor(.black)
                                Text("jakhongirav@mail.ru").font(.footnote).tint(.gray)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis").foregroundColor(.gray)
                    }
                }
                .padding([.horizontal],15)
                .padding(.bottom,safeArea().bottom == 0 ? 15 : 0)
                .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity,alignment: .leading)
        // Max Width...
        .frame(width: getRect().width - 90)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary
                .opacity(0.04)
                .ignoresSafeArea(.container, edges: .vertical)
        )
        .frame(maxWidth: .infinity,alignment: .leading)
    }
    
    @ViewBuilder
    func TabButton<Destination: View>(title: String, image: String, selectedTab: Binding<String>, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                Text(title)
            }
            .padding()
            .background(selectedTab.wrappedValue == title ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(10)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                selectedTab.wrappedValue = title
            }
        }
    }
}

struct ScanView: View {
    var body: some View {
        Text("Scan View")
            .navigationTitle("X-ray")
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

#Preview {
    ContentView()
}
