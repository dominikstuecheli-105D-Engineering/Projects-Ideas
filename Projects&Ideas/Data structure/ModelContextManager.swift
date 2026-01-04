//
//  ModelContextManager.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 11.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



///NOTE: The ModelContextManager is a singleton that simplifies some accesses to the modelContext like getting the global user settings where there should only be one instance. It also allows the .remove() function of the Array to permanently delete objects from the ModelContext without being given the ModelContext through the function call. The manager also contains some status values which are merely there to have an insight via the developer window.



@Observable class ModelContextManager {
	
	static let shared = ModelContextManager()
	private init() {} //Empty initialiser because the main action happens in setToContext()
	
	//MODELCONTEXT
	
	var modelContext: ModelContext? = nil
	
	//The modelContext is not available on initialisation so this function is the actual initialisation for the manager
	func setToContext(_ modelContext: ModelContext) {
		self.modelContext = modelContext
		
		//Model migration or modification during development
		developmentModelMigration()
		
		//Prevent crash because of edge case: optional force-unwrapping finding nil
		checkForIdeaExtensionTypeSecurity()
		
		//Finding the global User Settings
		getGlobaUserSettings()
		
		//Deleting all objects that were marked for deletion before the modelContext was known
		for object in objectsMarkedForDeletion { markForDeletion(object) }
	}
	
	//GLOBAL USER SETTINGS
	
	var globalUserSettings: GlobalUserSettings? = nil //This sadly has to be an optional since it is only available after the modelContext is known
	func unwrappedGlobalUserSettings() -> GlobalUserSettings {return globalUserSettings ?? GlobalUserSettings()} //If a non-optional is needed
	
	private var globalUserSettingsStatus: String = "Unavailable" //For the developer window
	
	private func getGlobaUserSettings() {
		let fetch: [GlobalUserSettings] = fetchObjects()
		
		//Look for the globalUserSettings object
		if let existing = fetch.first {
			globalUserSettings = existing
			globalUserSettingsStatus = "Available (Found existing)"
		} else {
			//If it doesnt exist yet, make it
			let new = GlobalUserSettings()
			modelContext?.insert(new)
			globalUserSettings = new
			globalUserSettingsStatus = "Available (Created new)"
		}
		
		//If for some reason there are multiple GlobalUserSettings objects, delete all except for the first one
		if fetch.count > 1 {
			var counter = 0
			let first = fetch.first; for object in fetch {
				if object != first { markForDeletion(object); counter += 1 }
			}
			globalUserSettingsStatus.write(" //Found \(counter) unnecessary Objects")
			customNotificationCentre.shared.new("Multiple GlobalUserSettings instances found: possible Settings loss", duration: 10, level: .technical)
		}
	}
	
	//PERMANENT DELETION SYSTEM
	
	private var objectsMarkedForDeletion: [any PersistentModel] = [] //This array makes sure that if for some reason a model is set to be deleted before the modelContext is known it is being marked for deletion and fully deleted later
	
	private var deletedObjectsInLifecycleCounter: Int = 0 //For the developer window
	private var lastDeletion: Date? = nil //For the developer window
	
	//This function is called when objects are removed from an Array so that they will be fully deleted
	func markForDeletion(_ object: any PersistentModel) {
		DispatchQueue.main.async { //Async, not needed but logical since its not urgent
			if self.modelContext != nil {
				self.modelContext!.delete(object)
				self.deletedObjectsInLifecycleCounter += 1; self.lastDeletion = .now
			}
			else { self.objectsMarkedForDeletion.append(object) }
		}
	}
	
	//IDEAEXTENSION TYPE SECURITY CHECK
	
	///NOTE: This check should not be required. however, During development I have encountered a rare edge case where the optionals in an IdeaExtension where all nil, even tho at least one should contain something. Because they are force-unwrapped (because logically not all can be nil) this leads to an immediate crash. The App does not start and therefore does not allow repairing. To make sure this never happens, this security check is run as soon as the ModelContext is known.

	///NOTE UPDATE: I seem to have fixed the issue. The problem occured in the moveIdea() function. The IdeaExtension relationships where not properly reinitialised but copied even tho the extensions were deleted, which led to relationship errors with SwiftData. I am still keeping this security check tho because in the extremely unlikely case that this problem reoccurs, the app does not immediately crash beyond repair but repairs the data itself.
	
	private func checkForIdeaExtensionTypeSecurity() {
		let fetch: [IdeaExtension] = fetchObjects()
		
		for ideaExtension in fetch {
			switch ideaExtension.type {
			case .checklist: if ideaExtension.checklistContent == nil {
				ideaExtension.checklistContent = Checklist()
				customNotificationCentre.shared.new("Failure on Idea Extension \"\(ideaExtension.title)\": content loss", duration: 10, level: .technical)
			}
			case .imageCatalogue: if ideaExtension.imageCatalogueContent == nil {
				ideaExtension.imageCatalogueContent = ImageCatalogue()
				customNotificationCentre.shared.new("Failure on Idea Extension \"\(ideaExtension.title)\": content loss", duration: 10, level: .technical)
			}
			}
		}
	}
	
	//SAVING THE MODELCONTEXT TO PERSISTENT STORAGE
	
	//Save the modelContext to persistent storage: allows 1 save per second
	private var saveWorkItem: DispatchWorkItem?
	func save() {
		saveWorkItem?.cancel() //Cancel old reset order
		saveWorkItem = DispatchWorkItem {try? self.modelContext?.save()}
		DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: saveWorkItem!)
	}
	
	//MODEL MIGRATION
	
	//If existing Models need to be migrated or modified during development the required code can be placed here.
	private func developmentModelMigration() {
		
	}
	
	//FUNCTIONS
	
	//Basic fetch function, equivilent to @Query
	func fetchObjects<ElementType: PersistentModel>() -> [ElementType] {
		if let fetch = try? modelContext?.fetch(FetchDescriptor<ElementType>()) { return fetch }
		else { return [] }
	}
	
	//This function is called in the developer window view to get insight into the manager
	func getStatus() -> [[String]] {
		return [
			["ModelContext", "\(modelContext != nil ? "Known" : "Unknown")"],
			["globalUserSettings", globalUserSettingsStatus],
			["Objects marked for deletion", "\(objectsMarkedForDeletion.count)"],
			["Objects deleted during lifecycle", "\(deletedObjectsInLifecycleCounter)"],
			["Time since last deletion", "\(lastDeletion?.timeIntervalSinceNow.rounded(), default: "N/A") Seconds (at time of call)"]
		]
	}
}
