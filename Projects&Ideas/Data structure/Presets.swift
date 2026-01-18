//
//	Presets.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 18.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



var previewproject = Project(title: "Preset project", buckets: [
	Bucket(title: "Bucket 1", ideas: [
		Idea(title: "Idea 1", position: 1),
		Idea(title: "Idea 2", position: 2)
	], position: 1),
	
	Bucket(title: "Bucket 2", ideas: [
		Idea(title: "Idea 3", position: 1),
		Idea(title: "Idea 4", position: 2)
	], position: 2)
], neverUseThisInitialiser: true)
