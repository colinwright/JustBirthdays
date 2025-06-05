//
//  Just_BirthdaysApp.swift
//  Just Birthdays
//
//  Created by Colin Wright on 6/5/25.
//

import SwiftUI

@main
struct Just_BirthdaysApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
