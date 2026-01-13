//
//	Tag DTO and logic.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



struct TagDTO: Codable {
	
	var title: String
	var colorIdentifier: Int
	
	//Meta
	var timestamp: Date
	var isExpandedInSidebar: Bool
	
	init(of: Tag) {
		self.title = of.title
		self.colorIdentifier = of.colorIdentifier
		self.timestamp = of.timestamp
		self.isExpandedInSidebar = of.isExpandedInSidebar
	}
}

extension Tag {
	func getDTO() -> TagDTO {
		return TagDTO(of: self)
	}
}



//TAG INTEGRATION
///Function to connect the tags the imported Project is marked with with the existing tag collection. If the tag does not already exist, it is created. A tag counts as "the same" if title and colour are identical.
func integrateTagsOfProjectDTO(tags: [TagDTO], project: Project) {
	let globalUserSettings = ModelContextManager.shared.unwrappedGlobalUserSettings()
	
	for tag in tags {
		if let found = globalUserSettings.tagCollection.first(where: {$0.title == tag.title && $0.colorIdentifier == tag.colorIdentifier}) {
			//If an identical, existing tag is found, add a reference to the project
			project.tags.add(TagReference(found, position: project.tags.count+1))
		} else {
			//If no existing tag is found, create a new one
			let newTag = Tag(tag.title, colorIdentifier: tag.colorIdentifier)
			globalUserSettings.tagCollection.append(newTag)
			project.tags.add(TagReference(newTag, position: project.tags.count+1))
		}
	}
}
