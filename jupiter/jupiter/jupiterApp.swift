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
    @StateObject var sb = ScheduleBuilder()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sb)
        }
    }
}
