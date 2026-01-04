//
//  Render Allowance system.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 29.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI

//Render allowance system to render large project views in batches to be able to show a more or less live progress bar.

///NOTE: This system exists because the Projectview of large project takes a long time to load; I wanted to show a live progress bar to the user, which is not possible when SwiftUI is blocking the main thread with loads of view building work. Therefore this system renders the Bucket- and Ideaviews in batches over multiple frames, so that a more or less live progress bar can be shown.

@MainActor @Observable class RenderAllowanceController {
	
	static var shared = RenderAllowanceController() //Singleton
	
	var renderQueue: [UUID] = [] //Which views are still to be rendered
	var renderAllowance: [UUID: Bool] = [:] //Which views are allowed to be rendered
	var fullRenderAllowed: Bool = false //If the rendering process has been finished
	
	var requiredTicks: Int = 0 //How many ticks its going to take to render everything
	var tickCounter: Int = 0 //How many ticks ago the render allowance process was started
	
	private let renderBatchSize: Int = 7 //How many ids are allowed to render per tick
	///NOTE: SwiftUI seems to build views faster if multiple are built per frame, so this batch size is a tradeoff between building speed and progress bar smoothness. With the current value the progress bar still doesnt move too far per frame to be useless but still builds the views acceptably fast.
	///NOTE UPDATE: Seems to load about 130% as long as without batched rendering (Macbook Pro 2019, Sequoia 15.7.2). But, you know, progress bar = visual feedback for the user = good
	
	var renderStart: Date = .now //At what specific time the rendering process was started
	var renderSpeed: Double = 0 //Ticks/s
	var timeLeft: Double = 0 //How many seconds are left based off of the current speed
	
	//ADDITIONAL STATUS/DIAGNOSIC VALUES
	var queryInitiationTimePoint: Date = .now
	var renderProcessEndTimePoint: Date = .now
	
	func getStatus() -> [[String]] { return [
		["Last Query and environment objects loading time", "\(String(format: "%.2f", renderStart.timeIntervalSince(queryInitiationTimePoint)))s"],
		["Last view building time", "\(String(format: "%.2f", renderProcessEndTimePoint.timeIntervalSince(renderStart)))s at \(String(format: "%.2f", renderSpeed))T/s"],
	] }
	
	//Function that is executed every frame
	private func onFrame() { if !fullRenderAllowed {
		//If the render queue is finished, allow a full render and stop the rendering process
		if renderQueue.count <= renderBatchSize {
			fullRenderAllowed = true; reset()
			renderProcessEndTimePoint = .now; return
		}
		//Allow the next id's in line to render and increase the tick counter accordingly
		for _ in 1...renderBatchSize {
			renderAllowance[renderQueue.removeFirst()] = true
			tickCounter += 1
		}
		renderSpeed = Double(tickCounter)/(-renderStart.timeIntervalSinceNow) //Calculate the rendering speed (Ticks/s)
		timeLeft = Double(renderQueue.count)/renderSpeed //Calculating how many seconds are left
		DispatchQueue.main.async {self.onFrame()} //Scheduling for next frame
	} }
	
	private func reset() {
		renderAllowance = [:]
		tickCounter = 0;requiredTicks = 0
		renderQueue = []
	}
	
	//startRender function that is called in the ContentView when a project is opened
	func startRender(forProject: Project) {
		reset(); fullRenderAllowed = false; renderStart = .now
		
		//Make a render queue
		DispatchQueue.main.async {
			for bucket in forProject.buckets.sorted(by: {$0.position < $1.position}) {
				self.renderQueue.append(bucket.id)
				for idea in bucket.ideas.sorted(by: {$0.position < $1.position}) {
					self.renderQueue.append(idea.id)
				}
			}
			self.requiredTicks = self.renderQueue.count
			
			DispatchQueue.main.async {self.onFrame()} //Start the rendering process
		}
	}
	
	//Progress string and progress value for the loading screen
	func getProgressString() -> String {
		if renderQueue.count == 0 {return "Waiting for resources"} else {
			return "\(tickCounter)/\(requiredTicks) at \(String(format: "%.2f", renderSpeed))T/s, \(String(format: "%.1f", timeLeft))S left"
		}
	}
	
	func getProgressValue() -> Double {
		if renderQueue.count == 0 || requiredTicks == 0 {return 0} else {
			return Double(tickCounter)/Double(requiredTicks)
		}
	}
}



//View modifier that can be attached to views that should conform to the render allowance system
private struct RenderAllowanceModifier: ViewModifier {
	
	var renderAllowanceId: UUID
	
	//Optional placeholder values
	var placeholder: Bool
	var width: CGFloat
	var height: CGFloat
	var skeletonCornerSize: CGFloat
	
	func body(content: Content) -> some View {
		//If allowed to render
		if RenderAllowanceController.shared.fullRenderAllowed || RenderAllowanceController.shared.renderAllowance[renderAllowanceId] ?? false {
			content
			
		//Placeholder
		} else {
			if placeholder {
				RoundedRectangle(cornerRadius: skeletonCornerSize) .foregroundStyle(.gray.opacity(0.3))
					.frame(width: width == 0 ? nil : width, height: height == 0 ? nil : height)
			} else {
				EmptyView()
			}
		}
	}
}

extension View {
	func renderAllowance(id: UUID, placeholder: Bool = false, width: CGFloat = 0, height: CGFloat = 0, cornerRadius: CGFloat = 0) -> some View {
		modifier(RenderAllowanceModifier(renderAllowanceId: id, placeholder: placeholder, width: width, height: height, skeletonCornerSize: cornerRadius))
	}
}
