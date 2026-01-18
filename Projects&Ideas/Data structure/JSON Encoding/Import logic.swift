//
//	Import logic.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 13.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



//Decoding JSON to Project
@MainActor func decodeProjectFromJson(url: URL, to context: ModelContext) async throws -> Project {
	
	//Politely ask to access the url
	let needsScope = url.startAccessingSecurityScopedResource()
	defer {if needsScope {url.stopAccessingSecurityScopedResource()}}
	
	//Converting to Data
	let data = try Data(contentsOf: url)
	
	//Decoding to DTO
	let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
	let projectDTO = try decoder.decode(ProjectDTO.self, from: data)
	
	//Decoding DTO to Model and inserting
	let project = Project()
	context.insert(project)
	project.setFromDTO(projectDTO, to: context)
	return project
}
