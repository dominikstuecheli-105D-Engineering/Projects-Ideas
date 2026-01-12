//
//  Main.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 02.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers



@Model class Idea: Identifiable, PersistentArrayCompatible {
    
    //Content
    var title: String
    var desc: String
	@Relationship(deleteRule: .cascade) var extensions: [IdeaExtension]
    
    //Meta
    var id = UUID()
    var position: Int
    var timestamp = Date()
    
    var minimized: Bool
    
    init(title: String = "", desc: String = "", position: Int, extensions: [IdeaExtension] = []) {
        self.title = title
        self.desc = desc
        self.extensions = extensions
        self.position = position
        self.minimized = false
    }
	
	//Another initialiser to copy another instance of this class
	init(copy: Idea, newPosition: Int? = nil) {
		self.title = copy.title
		self.desc = copy.desc
		
		if newPosition != nil {
			self.position = newPosition ?? 1
		} else {
			self.position = copy.position
		}
		
		self.minimized = copy.minimized
		
		self.extensions = []
		for ext in copy.extensions {
			self.extensions.append(IdeaExtension(copy: ext))
		}
	}
	
	//Another initialiser for JSON importing
	init(fromDTO: IdeaDTO) {
		self.title = fromDTO.title
		self.desc = fromDTO.desc
		self.position = fromDTO.position
		self.timestamp = fromDTO.timestamp
		self.minimized = fromDTO.minimized
		
		self.extensions = []
		for extensionDTO in fromDTO.extensions {
			self.extensions.append(IdeaExtension(fromDTO: extensionDTO))
		}
	}
}

//Transferable stuff for Drag&Drop functionality
///NOTE: The Transferable only contains the Idea id and not really the Idea content. This makes it much easier as the Idea may not just be 1 class but a relationship with IdeaExtension classes.
class IdeaTransferable: Transferable, Codable {
	var id: UUID
	
	init(idea: Idea) {self.id = idea.id}
	
	static var transferRepresentation: some TransferRepresentation {
		CodableRepresentation(contentType: .data)
	}
}

extension UTType {static let ideaTransferableType = UTType(exportedAs: "com.Projects&Ideas.ideaTransferable")}



@Model class Bucket: Identifiable, PersistentArrayCompatible {
    //Content
    var title: String
	@Relationship(deleteRule: .cascade) var ideas: [Idea]
    var colorIdentifier: Int
    
    //Meta
    var id = UUID()
    var position: Int
    
    init(title: String = "", ideas: [Idea] = [], position: Int) {
        self.title = title
        self.ideas = ideas
        self.position = position
        self.colorIdentifier = 1
    }
	
	//Another initialiser for JSON importing
	init(fromDTO: BucketDTO) {
		self.title = fromDTO.title
		self.colorIdentifier = fromDTO.colorIdentifier
		self.position = fromDTO.position
		
		self.ideas = []
		for idea in fromDTO.ideas {
			self.ideas.append(Idea(fromDTO: idea))
		}
	}
}



@Model class Project: Identifiable {
    //Content
    var title: String
	@Relationship(deleteRule: .cascade) var buckets: [Bucket]
	
	//Tags
	var tags: [TagReference] = []
    
    //Meta
    var id = UUID()
    var timestamp = Date()
	@Relationship(deleteRule: .cascade) var settings: ProjectSettings

	init(title: String = "new Project", buckets: [Bucket] = [], tags: [TagReference] = []) {
        self.title = title
        self.buckets = buckets
        self.settings = ProjectSettings()
		self.tags = tags
    }
	
	//Another initialiser for JSON importing
	init(fromDTO: ProjectDTO) {
		self.title = fromDTO.title
		self.timestamp = fromDTO.timestamp
		self.settings = ProjectSettings(fromDTO: fromDTO.settings)
		
		self.buckets = []
		for bucket in fromDTO.buckets {
			self.buckets.append(Bucket(fromDTO: bucket))
		}
		
		integrateTagsOfProjectDTO(tags: fromDTO.tags, project: self)
	}
}



//All Project specific settings are saved here
@Model class ProjectSettings {
    
    var ideaDeletionRequiresConfirmation: Bool = true
    var useScrollViewForBuckets: Bool = false
	var scrollViewBucketWidth: Int = 350
	var useCheckOffIdeaButton: Bool = false

	init() { }
	
	//Another initialiser for JSON importing
	init(fromDTO: ProjectSettingsDTO) {
		self.ideaDeletionRequiresConfirmation = fromDTO.ideaDeletionRequiresConfirmation
		self.useScrollViewForBuckets = fromDTO.useScrollViewForBuckets
		self.scrollViewBucketWidth = fromDTO.scrollViewBucketWidth
		self.useCheckOffIdeaButton = fromDTO.useCheckOffIdeaButton
	}
}
