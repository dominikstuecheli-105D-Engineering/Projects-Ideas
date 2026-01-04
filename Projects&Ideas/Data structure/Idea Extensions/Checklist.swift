//
//  Checklist.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 05.09.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers



@Model class ChecklistItem: Identifiable, PersistentArrayCompatible {
    
    //Content
    var title: String
    var checked: Bool
    
    //Meta
    var id = UUID()
    var position: Int
    
    init(_ title: String, position: Int) {
        self.title = title
        self.checked = false
        self.position = position
    }
	
	//Another initialiser to copy another instance of this class
	init(copy: ChecklistItem) {
		self.title = copy.title
		self.checked = copy.checked
		self.position = copy.position
	}
	
	//Another initialiser to copy from transferable
	init(fromTransferable: ChecklistItemTransferable, newPosition: Int) {
		self.title = fromTransferable.title
		self.checked = fromTransferable.checked
		self.position = newPosition
	}
}

//Transferable stuff for Drag&Drop functionality
class ChecklistItemTransferable: Transferable, Codable {
	
	//Content
	var title: String
	var checked: Bool
	
	//Meta
	var id = UUID()
	
	init(from: ChecklistItem) {
		self.title = from.title
		self.checked = from.checked
		self.id = from.id
	}
	
	static var transferRepresentation: some TransferRepresentation {
		CodableRepresentation(contentType: .data)
	}
}

extension UTType {
	static let checklistItemTransferableType = UTType(exportedAs: "com.Projects&Ideas.checklistItemTransferable")
}



@Model class Checklist: ValidIdeaExtension {
    
    //Content
	@Relationship(deleteRule: .cascade) var items: [ChecklistItem]
	
	//Meta
    var type: IdeaExtensionType
    
	init(_ items: [ChecklistItem] = [ChecklistItem(" ", position: 1)]) {
        self.type = .checklist
		self.items = items
    }
	
	//Another initialiser to copy another instance of this class
	init(copy: Checklist) {
		self.type = copy.type
		self.items = []
		
		for item in copy.items {
			self.items.append(ChecklistItem(copy: item))
		}
	}
}
