//
//  GameScene.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//

import SpriteKit
import AVFoundation
import SwiftUI //only needed for preview

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
        
        SoundManager.shared.playBackgroundMusic(fileName: "game_music")
    }
    
    func setupBackground() {
        background.size = self.size
        background.position = CGPoint(x: size.width / 2, y: size.height / 2) //center
        background.zPosition = -1
        addChild(background)
    }
    
    func setupPlayer() {
        player.position = CGPoint(x: size.width / 2, y: 120) //place us at the bottom
        player.size = CGSize(width: 40, height: 40)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        player.physicsBody?.isDynamic = false //disables the gravity
        player.physicsBody?.categoryBitMask = 1 //assign category bit masks to your player and enemies to trigger collision events effeciently
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
            let enemy = SKSpriteNode(texture: enemyTextures.randomElement())
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
                    print("🛡 Shield absorbed the hit!") // Debug log message
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
                print("💥 Player hit! Game Over.")
                gameOver = true // Set game over flag
                gameTimer?.invalidate() // Stop enemy spawning
                scoreTimer?.invalidate() // Stop score updates
                powerUpTimer?.invalidate() // Stop power-up spawning
                showGameOver() // Display the game over screen
            }
        }
        
    
    func moveEnemies() {
        for node in children {
            if let sprite = node as? SKSpriteNode, sprite != player, sprite != background {
                sprite.position.y -= 30 //move enemies downward each frame
                if sprite.position.y < 0 {
                    sprite.removeFromParent()
                }
            }
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
        
        run(SKAction.wait(forDuration: 2.0)) {
            self.restartGame()
        }
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
        startGame()
    }
}


//#Preview {
//    GameView()
//}




//import SpriteKit
//import AVFoundation
//import SwiftUI // only needed for preview
//
//// Defines the game scene and implements collision detection
//class GameScene: SKScene, SKPhysicsContactDelegate {
//    let player = SKSpriteNode(imageNamed: "ship") // Player's ship sprite
//    var enemyTextures: [SKTexture] = [ // Array of enemy textures for variety
//        SKTexture(imageNamed: "star"),
//        SKTexture(imageNamed: "meteor"),
//        SKTexture(imageNamed: "satellite"),
//    ]
//    
//    var background = SKSpriteNode(imageNamed: "space_background") // Background image
//    var scoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold") // Score label
//    var score = 0 // Player's score
//    var gameOver = false // Flag to check if the game is over
//    var gameTimer: Timer? // Timer to control enemy spawning and movement
//    var scoreTimer: Timer? // Timer to update the score every second
//    var shieldActive = false // Flag to check if the shield is active
//    var enemySpeedModifier: CGFloat = 1.0 // Modifier for enemy speed
//    var gameTimeModifier: Double = 1.0 // Modifier for game time (affects score rate)
//    var powerUpTimer: Timer? // Timer for spawning power-ups
//    
//    // Applies a power-up effect when collected
//    func applyPowerUp(_ powerUp: PowerUp) {
//        if let collectEffect = SKEmitterNode(fileNamed: "PowerUpEffect.sks") {
//            collectEffect.position = player.position // Position effect on player
//            collectEffect.zPosition = 2 // Place above other elements
//            addChild(collectEffect)
//            
//            let removeAction = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()])
//            collectEffect.run(removeAction) // Remove effect after delay
//        } else {
//            print("⚠️ Warning: PowerUpEffect.sks not found or failed to load!")
//        }
//        
//        switch powerUp.type {
//        case .speedBoost:
//            gameTimeModifier = 0.5 // Score updates twice as fast
//            enemySpeedModifier = 2.0 // Enemies fall twice as fast
//            SoundManager.shared.playSoundEffect(fileName: "speed_boost") // Play sound
//            
//            restartScoreTimer() // Restart score timer with new rate
//            updateEnemySpeeds() // Apply new enemy speed
//            
//            // Animate player to indicate power-up activation
//            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
//            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
//            player.run(SKAction.sequence([scaleUp, scaleDown]))
//            
//            run(SKAction.wait(forDuration: 5.0)) { // Power-up duration
//                self.gameTimeModifier = 1.0 // Reset score rate
//                self.enemySpeedModifier = 1.0 // Reset enemy speed
//                self.restartScoreTimer()
//                self.updateEnemySpeeds() // Reset enemy speeds to normal
//            }
//            
//        case .slowEnemies:
//            enemySpeedModifier = 0.5 // Slow down enemies
//            SoundManager.shared.playSoundEffect(fileName: "slow_powerup") // Play sound
//            
//            updateEnemySpeeds() // Apply slowdown immediately
//            
//            run(SKAction.wait(forDuration: 5.0)) { // Power-up duration
//                self.enemySpeedModifier = 1.0 // Reset enemy speed
//                self.updateEnemySpeeds() // Reset enemy speeds to normal
//            }
//            
//        case .shield:
//            shieldActive = true // Activate shield
//            SoundManager.shared.playSoundEffect(fileName: "shield_powerup") // Play sound
//            
//            let glow = SKShapeNode(circleOfRadius: 25) // Create glow effect
//            glow.strokeColor = .cyan // Shield color
//            glow.lineWidth = 3
//            glow.alpha = 0.7
//            glow.name = "shieldGlow"
//            glow.position = CGPoint(x: 0, y: 0)
//            player.addChild(glow) // Add glow to player
//            
//            run(SKAction.wait(forDuration: 10.0)) { // Shield duration
//                self.shieldActive = false // Deactivate shield
//                glow.removeFromParent() // Remove glow effect
//            }
//        }
//    }
//    
//    // Updates all existing enemies to use the latest enemy speed modifier
//    func updateEnemySpeeds() {
//        for node in children {
//            if let enemy = node as? SKSpriteNode, enemy.physicsBody?.categoryBitMask == 2 {
//                let baseDuration: TimeInterval = 3.0 // Default fall duration
//                let adjustedDuration = baseDuration / enemySpeedModifier // Adjusted duration
//                
//                enemy.removeAllActions() // Stop any lingering old movement actions
//                let moveAction = SKAction.moveTo(y: -enemy.size.height, duration: adjustedDuration)
//                let removeAction = SKAction.removeFromParent()
//                enemy.run(SKAction.sequence([moveAction, removeAction])) // Apply new speed
//            }
//        }
//    }
//    
//    // Restarts the score timer, applying any game time modifications
//    func restartScoreTimer() {
//        scoreTimer?.invalidate() // Stop the old timer
//        
//        scoreTimer = Timer.scheduledTimer(withTimeInterval: 1.0 * gameTimeModifier, repeats: true) { _ in
//            if !self.gameOver {
//                self.score += 1
//                self.updateScoreLabel()
//            }
//        }
//    }
//    
//    // Initializes the scene when the game starts
//    override func didMove(to view: SKView) {
//        backgroundColor = .black // Fallback color in case assets fail to load
//        setupBackground() // Set up background
//        setupPlayer() // Set up player sprite
//        setupUI() // Set up UI elements
//        startGame() // Begin game logic
//        
//        physicsWorld.contactDelegate = self // Enable collision detection
//        
//        SoundManager.shared.playBackgroundMusic(fileName: "game_music") // Start music
//    }
//    
//    // Sets up the background sprite
//    func setupBackground() {
//        background.size = self.size // Match scene size
//        background.position = CGPoint(x: size.width / 2, y: size.height / 2) // Center the background
//        background.zPosition = -1 // Place behind all other elements
//        addChild(background)
//    }
//    
//    // Sets up the player sprite and physics properties
//    func setupPlayer() {
//        player.position = CGPoint(x: size.width / 2, y: 120) // Position near bottom
//        player.size = CGSize(width: 40, height: 40) // Set player size
//        
//        player.physicsBody = SKPhysicsBody(circleOfRadius: 20) // Set collision size
//        player.physicsBody?.isDynamic = false // Disable gravity effects
//        player.physicsBody?.categoryBitMask = PhysicsCategory.player
//        player.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.powerUp
//        player.physicsBody?.collisionBitMask = 0
//        addChild(player)
//    }
//    
//    // Sets up the UI elements such as score display
//    func setupUI() {
//        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80) // Position near top
//        scoreLabel.fontSize = 24
//        scoreLabel.fontColor = .white
//        addChild(scoreLabel)
//        updateScoreLabel() // Initialize score label
//    }
//    
//    // Starts the game logic including timers for enemies, score, and power-ups
//    func startGame() {
//        gameTimer?.invalidate()
//        scoreTimer?.invalidate()
//        powerUpTimer?.invalidate()
//        
//        // Timer for enemy movement and spawning
//        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
//            self.spawnEnemy()
//            self.moveEnemies()
//            self.checkCollision()
//        }
//        
//        // Timer for updating score
//        scoreTimer = Timer.scheduledTimer(withTimeInterval: 1.0 * gameTimeModifier, repeats: true) { _ in
//            if !self.gameOver {
//                self.score += 1
//                self.updateScoreLabel()
//            }
//        }
//        
//        // Timer for spawning power-ups every 20 seconds
//        powerUpTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
//            if !self.gameOver {
//                self.spawnPowerUp()
//            }
//        }
//    }
//    // Spawns a power-up randomly at a random X position
//    func spawnPowerUp() {
//        let randomX = CGFloat.random(in: 50...size.width - 50) // Random X position within screen bounds
//        
//        let powerUpType: PowerUpType // Variable to hold the chosen power-up type
//        let chance = Int.random(in: 1...3) // Random number between 1 and 3 to determine power-up type
//        
//        switch chance {
//        case 1:
//            powerUpType = .speedBoost // 33% chance to spawn a speed boost power-up
//        case 2:
//            powerUpType = .slowEnemies // 33% chance to spawn a slow enemy power-up
//        default:
//            powerUpType = .shield // 33% chance to spawn a shield power-up
//        }
//        
//        let powerUp = PowerUp(type: powerUpType) // Create the power-up instance
//        powerUp.position = CGPoint(x: randomX, y: size.height) // Spawn at the top of the screen
//        
//        addChild(powerUp) // Add power-up to the scene
//        
//        let moveAction = SKAction.moveTo(y: -powerUp.size.height, duration: 4.0) // Move downward over 4 seconds
//        let removeAction = SKAction.removeFromParent() // Remove from scene when off-screen
//        powerUp.run(SKAction.sequence([moveAction, removeAction])) // Run movement and removal actions
//    }
//    
//    // Spawns an enemy at a random X position with a small chance to be a seeker
//    func spawnEnemy() {
//        let randomX = CGFloat.random(in: 50...size.width - 50) // Random X position within screen bounds
//        let randomSize = CGFloat.random(in: 20...35) // Random enemy size
//        let enemy = SKSpriteNode(texture: enemyTextures.randomElement())
//        enemy.position = CGPoint(x: randomX, y: size.height)
//        enemy.size = CGSize(width: randomSize, height: randomSize)
//        
//        // Set up physics body for collision detection
//        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
//        enemy.physicsBody?.isDynamic = true // Enable physics movement
//        enemy.physicsBody?.categoryBitMask = 2 // Assign category for enemies
//        enemy.physicsBody?.contactTestBitMask = 1 // Detect collision with the player
//        enemy.physicsBody?.collisionBitMask = 0 // Prevents unintended physics interactions
//        enemy.physicsBody?.usesPreciseCollisionDetection = true // Improve hit detection accuracy
//        
//        addChild(enemy) // Add enemy to the scene
//        
//        let baseDuration: TimeInterval = 3.0 // Default duration to fall from top to bottom
//        let adjustedDuration = baseDuration / enemySpeedModifier // Adjust duration based on power-ups
//        
//        let moveAction = SKAction.moveTo(y: -enemy.size.height, duration: adjustedDuration) // Move downward
//        let removeAction = SKAction.removeFromParent() // Remove from scene when off-screen
//        enemy.run(SKAction.sequence([moveAction, removeAction])) // Run movement and removal actions
//    }
//    
//    // Handles collision detection logic between game objects
//    func didBegin(_ contact: SKPhysicsContact) {
//        let firstBody = contact.bodyA // First object in the collision
//        let secondBody = contact.bodyB // Second object in the collision
//        
//        // Handle power-up collection
//        if firstBody.categoryBitMask == PhysicsCategory.powerUp || secondBody.categoryBitMask == PhysicsCategory.powerUp {
//            if let powerUp = firstBody.node as? PowerUp ?? secondBody.node as? PowerUp {
//                applyPowerUp(powerUp) // Apply the collected power-up
//                
//                // Prevents a crash by ensuring the power-up is still in the scene before removing
//                if powerUp.parent != nil {
//                    powerUp.removeFromParent()
//                }
//            }
//            return // Exit function since power-up collection doesn't cause game over
//        }
//        
//        // Handle enemy collision with the player
//        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.enemy) ||
//            (firstBody.categoryBitMask == PhysicsCategory.enemy && secondBody.categoryBitMask == PhysicsCategory.player) {
//            
//            if shieldActive {
//                print("🛡 Shield absorbed the hit!") // Debug log message
//                shieldActive = false // Deactivate shield
//                
//                // Remove the shield visual effect
//                if let shieldGlow = player.childNode(withName: "shieldGlow") {
//                    let flash = SKAction.sequence([
//                        SKAction.fadeOut(withDuration: 0.1),
//                        SKAction.fadeIn(withDuration: 0.1),
//                        SKAction.fadeOut(withDuration: 0.1),
//                        SKAction.removeFromParent()
//                    ])
//                    shieldGlow.run(flash) // Run shield disappearance animation
//                }
//                
//                // Remove the enemy that collided with the shield
//                if firstBody.categoryBitMask == PhysicsCategory.enemy {
//                    firstBody.node?.removeFromParent()
//                } else {
//                    secondBody.node?.removeFromParent()
//                }
//                return // Exit function since the shield absorbed the hit
//            }
//            
//            // If the player is hit without a shield, trigger game over
//            print("💥 Player hit! Game Over.")
//            gameOver = true // Set game over flag
//            gameTimer?.invalidate() // Stop enemy spawning
//            scoreTimer?.invalidate() // Stop score updates
//            powerUpTimer?.invalidate() // Stop power-up spawning
//            showGameOver() // Display the game over screen
//        }
//    }
//    
//    // Moves enemies downward and updates seeker enemies' movement
//    func moveEnemies() {
//        for node in children {
//            if let sprite = node as? SKSpriteNode, sprite != player, sprite != background {
//                sprite.position.y -= 30 // move enemies downward each frame
//                if sprite.position.y < 0 {
//                    sprite.removeFromParent()
//                }
//                
//            }
//        }
//    }
//    
//    // Updates the score label to display the player's survival time
//    func updateScoreLabel(){
//        scoreLabel.text = "Timer Survived: \(score) seconds" // Sets the label text with the updated score value
//    }
//    
//    // Handles player movement when the player touches and drags on the screen
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return } // Ensures we process only the first detected touch
//        let location = touch.location(in: self) // Gets the touch location within the game scene
//        
//        // Clamps the player's X position to keep it within screen boundaries
//        let clampedX = min(max(location.x, player.size.width / 2), size.width - player.size.width / 2)
//        player.position.x = clampedX // Updates the player's position with the clamped value
//    }
//    
//    // Checks for collisions between the player and enemies
//    func checkCollision() {
//        for node in children {
//            // Ignore player, background, and power-ups in the collision check
//            if node != player, let enemy = node as? SKSpriteNode, enemy.physicsBody?.categoryBitMask == PhysicsCategory.enemy {
//                let distance = sqrt(pow(player.position.x - enemy.position.x, 2) + pow(player.position.y - enemy.position.y, 2))
//                
//                // If the enemy is close enough to the player, handle the collision
//                if distance < (enemy.size.width / 2 + 20) {
//                    if shieldActive {
//                        shieldActive = false // Absorb hit if shield is active
//                        return // Exit to prevent game over
//                    }
//                    
//                    // If no shield is active, trigger game over sequence
//                    gameOver = true
//                    gameTimer?.invalidate() // Stop enemy spawning
//                    scoreTimer?.invalidate() // Stop score updates
//                    powerUpTimer?.invalidate() // Stop power-up spawning
//                    showGameOver() // Display the game over screen
//                }
//            }
//        }
//    }
//    
//    // Displays the game over sequence when the player loses
//    func showGameOver() {
//        showExplosion(at: player.position) // Play explosion effect at player's position
//        SoundManager.shared.playSoundEffect(fileName: "game_over") // Play game over sound effect
//        player.removeFromParent() // Remove the player's sprite from the scene
//        
//        run(SKAction.wait(forDuration: 2.0)) {
//            self.restartGame()
//        }
//    }
//    
//    // Creates an explosion effect when the player is destroyed
//    func showExplosion(at position: CGPoint){
//        if let explosion = SKEmitterNode(fileNamed: "Explosion.sks") {
//            explosion.position = position // Position the explosion at the given location
//            addChild(explosion) // Add explosion effect to the scene
//            SoundManager.shared.playSoundEffect(fileName: "explosion") // Play explosion sound effect
//            run(SKAction.wait(forDuration: 1.0)) {
//                explosion.removeFromParent() // Remove explosion after 1 second
//            }
//        }
//    }
//    
//    // Resets the game state and restarts the game
//    func restartGame(){
//        for node in children {
//            if node != background && node != player {
//                node.removeFromParent() // Remove all game elements except the background and player
//            }
//        }
//        
//        // Reset power-up effects
//        shieldActive = false
//        enemySpeedModifier = 1.0
//        gameTimeModifier = 1.0
//        
//        gameOver = false // Reset game over flag
//        score = 0 // Reset the score
//        updateScoreLabel() // Update score label to show reset value
//        
//        if !children.contains(player) {
//            setupPlayer() // Re-add the player if missing
//            setupUI() // Reinitialize UI elements
//        }
//        
//        startGame() // Restart the game logic and timers
//    }
// 
//}
//

//#Preview {
//    GameView()
//}
