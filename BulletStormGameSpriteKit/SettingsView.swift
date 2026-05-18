//
//  showSettings.swift
//  BulletStormGameSpriteKit
//
//  Created by Lidiia Diachkovskaia on 5/15/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var showSettings: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [GameSettings]
    
    @State private var selectedShipColor: String = "red"
    @State private var shipScale: CGFloat = 1.0
    
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .bold()
                .padding()
            Text("Select Ship Color")
                .font(.headline)
                .padding()
            
            Image("ship_\(selectedShipColor)")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(shipScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: shipScale)
            Picker("Ship Color", selection: $selectedShipColor) {
                Text("Red").tag("red")
                Text("Purple").tag("purple")
                Text("Yellow").tag("yellow")
                Text("Silver").tag("silver")
            }
            .pickerStyle(.segmented)
            .padding(50)
            .onChange(of: selectedShipColor) { //for animation
                newValue in
                updateShipColor(newValue)
            }
            
            Spacer()
            Button(action: saveAndReturn){
                Text("Save and Return")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onAppear{
            selectedShipColor = settings.first?.selectedShipColor ?? "red"
            
        }
    }
    private func updateShipColor(_ color: String) {
        shipScale = 1.5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            shipScale = 1.0
        } //for animation
        
        if settings.isEmpty {
            let newSettings = GameSettings(selectedShipColor: color)
            modelContext.insert(newSettings)
        } else {
            settings.first?.selectedShipColor = color
        }
        UserDefaults.standard.set(color, forKey: "selectedShipColor")
    }
    
    private func saveAndReturn() {
        Task{
            do{
                try modelContext.save() //should save any changes to swiftdata
            }catch{
                print("Failed to save: \(error)")
            }
            showSettings = false
        }
    }
}

#Preview{
    @Previewable @State var previewSettings: Bool = true
    return SettingsView(showSettings: $previewSettings)
}
