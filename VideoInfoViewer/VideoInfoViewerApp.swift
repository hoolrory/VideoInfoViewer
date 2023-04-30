//
//  VideoInfoViewerApp.swift
//  VideoInfoViewer
//
//  Created by Rory Hool on 4/23/23.
//

import SwiftUI

@main
struct VideoInfoViewerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
