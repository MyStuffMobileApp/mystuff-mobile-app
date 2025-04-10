//
//  PhotoNoteApp.swift
//  PhotoNote
//
//  Created by Ryan Cabeen on 3/6/25.
//

import SwiftUI

@main
struct MyStuffApp: App {
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(appSettings)
        }
    }
}
