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
    
    @State var currentTab = "Home"
    
    // Offset for Both Drag Gesuture and showing Menu...
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    
    // GEsture Offset...
    @GestureState var gestureOffset: CGFloat = 0
    
    var body: some View {
        let sideBarWidth: CGFloat = getRect().width - 90
        
        NavigationView {
            HStack(spacing: 0) {
                // Side menu
                SideMenu(showMenu: $showMenu)
                VStack(spacing: 0){
                    
                    TabView(selection: $currentTab){
                        
                        HomeView(showMenu: $showMenu)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                            .tag("Home")
                    }
                }
                .frame(width: getRect().width)
                // BG when menu is showing...
                .overlay(
                
                    Rectangle()
                        .fill(
                        
                            Color.primary
                                .opacity(Double((offset / sideBarWidth) / 5))
                        )
                        .ignoresSafeArea(.container, edges: .vertical)
                        .onTapGesture {
                            withAnimation{
                                showMenu.toggle()
                            }
                        }
                )
                
                
            }
            // max Size...
            .frame(width: getRect().width + sideBarWidth)
            .offset(x: -sideBarWidth / 2)
            .offset(x: offset > 0 ? offset : 0)
            // Gesture...
            .gesture(
            
                DragGesture()
                    .updating($gestureOffset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onEnded(onEnd(value:))
            )
            // no nav bar link....
            // hiding nav bar
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .animation(.easeOut, value: offset == 0)
        .onChange(of: showMenu) { newValue, _ in
            if newValue && offset == 0 {
                offset = sideBarWidth
                lastStoredOffset = offset
            }

            if !newValue && offset == sideBarWidth {
                offset = 0
                lastStoredOffset = 0
            }
        }

        .onChange(of: gestureOffset) { _, _ in
            onChange()
        }
    }
    
    func onChange(){
        let sideBarWidth = getRect().width - 90
        
        offset = (gestureOffset != 0) ? ((gestureOffset + lastStoredOffset) < sideBarWidth ? (gestureOffset + lastStoredOffset) : offset) : offset
        
        offset = (gestureOffset + lastStoredOffset) > 0 ? offset : 0
    }
    
    func onEnd(value: DragGesture.Value){
        
        let sideBarWidth = getRect().width - 90
        
        let translation = value.translation.width
        
        withAnimation{
            // Checking...
            if translation > 0{
                
                if translation > (sideBarWidth / 2){
                    // showing menu...
                    offset = sideBarWidth
                    showMenu = true
                }
                else{
                    
                    // Extra cases...
                    if offset == sideBarWidth || showMenu{
                        return
                    }
                    offset = 0
                    showMenu = false
                }
            }
            else{
                
                if -translation > (sideBarWidth / 2){
                    offset = 0
                    showMenu = false
                }
                else{
                    
                    if offset == 0 || !showMenu{
                        return
                    }
                    
                    offset = sideBarWidth
                    showMenu = true
                }
            }
        }
        
        // storing last offset...
        lastStoredOffset = offset
    }
}

#Preview {
    BaseView()
}
