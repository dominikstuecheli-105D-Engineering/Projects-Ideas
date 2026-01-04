//
//  GlobalUserSettings.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 11.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class GlobalUserSettings {
	
	@Relationship(deleteRule: .cascade) var UISize: UISizeConcept = UISizeConcept() //UISize
	
	var lastOpenedProject: UUID? = nil //Remember the last opened Project
	
	var tagCollection: [Tag] = [] //The global list of tags that can be attached to projects with TagReferences
	
	var categoriseByTags: Bool = false //How the sidebar list is categorized
	
	init() {}
}

//UI Size: dictates the size of more or less all UI Elements. Useful accessibility feature and a fix differences between macOS and iOS.
@Model class UISizeConcept {
	var sizeValue: Int
	
	var large: CGFloat = 0
	var small: CGFloat = 0
	
	var largeText: CGFloat = 0
	var mediumText: CGFloat = 0
	var smallText: CGFloat = 0
	
	init() {
		#if os(iOS)
		self.sizeValue = 24
		#else
		self.sizeValue = 20
		#endif
		self.updateSizes()
	}
	
	func updateSizes() {
		self.sizeValue = min(max(self.sizeValue,16),40)
		let value = CGFloat(sizeValue)
		self.large = value*1.5
		self.small = value
		
		self.largeText = value*1.25
		self.mediumText = value*0.8
		self.smallText = value*0.7
	}
	
	func larger() { self.sizeValue += 2; self.updateSizes() }
	func smaller() { self.sizeValue -= 2; self.updateSizes() }
}
