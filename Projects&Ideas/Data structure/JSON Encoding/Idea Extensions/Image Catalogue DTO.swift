//
//  Image Catalogue DTO.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.01.2026.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



struct ImageCatalogueItemDTO: Codable {
    
    //Content
	var image: String
    var title: String
    
    //Meta
    var position: Int
    
	init(of: ImageCatalogueItem) {
		self.title = of.title
		self.position = of.position
		self.image = of.image.base64EncodedString()
	}
}
