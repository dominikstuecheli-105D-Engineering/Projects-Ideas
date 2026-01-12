//
//  Checklist DTO.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.01.2026.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers



struct ChecklistItemDTO: Codable {
	
	//Content
	var title: String
	var checked: Bool
	
	//Meta
	var position: Int
	
	init(of: ChecklistItem) {
		self.title = of.title
		self.checked = of.checked
		self.position = of.position
	}
}
