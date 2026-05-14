//
//  ContentView.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//


import SwiftUI

struct ContentView: View {
    @State private var showGameScene: Bool = false
    
    var body: some View {
        ZStack {
            if showGameScene {
                GameView()
                    .id(UUID())
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name( "exitToMainMenu"))) { _ in
                        showGameScene = false
                    }
            } else {
                VStack(alignment: .center) {
                    Text("Bullet Storm Game 🎮")
                        .font(.title)
                        .bold()
                        .padding()
                    Button(action: { showGameScene = true }) {
                        Text("Start Game")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundColor(.white)
                        
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showGameScene)
    }
}

#Preview {
    ContentView()
}

