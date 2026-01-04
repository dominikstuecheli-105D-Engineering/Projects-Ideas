//
//  Tags.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 11.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData



@Model class Tag: Identifiable {
	
	var title: String
	var colorIdentifier: Int
	
	//Meta
	var id = UUID()
	var timestamp: Date = Date()
	var isExpandedInSidebar: Bool = true //If the section of this tag is expanded in the sidebar
	
	init(_ title: String = "new Tag", colorIdentifier: Int = 1) {
		self.title = title
		self.colorIdentifier = colorIdentifier
	}
}

//REFERENCE CLASS

//Because the tags have individual position values on each project the projects only store this reference class that has that position value. This reference class has a Relationship to the original Tag object in the modelContext.
@Model class TagReference: Identifiable, PersistentArrayCompatible {
	
	var tag: Tag //The tag that is referenced: saved as a Relationship
	
	//Meta
	var id = UUID()
	var position: Int
	
	init(_ tag: Tag, position: Int = 1) {
		self.tag = tag
		self.position = position
	}
}

//DELETING TAGS

//Because there may still be TagReferences referencing the tag that is to be deleted they have to be deleted themselves first. this function handles that and deleting the tag properly from the ModelContext.
func safelyDeleteTag(_ tag: Tag) {
	let projects: [Project] = ModelContextManager.shared.fetchObjects()
	
	for project in projects {
		for tagReference in project.tags {
			if tagReference.tag == tag {project.tags.remove(tagReference)}
		}
	}
	
	ModelContextManager.shared.globalUserSettings?.tagCollection.removeAll(where: {$0 == tag})
	ModelContextManager.shared.markForDeletion(tag)
}
