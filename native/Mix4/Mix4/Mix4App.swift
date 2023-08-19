//
//  Mix4App.swift
//  Mix4
//
//  Created by Brooklin Myers on 8/19/23.
//

import SwiftUI

@main
struct Mix4App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
