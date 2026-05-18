//
//  BulletStormGameSpriteKitApp.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//

import SwiftUI
import SwiftData

@main
struct BulletStormGameSpriteKitApp: App {
    var sharedModelContainer: ModelContainer = { //Creates a database that stores GameSettings objects - for SwiftData
        let schema = Schema([GameSettings.self]) //Think of it like a blueprint for the database
        let container = try! ModelContainer(for: schema)
        return container
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer) //inject SwiftData
        }
    }
}
