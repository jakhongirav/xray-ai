//
//  BaseView.swift
//  xray-ai
//
//  Created by Jahongir Abdujalilov on 12/12/24.
//

import SwiftUI

struct BaseView: View {
    @State var showMenu: Bool = false
    @State var currentTab = "Chat"

    // Remove unused state
    // @State private var selectedView: AnyView = AnyView(HomeView(showMenu: .constant(false)))

    // Optimize gesture state management
    @State private var offset: CGFloat = 0
    @State private var lastStoredOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0

    // Cache sideBarWidth to avoid recalculation
    private let sideBarWidth: CGFloat = UIScreen.main.bounds.width - 90

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        // Remove redundant constant definition
        HStack(spacing: 0) {
            // Side menu component
            SideMenu(showMenu: $showMenu, selectedTab: $currentTab)

            // Main content area with NavigationView
            NavigationView {
                Group {  // Use Group to avoid recreating VStack when content changes
                    if currentTab == "Chat" {
                        HomeView(showMenu: $showMenu)
                    } else {
                        ScanView(showMenu: $showMenu)
                    }
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
                overlayView(sideBarWidth: sideBarWidth)
                    .allowsHitTesting(offset > 0)  // Only allow overlay interaction when menu is open
            )
        }
        // Container frame and offset
        .frame(width: getRect().width + sideBarWidth)
        .offset(x: -sideBarWidth / 2)
        .offset(x: offset > 0 ? offset : 0)
        // Gesture...
        .gesture(
            DragGesture()
                .updating(
                    $gestureOffset,
                    body: { value, out, _ in
                        out = value.translation.width
                    }
                )
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
        // Add onChange modifier to watch for tab changes
        .onChange(of: currentTab) { oldValue, newValue in
            closeMenu()
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
            .allowsHitTesting(offset > 0)  // Only allow interaction when menu is open
            .onTapGesture {
                withAnimation(.easeOut) {
                    offset = 0
                    showMenu = false
                    lastStoredOffset = 0
                }
            }
    }

    // Extract menu toggle logic to reduce redundancy
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

    func onChange() {
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

    func onEnd(value: DragGesture.Value) {
        let sideBarWidth = getRect().width - 90
        let translation = value.translation.width

        withAnimation(.easeOut) {
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
