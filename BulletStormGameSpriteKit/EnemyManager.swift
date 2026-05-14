//
//  EnemyManager.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/14/26.
//

import SpriteKit

enum EnemyType {
    case normal
    case seeker
}

class EnemyNode: SKSpriteNode {
    var type: EnemyType
    
    init(type: EnemyType, texture: SKTexture) {
        self.type = type
        super.init(texture: texture, color: .clear, size: texture.size())
        
        //physics body for the enemy
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2) //physicsBody is gonna adjust to the enemy size
        self.physicsBody?.isDynamic = true //static y position - have gravity falling from the sky
        self.physicsBody?.categoryBitMask = 2 //unique identifier for the enemy
        self.physicsBody?.contactTestBitMask = 1 //detects collision
        self.physicsBody?.collisionBitMask = 0 // prevent unintended physics bounces
        self.physicsBody?.usesPreciseCollisionDetection = true
        
        if type == .seeker {
            addGlowEffect()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMovement(playerPosition: CGPoint) {
        switch type {
        case .normal:
            break
        case .seeker:
            let moveSpeed: CGFloat = 5
            
            if playerPosition.x > self.position.x { //enemy is adjusting to the player
                self.position.x += moveSpeed
            } else if playerPosition.x < self.position.x {
                self.position.x -= moveSpeed
            }
        }
    }
    
    private func addGlowEffect() {
        let glowAction = SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.3)
        let removeGlow = SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.3)
        
        let pulse = SKAction.sequence([glowAction, removeGlow])
        let repeatGlow = SKAction.repeatForever(pulse)
        
        self.run(repeatGlow)
    }
    
    
}
