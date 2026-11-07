//
//  CSE_335_ProjectApp.swift
//  CSE 335 Project
//
//  Created by asalha2 on 3/30/25.
//

import SwiftUI
import SwiftData

@main
struct CSE_335_ProjectApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedEvent.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                EventsListView()
                    .tabItem {
                        Label("Events", systemImage: "list.bullet")
                    }
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }
            }
            .task {
                // Request notification permission on app launch
                try? await NotificationManager.shared.requestPermission()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
