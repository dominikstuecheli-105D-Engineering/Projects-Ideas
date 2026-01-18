//
//  IdeaExtensions Main.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 30.08.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



protocol ValidIdeaExtension {
	var type: IdeaExtensionType {get}
}

//All Idea Extension are stored inside this class in the content variable for easier type handling.

///NOTE: In the newer SwiftData versions class inheritance is possible, which would have made this much simpler. However, I am not sure if that would still work on older iOS and macOS versions as these newer SwiftData versions are mainly made for iOS/macOS 26+, So I am keeping this less clean but working solution.

@Model class IdeaExtension: Identifiable, PersistentArrayCompatible {
    
    //Content
    var title: String
	
	//Every type of IdeaExtension has is own class which is stored here. Only the content of the IdeaExtension type is used, the others are just nil.
	@Relationship(deleteRule: .cascade) var checklistContent: Checklist? = nil
	@Relationship(deleteRule: .cascade) var imageCatalogueContent: ImageCatalogue? = nil
	
    //Meta
	var type: IdeaExtensionType
    var id = UUID()
    var position: Int
    var minimized: Bool
	
	init(_ type: IdeaExtensionType, content: any ValidIdeaExtension, position: Int) {
		self.title = getIdeaExtensionTitle(type: type)
		
		switch type {
		case .checklist: self.checklistContent = content as? Checklist
		case .imageCatalogue: self.imageCatalogueContent = content as? ImageCatalogue
		}
		
		self.type = type
		self.position = position
		self.minimized = false
	}
	
	//Another initialiser to copy another instance of this class
	init(copy: IdeaExtension) {
		self.title = copy.title
		self.type = copy.type
		self.position = copy.position
		self.minimized = copy.minimized
		
		self.checklistContent = (copy.checklistContent == nil ? nil : Checklist(copy: copy.checklistContent!))
		self.imageCatalogueContent = (copy.imageCatalogueContent == nil ? nil : ImageCatalogue(copy: copy.imageCatalogueContent!))
	}
	
	//Another initialiser for JSON importing
	init(fromDTO: IdeaExtensionDTO, to context: ModelContext) {
		self.title = fromDTO.title
		self.type = fromDTO.type
		self.position = fromDTO.position
		self.minimized = fromDTO.minimized
		
		switch fromDTO.type {
		case .checklist: do {
			let newContent = Checklist(fromDTOs: fromDTO.checklistContent, to: context)
			context.insert(newContent)
			self.checklistContent = newContent
			self.imageCatalogueContent = nil
		}
		case .imageCatalogue: do {
			let newContent = ImageCatalogue(fromDTOs: fromDTO.imageCatalogueContent, to: context)
			context.insert(newContent)
			self.imageCatalogueContent = newContent
			self.checklistContent = nil
		}
		}
	}
}



enum IdeaExtensionType: String, Codable, CaseIterable {
    case checklist
    case imageCatalogue
}

//The enum names are not that "polished" so this function gets the cleaner names to be shown to the user
func getIdeaExtensionTitle(type: IdeaExtensionType) -> String {
    switch type {
    case .checklist: return "Checklist"
    case .imageCatalogue: return "Image gallery"
    }
}
