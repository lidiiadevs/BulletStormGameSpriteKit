//
//  GameScene.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//

import SpriteKit
import AVFoundation
import SwiftUI //only needed for preview
import SwiftData

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode(imageNamed: "ship")
    var enemyTextures: [SKTexture] = [
        SKTexture(imageNamed: "star"),
        SKTexture(imageNamed: "meteor"),
        SKTexture(imageNamed: "satellite"),
    ]
    
    var background = SKSpriteNode(imageNamed: "space_background")
    var scoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
    var score = 0
    var gameOver = false
    var gameTimer: Timer? //control the enemy spawning and movement
    var scoreTimer: Timer? //update every second for the score
    var shieldActive = false
    var powerUpTimer: Timer?
    var enemySpeedModifier: CGFloat = 1.0
    var gameTimeModifier: Double = 1.0
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [GameSettings]
    
    func applyPowerUp(_ powerUp: PowerUp) {
        if let collectedEffect = SKEffectNode(fileNamed: "PowerUpEffect.sks") {
            collectedEffect.position = player.position
            collectedEffect.zPosition = 2
            addChild(collectedEffect)
            
            let removeAction = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()])
            collectedEffect.run(removeAction)
        } else {
            print("Effect not found")
        }
        switch powerUp.type {
        case .speedBoost:
            //sound goes here
            
            gameTimeModifier = 0.5
            enemySpeedModifier = 2.0
            
            restartScoreTimer()
            updateEnemySpeeds()
            
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            player.run(SKAction.sequence([scaleUp, scaleDown]))
            
            run(SKAction.wait(forDuration: 5.0)) {
                self.gameTimeModifier = 1.0
                self.enemySpeedModifier = 1.0
                self.restartScoreTimer()
                self.updateEnemySpeeds()
            }
            
        case .slowEnemies:
            enemySpeedModifier = 0.5
            
            updateEnemySpeeds()
            
            run(SKAction.wait(forDuration: 5.0)) {
                self.enemySpeedModifier = 1.0
                self.updateEnemySpeeds()
            }
        case .shield:
                  shieldActive = true // Activate shield
                  SoundManager.shared.playSoundEffect(fileName: "shield_powerup") // Play sound
                  
                  let glow = SKShapeNode(circleOfRadius: 25) // Create glow effect
                  glow.strokeColor = .cyan // Shield color
                  glow.lineWidth = 3
                  glow.alpha = 0.7
                  glow.name = "shieldGlow"
                  glow.position = CGPoint(x: 0, y: 0)
                  player.addChild(glow) // Add glow to player
                  
                  run(SKAction.wait(forDuration: 10.0)) { // Shield duration
                      self.shieldActive = false // Deactivate shield
                      glow.removeFromParent() // Remove glow effect
                  }
              }
        
    }
    
    func updateEnemySpeeds() {
        for node in children {
            if let enemy = node as? SKSpriteNode, enemy.physicsBody?.categoryBitMask == 2 {
                let baseDuration: TimeInterval = 3.0
                let adjustedDuration = baseDuration / enemySpeedModifier
                
                enemy.removeAllActions()
                let moveAction = SKAction.moveTo(y: -enemy.size.height, duration: adjustedDuration)
                let removeAction = SKAction.removeFromParent()
                enemy.run(SKAction.sequence([moveAction, removeAction])) //apply new speed
            }
        }
    }
    
    func restartScoreTimer() {
        scoreTimer?.invalidate()
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 1.0 * gameTimeModifier, repeats: true) {
            _ in
            if !self.gameOver {
                self.score += 1
                self.updateScoreLabel()
            }
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black //fallback for our images fail to load
        setupBackground()
        setupPlayer()
        setupUI()
        startGame()
        
        physicsWorld.contactDelegate = self //enables the collision detection
        
        if settings.isEmpty {
            let newSettings = GameSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
        
        SoundManager.shared.playBackgroundMusic(fileName: "game_music")
    }
    
    // Sets up the background sprite
     func setupBackground() {
         background.size = self.size // Match scene size
         background.position = CGPoint(x: size.width / 2, y: size.height / 2) // Center the background
         background.zPosition = -1 // Place behind all other elements
         addChild(background)
     }
     
     // Sets up the player sprite and physics properties
     func setupPlayer() {
         let selectedColor = UserDefaults.standard.string(forKey: "selectedShipColor") ?? "red" // Default to red

         let shipImageName = "ship_\(selectedColor)"
         player.texture = SKTexture(imageNamed: shipImageName) // Load correct ship texture

         player.position = CGPoint(x: size.width / 2, y: 120)
         player.size = CGSize(width: 40, height: 40)

         player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
         player.physicsBody?.isDynamic = false
         player.physicsBody?.categoryBitMask = 1
         player.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.powerUp
         addChild(player)
     }
    
    
    func setupUI() {
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        addChild(scoreLabel) //without addChild, the label exists in memory but is not shown on screen.
        updateScoreLabel()
    }
    
    func startGame() {
        gameTimer?.invalidate()
        scoreTimer?.invalidate()
        powerUpTimer?.invalidate()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            self.spawnEnemy()
            self.moveEnemies()
            self.checkCollision()
        }
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !self.gameOver {
                self.score += 1
                self.updateScoreLabel()
            }
        }
        
        powerUpTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            _ in
            if !self.gameOver {
                self.spawnPowerUp()
            }
        }
    }
    
    func spawnPowerUp() {
        let randomX = CGFloat.random(in: 50...size.width - 50)
        let powerUpType: PowerUpType
        let chance = Int.random(in: 1...3) //only 3 powerUp types
        
        switch chance {
        case 1:
            powerUpType = .speedBoost
        case 2:
            powerUpType = .slowEnemies
        default:
            powerUpType = .shield
        }
         
        
        let powerUp = PowerUp(type: powerUpType)
        powerUp.position = CGPoint(x: randomX, y: size.height)
        
        addChild(powerUp)
        
        let moveAction = SKAction.moveTo(y: -powerUp.size.height, duration: 4.0)
        let removeAction = SKAction.removeFromParent()
        powerUp.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func spawnEnemy() {
        let randomX = CGFloat.random(in: 50...size.width - 50)
        let randomSize  = CGFloat.random(in: 20...35)
        
        //50% chance to spawn an enemy each cycle to avoid overwhelming the player
        
        if Bool.random() {
            
            
            let enemyType: EnemyType = Int.random(in: 1...10) == 1 ? .seeker : .normal
            
            let enemy = EnemyNode(type: enemyType, texture: enemyTextures.randomElement()!)
            enemy.position = CGPoint(x: randomX, y: size.height)
            enemy.size = CGSize(width: randomSize, height: randomSize)
            
            //physics body for the enemy
            enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2) //physicsBody is gonna adjust to the enemy size
            enemy.physicsBody?.isDynamic = true //static y position - have gravity falling from the sky
            enemy.physicsBody?.categoryBitMask = 2 //unique identifier for the enemy
            enemy.physicsBody?.contactTestBitMask = 1 //detects collision
            enemy.physicsBody?.collisionBitMask = 0 // prevent unintended physics bounces
            enemy.physicsBody?.usesPreciseCollisionDetection = true
            
            addChild(enemy)
            
            let baseDuration: TimeInterval = 3.0
            let adjustedDuration = baseDuration / enemySpeedModifier
            
            
            let moveAction = SKAction.moveTo(y: -enemy.size.height, duration: adjustedDuration)
            let removeAction = SKAction.removeFromParent()
            enemy.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if firstBody.categoryBitMask == PhysicsCategory.powerUp || secondBody.categoryBitMask == PhysicsCategory.powerUp {
            if let powerUp = firstBody.node as? PowerUp ?? secondBody.node as? PowerUp{
                applyPowerUp(powerUp)
                
                if powerUp.parent != nil {
                    powerUp.removeFromParent()
                }
            }
                return
            }
            // Handle enemy collision with the player
            if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.enemy) ||
                (firstBody.categoryBitMask == PhysicsCategory.enemy && secondBody.categoryBitMask == PhysicsCategory.player) {
                
                if shieldActive {
                    print("Shield absorbed the hit!") // Debug log message
                    shieldActive = false // Deactivate shield
                    
                    // Remove the shield visual effect
                    if let shieldGlow = player.childNode(withName: "shieldGlow") {
                        let flash = SKAction.sequence([
                            SKAction.fadeOut(withDuration: 0.1),
                            SKAction.fadeIn(withDuration: 0.1),
                            SKAction.fadeOut(withDuration: 0.1),
                            SKAction.removeFromParent()
                        ])
                        shieldGlow.run(flash) // Run shield disappearance animation
                    }
                    
                    // Remove the enemy that collided with the shield
                    if firstBody.categoryBitMask == PhysicsCategory.enemy {
                        firstBody.node?.removeFromParent()
                    } else {
                        secondBody.node?.removeFromParent()
                    }
                    return // Exit function since the shield absorbed the hit
                }
                
                // If the player is hit without a shield, trigger game over
                print("Player hit! Game Over.")
                gameOver = true // Set game over flag
                gameTimer?.invalidate() // Stop enemy spawning
                scoreTimer?.invalidate() // Stop score updates
                powerUpTimer?.invalidate() // Stop power-up spawning
                showGameOver() // Display the game over screen
            }
        }
        
    
    func moveEnemies() {
        for node in children {
            if let enemy = node as? EnemyNode {
                let baseSpeed: CGFloat = size.height / (2.0 * 60)
                let adjustedSpeed = baseSpeed * enemySpeedModifier
                
                enemy.updateMovement(playerPosition: player.position)
                enemy.position.y -= adjustedSpeed
                
                if enemy.position.y < -enemy.size.height {
                    enemy.removeFromParent()
                }
            }
            
            //        for node in children {
            //            if let sprite = node as? SKSpriteNode, sprite != player, sprite != background {
            //                sprite.position.y -= 30 //move enemies downward each frame
            //                if sprite.position.y < 0 {
            //                    sprite.removeFromParent()
            //                }
            //            }
            //        }
        }
    }
    
    func updateScoreLabel() {
        scoreLabel.text = "Timer Survived: \(score) seconds"
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let clampedX = min(max(location.x, player.size.width / 2), size.width - player.size.width / 2)
        player.position.x = clampedX
    }
    
    func checkCollision() {
        for node in children {
            if node != player, let enemy = node as? SKSpriteNode, enemy.physicsBody?.categoryBitMask == PhysicsCategory.enemy {
                let distance = sqrt(pow(player.position.x - enemy.position.x, 2) + pow(player.position.y - enemy.position.y, 2))
                
                if distance < (enemy.size.width / 2 + 20) {
                    if shieldActive {
                        shieldActive = false
                        return
                    }
                    gameOver = true
                    gameTimer?.invalidate()
                    scoreTimer?.invalidate()
                    powerUpTimer?.invalidate()
                    showGameOver()
                }
            }
        }
    }
    
    
    func showGameOver() {
        showExplosion(at: player.position)
        
        SoundManager.shared.playSoundEffect(fileName: "game_over")
        player.removeFromParent()
        
        showGameOverScreen()
    }
    
    func showExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosion.position = position
            addChild(explosion)
            SoundManager.shared.playSoundEffect(fileName: "explosion")
            
            run(SKAction.wait(forDuration: 1.0)) {
                explosion.removeFromParent()
            }
        }
    }
    
    func restartGame() {
        for node in children {
            if node != background && node != player {
                node.removeFromParent()
            }
        }
        
        shieldActive = false
        enemySpeedModifier = 1.0
        gameTimeModifier = 1.0
        
        gameOver = false
        score = 0
        updateScoreLabel()
        
        if !children.contains(player) {
            setupPlayer()
            setupUI()
        }
        SoundManager.shared.playBackgroundMusic(fileName: "game_music")
        startGame()
    }
    
    func saveScore(_ newScore: Int) {
        let defaults = UserDefaults.standard
        var highScores = defaults.array(forKey: "highScores") as? [Int] ?? []
        
        highScores.append(newScore)
        highScores.sort(by: >)
        
        if highScores.count > 5 {
            highScores = Array(highScores.prefix(5))
        }
        defaults.set(highScores, forKey: "highScores")
    }
    
    // Displays the game over screen with a black overlay, final score, and action buttons
       func showGameOverScreen() {
           // Stop all game logic
           gameTimer?.invalidate()
           scoreTimer?.invalidate()
           powerUpTimer?.invalidate()
           SoundManager.shared.stopBackgroundMusic() // Stop music on game over
           
           saveScore(score)
           
           // Create a black semi-transparent overlay
           let overlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: self.size)
           overlay.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2) // Center overlay
           overlay.zPosition = 10 // Place it above other elements
           addChild(overlay)
           
           // Create the "Game Over" label
           let gameOverLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
           gameOverLabel.text = "Game Over" // Display "Game Over" text
           gameOverLabel.fontSize = 40
           gameOverLabel.fontColor = .white
           gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 80) // Position above center
           gameOverLabel.zPosition = 11 // Ensure it's on top of overlay
           addChild(gameOverLabel)
           
           // Create the score display label
           let finalScoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
           finalScoreLabel.text = "Final Score: \(score) seconds" // Show player's survival time
           finalScoreLabel.fontSize = 28
           finalScoreLabel.fontColor = .white
           finalScoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 30) // Below "Game Over"
           finalScoreLabel.zPosition = 11
           addChild(finalScoreLabel)
           
           // Create the "Go Again" button
           let retryButton = SKLabelNode(fontNamed: "AevnirNext-Bold")
           retryButton.text = "Go Again" // Allow player to restart the game
           retryButton.fontSize = 24
           retryButton.fontColor = .green
           retryButton.position = CGPoint(x: self.size.width / 2 - 100, y: self.size.height / 2 - 30) // Left side
           retryButton.zPosition = 11
           retryButton.name = "retryButton" // Assign a name for touch detection
           addChild(retryButton)
           
           // Create the "Return to Menu" button
           let menuButton = SKLabelNode(fontNamed: "AevnirNext-Bold")
           menuButton.text = "Main Menu" // Allow player to exit to menu
           menuButton.fontSize = 24
           menuButton.fontColor = .yellow
           menuButton.position = CGPoint(x: self.size.width / 2 + 100, y: self.size.height / 2 - 30) // Right side
           menuButton.zPosition = 11
           menuButton.name = "mainMenuButton" // Assign a name for touch detection
           addChild(menuButton)
           
           let defaults = UserDefaults.standard
           var highScores = defaults.array(forKey: "highScores") as? [Int] ?? []
           
           for(index, score) in highScores.enumerated(){
               let scoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
               scoreLabel.text = "\(index + 1). \(score) seconds ⏰"
               scoreLabel.fontSize = 24
               scoreLabel.fontColor = .white
               scoreLabel.zPosition = 11
               
               scoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 80 - CGFloat(index * 30))
               addChild(scoreLabel)
           }
       }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "mainMenuButton" {
            gotoMainMenu()
        } else if touchedNode.name == "retryButton" {
            restartGame()
        }
    }
    
    func gotoMainMenu() {
        gameTimer?.invalidate()
        scoreTimer?.invalidate()
        powerUpTimer?.invalidate()
        SoundManager.shared.stopBackgroundMusic()
        
        self.removeAllActions()
        self.removeAllChildren()
        
        NotificationCenter.default.post(name: NSNotification.Name("exitToMainMenu"), object: nil)
    }
}


//#Preview {
//    GameView()
//}
