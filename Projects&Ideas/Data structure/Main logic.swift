//
//  Main logic.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 20.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//
//
import Foundation
import SwiftData
import SwiftUI



//I coded my own Array add&remove functions to also handle the position values as SwiftData saves everything as a Set and not really as an orderered Array.
protocol PersistentArrayCompatible: Identifiable, PersistentModel {
    var position: Int {get set}
    var id: UUID {get} //For comparisons
}

extension Array where Element: PersistentArrayCompatible {
	
	//Redoes the position values to always start at 1 and be 1 apart.
	mutating func reIndexPositions() {
		var counter: Int = 1
		
		for item in self.sorted(by: {$0.position < $1.position}) {
			item.position = counter
			counter += 1
		}
		
		ModelContextManager.shared.save() //Save everything after change
	}
	
	//Adding elements
	
	///NOTE: When adding an element, for example at position 2 into the Array [Element1=pos 1, Element2=pos 2, Element3=pos 3] it would be best to set the position value of the new element to 1.5 so that the Array would look like this: [Element1=pos 1,  newElement=pos 1.5, Element2=pos 2, Element3=pos 3] And then re-Index the position values: [Element1=pos 1,  newElement=pos 2, Element2=pos 3, Element3=pos 4]. However, the position values are Integers and cannot contain decimal numbers, so the process looks like this: 								[Element1=pos 1, Element2=pos 2, Element3=pos 3]
	///(Doubling all position values) -> 	[Element1=pos 2, Element2=pos 4, Element3=pos 6]
	///(Adding new Element) -> 			[Element1=pos 2,  newElement=pos 3, Element2=pos 4, Element3=pos 6]
	///(re-Indexing position values) -> 	[Element1=pos 1,  newElement=pos 2, Element2=pos 3, Element3=pos 4].
	
	mutating func add(_ element: Element) {
		for item in self { item.position *= 2 } //Doubling the Integer position values so the new element can be inserted "inbetween"
		element.position = element.position*2 - 1 //The elements existing position value is taken as the insert position, as most of the time the element is newly initialised, where the position value can be set in the initialiser. It does not need to be set in the function call here.
		self.append(element)
		reIndexPositions() //Making all position values correct again
	}
	
	//Removing elements
	mutating func remove(_ element: Element, removePersistently: Bool = true) {
		self.removeAll(where: {$0.id == element.id})
		reIndexPositions() //Making all position values correct again because there is one element less
		if removePersistently {ModelContextManager.shared.markForDeletion(element)} //Fully remove from modelContext
	}
	
	//Moving specific elements
	mutating func move(_ element: Element, toPos: Int) {
		for item in self { item.position *= 2 } //Doubling the Integer position values so the element can be moved "inbetween"
		element.position = toPos*2 - 1
		reIndexPositions() //Making all position values correct again
	}
}



//Function to change a value on all Ideas in a Bucket simultaniously
enum bucketChangeForAllActionType {
	case minimized
	case checkOff
}

extension Bucket {
	func changeForAll(_ actionType: bucketChangeForAllActionType, value: Bool = false, project: Project? = nil) {
		switch actionType {
		case .minimized: do { for idea in self.ideas { idea.minimized = value } }
		case .checkOff: do { for idea in self.ideas { project!.checkOffIdea(idea) } }
		}
	}
}



extension Project {
	
	//The order of first adding and then removing the Idea is much easier, as it does not need to take any edge cases into account.
	func moveIdea(_ rootIdea: Idea, toBucket: Bucket, toPosition: Int) {
		guard let rootBucket: Bucket = buckets.first(where: {$0.ideas.contains(rootIdea)} ) else { return }
		
		if rootBucket == toBucket {rootBucket.ideas.move(rootIdea, toPos: toPosition); return} //If the idea does not change buckets, use the PersistentArray .move function
		
		rootIdea.position = toPosition //Updating the position value so that the .add function inserts it at the right position
		toBucket.ideas.add(rootIdea) //Adding the Idea in the place where it is supposed to go
		rootBucket.ideas.remove(rootIdea, removePersistently: false) //Removing the Idea from its old position
	}
	
	//Checking an Idea off: Currently defined as move to the last Bucket and minimize
	func checkOffIdea(_ idea: Idea) {
		guard let newBucket: Bucket = buckets.first(where: {$0.position == buckets.count}) else { return }
		
		idea.minimized = true
		moveIdea(idea, toBucket: newBucket, toPosition: newBucket.ideas.count+1)
	}
	
	//Getting the color of the last bucket for the check-off button
	func getLastBucketColor(_ colorScheme: ColorScheme, respectOpacity: Bool = false) -> Color {
		return buckets.first(where: {$0.position == buckets.count})?.getSelfColor(colorScheme, respectOpacity: respectOpacity) ?? .gray
	}
	
	//Bucket movement
	///NOTE: This enum is not really necessary, it does make the function "nicer" tho
	enum bucketMovementDirection { case left; case right }
	
	func moveBucket(_ pos: Int, direction: bucketMovementDirection) {
		guard let bucket1: Bucket = buckets.first(where: {$0.position == pos}) else { return }
		guard let bucket2: Bucket = buckets.first(where: {(direction == .left ? $0.position == pos-1 : $0.position == pos+1)}) else { return }
		
		if (direction == .left ? pos > 1 : pos < buckets.count) {
			switch direction {
			case .left: bucket1.position -= 1; bucket2.position += 1
			case .right: bucket1.position += 1; bucket2.position -= 1
			}
		}
	}
    
	//The Summary function that is used for the small "summary" in the Project settings
    func summary() -> String {
        var ideaCounter = 0
        
        for bucket in buckets {
            ideaCounter += bucket.ideas.count
        }
        
        return "\(ideaCounter) Ideas in \(buckets.count) Buckets"
    }
	
	//The context that is sent with a peer-to-peer connection invite
	func sendableDataContext(encodedSize: Int) -> SendableDataContext {
		let formatter = ByteCountFormatter() //nice formatting for the file size
		formatter.countStyle = .file; formatter.includesUnit = true
		let sizeString = formatter.string(fromByteCount: Int64(encodedSize))
		
		return SendableDataContext(primary: title, secondary: summary(), tertiary: sizeString)
	}
}
