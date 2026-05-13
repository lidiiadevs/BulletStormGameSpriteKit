//
//  SoundManager.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/13/26.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    var backgoundMusicPlayer: AVAudioPlayer?
    var soundEffectplayer: AVAudioPlayer?
    
    private init() { //prevent multiple instances
    }
    
    func playBackgroundMusic(fileName: String, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Error: BGM not found \(fileName).mp3")
            return
        }
        do {
            backgoundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgoundMusicPlayer?.numberOfLoops = loop ? -1 : 0  //allows to loop infinitly
            backgoundMusicPlayer?.volume = 0.1
            backgoundMusicPlayer?.play()
        } catch {
            print("Error could not play BGN music")
        }
    }
    
    func stopBackgroundMusic() {
        backgoundMusicPlayer?.stop()
    }
    
    func playSoundEffect(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Error: Sound Effect file not found \(fileName).mp3")
            return
        }
        do {
            soundEffectplayer = try AVAudioPlayer(contentsOf: url)
            soundEffectplayer?.play()
        } catch {
            print("Error: could not find the sound effects")
        }
    }
}
