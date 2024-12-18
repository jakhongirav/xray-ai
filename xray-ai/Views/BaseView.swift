import SwiftUI

struct BaseView: View {
    @State var showMenu: Bool = false
    @State var currentTab = "Chat"
    
    @State private var offset: CGFloat = 0
    @State private var lastStoredOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0
    
    private let sideBarWidth: CGFloat = UIScreen.main.bounds.width - 90
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        let drag = DragGesture()
            .updating($gestureOffset) { value, out, _ in
                out = value.translation.width
            }
            .onEnded(onEnd)
        
        return HStack(spacing: 0) {
            SideMenu(showMenu: $showMenu, selectedTab: $currentTab)
            
            NavigationView {
                VStack(spacing: 0) {
//                    if currentTab == "Chat" {
//                        HomeView(showMenu: $showMenu)
//                    } else {
                        ScanView(showMenu: $showMenu)
//                    }
                }
                .navigationTitle(currentTab)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(action: toggleMenu) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                )
            }
            .frame(width: getRect().width)
            .overlay(
                Color.black
                    .opacity(showMenu ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut) {
                            closeMenu()
                        }
                    }
            )
        }
        .frame(width: getRect().width + sideBarWidth)
        .offset(x: -sideBarWidth / 2)
        .offset(x: offset)
        .gesture(drag)
        .onChange(of: gestureOffset) { _, newValue in
            onChange()
        }
        .onChange(of: currentTab) { _, _ in
            closeMenu()
        }
    }
    
    private func toggleMenu() {
        withAnimation(.easeOut) {
            if showMenu {
                closeMenu()
            } else {
                openMenu()
            }
        }
    }
    
    private func openMenu() {
        offset = sideBarWidth
        lastStoredOffset = offset
        showMenu = true
    }
    
    private func closeMenu() {
        offset = 0
        lastStoredOffset = 0
        showMenu = false
    }
    
    private func onChange() {
        let newOffset = gestureOffset + lastStoredOffset
        offset = max(0, min(sideBarWidth, newOffset))
    }
    
    private func onEnd(value: DragGesture.Value) {
        let translation = value.translation.width
        
        withAnimation(.easeOut) {
            if translation > 0 {
                if translation > (sideBarWidth / 3) {
                    offset = sideBarWidth
                    showMenu = true
                } else {
                    closeMenu()
                }
            } else {
                if -translation > (sideBarWidth / 3) {
                    closeMenu()
                } else {
                    offset = sideBarWidth
                    showMenu = true
                }
            }
            lastStoredOffset = offset
        }
    }
}

#Preview {
    BaseView()
        .environmentObject(HistoryManager())
}
