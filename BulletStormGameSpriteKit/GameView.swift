//
//  GameView.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) //allows to push the screen size to the boundries of the device
        scene.scaleMode = .fill
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene) //enbed new spriteKit based game
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
        
    }
}

#Preview {
GameView()
}

