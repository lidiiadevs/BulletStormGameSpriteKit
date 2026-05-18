//
//  ContentView.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//


import SwiftUI

struct ContentView: View {
    @State private var showGameScene: Bool = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        ZStack {
            if showGameScene {
                GameView()
                    .id(UUID())
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name( "exitToMainMenu"))) { _ in
                        showGameScene = false
                    }
            } else if showSettings {
                SettingsView(showSettings: $showSettings)
            }
            else {
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                    Button(action: { showSettings = true }) {
                        Text("Settings")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showGameScene) //animation changes between menu and game screen
        .animation(.easeInOut, value: showSettings)
    }
}

#Preview {
    ContentView()
}

