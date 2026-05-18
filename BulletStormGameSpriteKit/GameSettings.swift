//
//  GameSettings.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/15/26.
//

import Foundation
import SwiftData

@Model
class GameSettings {
    var selectedShipColor: String
    
    init(selectedShipColor: String = "silver") {
        self.selectedShipColor = selectedShipColor
    }
}
