//
//  BaseView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 12/12/24.
//

import SwiftUI

struct BaseView: View {
    @State var showMenu: Bool = false
    
    init(){
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab = "Chat"
    @State private var selectedView: AnyView = AnyView(HomeView(showMenu: .constant(false)))
    
    // Offset for Both Drag Gesuture and showing Menu...
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    
    // GEsture Offset...
    @GestureState var gestureOffset: CGFloat = 0
    
    var body: some View {
        // Define constants
        let sideBarWidth: CGFloat = getRect().width - 90
        
        // Main navigation view
        NavigationView {
            // Main content stack
            HStack(spacing: 0) {
                // Side menu component
                SideMenu(showMenu: $showMenu, selectedTab: $currentTab)
                
                // Main content area
                VStack(spacing: 0) {
                    if currentTab == "Chat" {
                        HomeView(showMenu: $showMenu)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    } else {
                        ScanView(showMenu: $showMenu)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    }
                }
                .frame(width: getRect().width)
                .overlay(
                    overlayView(sideBarWidth: sideBarWidth)
                )
            }
            // Container frame and offset
            .frame(width: getRect().width + sideBarWidth)
            .offset(x: -sideBarWidth / 2)
            .offset(x: offset > 0 ? offset : 0)
            // Gesture...
            .gesture(
                DragGesture()
                    .updating($gestureOffset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onEnded({ value in
                        withAnimation {
                            let translation = value.translation.width
                            
                            if translation > 0 {
                                if translation > (sideBarWidth / 2) {
                                    // showing menu...
                                    offset = sideBarWidth
                                    showMenu = true
                                } else {
                                    offset = 0
                                    showMenu = false
                                }
                            } else {
                                if -translation > (sideBarWidth / 2) {
                                    offset = 0
                                    showMenu = false
                                } else {
                                    offset = sideBarWidth
                                    showMenu = true
                                }
                            }
                            
                            lastStoredOffset = offset
                        }
                    })
            )
        }
        .onChange(of: showMenu) { oldValue, newValue in
            withAnimation {
                if newValue {
                    offset = sideBarWidth
                } else {
                    offset = 0
                }
            }
        }
    }
    
    // Helper function to create overlay view
    @ViewBuilder
    private func overlayView(sideBarWidth: CGFloat) -> some View {
        Rectangle()
            .fill(Color.primary.opacity(Double((offset / sideBarWidth) / 5)))
            .ignoresSafeArea(.container, edges: .vertical)
            .opacity(offset == 0 ? 0 : 1)
            .contentShape(Rectangle())  // Ensures the entire area is tappable
            .onTapGesture {
                withAnimation(.easeOut) {
                    offset = 0
                    showMenu = false
                    lastStoredOffset = 0
                }
            }
    }
    
    // Helper function to handle menu state changes
    private func handleMenuChange(newValue: Bool, sideBarWidth: CGFloat) {
        if newValue && offset == 0 {
            offset = sideBarWidth
            lastStoredOffset = offset
        }
        
        if !newValue && offset == sideBarWidth {
            offset = 0
            lastStoredOffset = 0
        }
    }
    
    func onChange(){
        let sideBarWidth = getRect().width - 90
        
        // Allow scrolling/dragging in both directions
        let newOffset = gestureOffset + lastStoredOffset
        offset = max(0, min(sideBarWidth, newOffset))
        
        // Update menu state based on drag
        if newOffset <= sideBarWidth / 2 && showMenu {
            showMenu = false
        } else if newOffset > sideBarWidth / 2 && !showMenu {
            showMenu = true
        }
    }
    
    func onEnd(value: DragGesture.Value){
        let sideBarWidth = getRect().width - 90
        let translation = value.translation.width
        
        withAnimation(.easeOut){
            if translation > 0 {
                // Opening gesture (right swipe)
                if translation > (sideBarWidth / 3) || (showMenu && translation > 10) {
                    offset = sideBarWidth
                    showMenu = true
                } else {
                    offset = 0
                    showMenu = false
                }
            } else {
                // Closing gesture (left swipe)
                if -translation > (sideBarWidth / 3) || (!showMenu && -translation > 10) {
                    offset = 0
                    showMenu = false
                } else {
                    offset = sideBarWidth
                    showMenu = true
                }
            }
        }
        lastStoredOffset = offset
    }
}

#Preview {
    BaseView()
}
