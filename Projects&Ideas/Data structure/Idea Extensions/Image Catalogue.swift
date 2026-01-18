//
//  Image Catalogue.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 20.09.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



//Subclass of ImageCatalogue; Contains 1 image and its image title
@Model class ImageCatalogueItem: Identifiable, PersistentArrayCompatible {
    
    //Content
	@Attribute(.externalStorage) var image: Data
    var title: String
    
    //Meta
    var id: UUID = UUID()
    var position: Int
    
    init(_ image: Data, position: Int) {
        self.image = image
        self.title = ""
        self.position = position
    }
	
	//Another initialiser to copy another instance of this class
	init(copy: ImageCatalogueItem) {
		self.title = copy.title
		self.position = copy.position
		
		self.image = copy.image
	}
	
	//Another initialiser for JSON importing
	init?(fromDTO: ImageCatalogueItemDTO) {
		self.title = fromDTO.title
		self.position = fromDTO.position
		if let data = Data(base64Encoded: fromDTO.image) {
			self.image = data
		} else {
			customNotificationCentre.shared.new("Lost Image \"\(fromDTO.title)\" while decoding Base64 String", duration: 10, level: .technical)
			return nil
		}
	}
}



@Model class ImageCatalogue: ValidIdeaExtension {
    
    //Content
	@Relationship(deleteRule: .cascade) var images: [ImageCatalogueItem]
    
    //Meta
	var type: IdeaExtensionType = IdeaExtensionType.imageCatalogue
    
    init(images: [ImageCatalogueItem] = []) {
        self.images = images
    }
	
	//Another initialiser to copy another instance of this class
	init(copy: ImageCatalogue) {
		self.type = copy.type
		
		self.images = []
		for item in copy.images {
			self.images.append(ImageCatalogueItem(copy: item))
		}
	}
	
	//Another initialiser for JSON importing
	init(fromDTOs: [ImageCatalogueItemDTO], to context: ModelContext) {
		self.images = []
		for item in fromDTOs {
			if let imageItem = ImageCatalogueItem(fromDTO: item) {
				context.insert(imageItem)
				self.images.append(imageItem)
			}
		}
	}
}
