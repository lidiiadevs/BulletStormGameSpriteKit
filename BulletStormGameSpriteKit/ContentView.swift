//
//  ContentView.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Text("Bullet Storm Game 🎮")
                    .font(.title)
                    .bold()
                    .padding()
                NavigationLink(destination: GameView()) {
                    Text("Start Game")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

