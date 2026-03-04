//
//  FitnessDeviceLabApp.swift
//  FitnessDeviceLab
//
//  Created by JB Baudens on 2/27/26.
//

import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @StateObject private var workoutManager = WorkoutSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BluetoothManager.shared)
                .environmentObject(workoutManager)
        }
    }
}
