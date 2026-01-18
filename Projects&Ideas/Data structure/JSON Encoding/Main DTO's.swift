//
//	Main DTO's.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI



struct IdeaDTO: Codable {
	
	//Content
	var title: String
	var desc: String
	var extensions: [IdeaExtensionDTO]
	
	//Meta
	var position: Int
	var timestamp: Date
	var minimized: Bool
	
	init(of: Idea) {
		self.title = of.title
		self.desc = of.desc
		self.position = of.position
		self.timestamp = of.timestamp
		self.minimized = of.minimized
		
		self.extensions = []
		for extensionItem in of.extensions {
			self.extensions.append(extensionItem.getDTO())
		}
	}
}

extension Idea {
	func getDTO() -> IdeaDTO {return IdeaDTO(of: self)}
}





struct BucketDTO: Codable {
	
	//Content
	var title: String
	var ideas: [IdeaDTO]
	var colorIdentifier: Int
	
	//Meta
	var position: Int
	
	init(of: Bucket) {
		self.title = of.title
		self.colorIdentifier = of.colorIdentifier
		self.position = of.position
		
		self.ideas = []
		for idea in of.ideas {
			self.ideas.append(idea.getDTO())
		}
	}
}

extension Bucket {
	func getDTO() -> BucketDTO {return BucketDTO(of: self)}
}



struct ProjectDTO: Codable {
	
	//Content
	var title: String
	var buckets: [BucketDTO]
	
	//Tags
	var tags: [TagDTO]
	
	//Meta
	var timestamp: Date
	var id: UUID
	
	//Settings
	var ideaDeletionRequiresConfirmation: Bool
	var useScrollViewForBuckets: Bool
	var scrollViewBucketWidth: Int
	var useCheckOffIdeaButton: Bool
	
	init(of: Project) {
		self.title = of.title
		self.timestamp = of.timestamp
		self.id = of.id
		
		self.ideaDeletionRequiresConfirmation = of.ideaDeletionRequiresConfirmation
		self.useScrollViewForBuckets = of.useScrollViewForBuckets
		self.scrollViewBucketWidth = of.scrollViewBucketWidth
		self.useCheckOffIdeaButton = of.useCheckOffIdeaButton
		
		self.buckets = []
		for bucket in of.buckets {self.buckets.append(bucket.getDTO())}
		
		self.tags = []
		for tagReference in of.tags {self.tags.append(tagReference.tag.getDTO())}
	}
	
	//Actual exporting to Data function
	func encode() throws -> Data {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.prettyPrinted]
		return try encoder.encode(self)
	}
}

extension Project {
	func getDTO() -> ProjectDTO {return ProjectDTO(of: self)}
	func getFile() throws -> ProjectFile {return try ProjectFile(of: self)}
}



struct ProjectFile: FileDocument {
	static var readableContentTypes: [UTType] = [.json]
	
	let data: Data
	
	//Initialise with Project
	init(of: Project) throws {
		self.data = try of.getDTO().encode()
	}
	
	//Initialise with configuration? Idunno, SwiftUI needs this tho
	init(configuration: ReadConfiguration) throws {
		if let newData = configuration.file.regularFileContents {
			self.data = newData
		} else {
			throw CocoaError(.fileReadCorruptFile)
		}
	}
	
	//Exporting to JSON
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		return FileWrapper(regularFileWithContents: data)
	}
}
