//
//  Other Stuff.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 20.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData



//Preview and Preset Project
let previewproject = Project(title: "new Project", buckets: [
	Bucket(title: "Bucket 1", ideas: [
		Idea(title: "Idea 1", desc: "Description", position: 1),
		Idea(title: "Idea 2", desc: "Description", position: 2)
	], position: 1),
	Bucket(title: "Bucket 2", ideas: [
		Idea(title: "Idea 3", desc: "Description", position: 1),
		Idea(title: "Idea 4", desc: "Description", position: 2)
	], position: 2)
])

let presetproject = Project(title: "new Project", buckets: [
	Bucket(title: "Empty Bucket", ideas: [], position: 1)
])
