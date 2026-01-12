//
//  IdeaExtensions Main DTO.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.01.2026.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



struct IdeaExtensionDTO: Codable {
    
    //Content
    var title: String

	var checklistContent: [ChecklistItemDTO]
	var imageCatalogueContent: [ImageCatalogueItemDTO]
	
    //Meta
	var type: IdeaExtensionType
    var position: Int
    var minimized: Bool
	
	init(of: IdeaExtension) {
		self.title = of.title
		self.type = of.type
		self.position = of.position
		self.minimized = of.minimized
		
		//Checklist items
		self.checklistContent = []
		if of.checklistContent != nil {
			for item in of.checklistContent!.items {
				self.checklistContent.append(ChecklistItemDTO(of: item))
			}
		}
		
		//Image catalogue items
		self.imageCatalogueContent = []
		if of.imageCatalogueContent != nil {
			for item in of.imageCatalogueContent!.images {
				self.imageCatalogueContent.append(ImageCatalogueItemDTO(of: item))
			}
		}
	}
}

extension IdeaExtension {
	func getDTO() -> IdeaExtensionDTO {return IdeaExtensionDTO(of: self)}
}
