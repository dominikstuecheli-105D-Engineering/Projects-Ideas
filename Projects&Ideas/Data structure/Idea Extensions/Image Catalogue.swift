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
}



@Model class ImageCatalogue: ValidIdeaExtension {
    
    //Content
	@Relationship(deleteRule: .cascade) var images: [ImageCatalogueItem]
    
    //Meta
    var type: IdeaExtensionType
    
    init(images: [ImageCatalogueItem] = []) {
        self.type = .imageCatalogue
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
}
