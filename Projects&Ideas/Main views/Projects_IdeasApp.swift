//
//  Projects_IdeasApp.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 02.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



//App should close fully when window is closed; only on macOS
#if canImport(AppKit)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
}
#endif



@main struct Projects_IdeasApp: App {
    #if canImport(AppKit)
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
	
    var body: some Scene {
		WindowGroup {
			ZStack {
				
				//Contentview, all the Project stuff is in here
				ContentView()
				
				//Notification overlay
				NotificationOverlay()
			}
		}
		.modelContainer(for: [Project.self, GlobalUserSettings.self])
		//.windowToolbarStyle(.unifiedCompact)
    }
}
