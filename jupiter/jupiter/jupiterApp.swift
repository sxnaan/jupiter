//
//  jupiterApp.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/24/21.
//

import SwiftUI

@main
struct jupiterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
