//
//  ProjectLoadingScreen.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 29.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



//this view is shown while the view of a project is being built.
struct ProjectLoadingScreen: View {
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@State var frame: CGFloat = 20
	private let widthFactor: CGFloat = 10
	
	//Progress value
	private let progress: Double = {
		var value = RenderAllowanceController.shared.getProgressValue()
		if value < 0 {value = 0}
		if value > 1 {value = 1}
		return value
	}()
	
	//Text that is shown at the bottom
	private let motivationalText: String = {
		var string = ""
		if RenderAllowanceController.shared.getProgressValue() < 0.3 {string = "We're getting there..."}
		else if RenderAllowanceController.shared.getProgressValue() < 0.6 {string = "Not much longer..."}
		else if RenderAllowanceController.shared.getProgressValue() < 0.9 {string = "Almost done..!"}
		else {string = "Done!"}
		return string
	}()
	
	//Emoji that is shown in the progress bar
	private let emojis: [String] = ["😐", "🙄", "🫨", "😬", "🐢", "🐨", "📦", "🌸", "😊", "🧐", "😑", "☹️"]
	private func randomEmoji() -> String {return emojis.randomElement()!}
	
    var body: some View {
		TimelineView(.animation) {_ in
			VStack(spacing: standartPadding) {
				
				//TITLE
				Text("Building project")
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .semibold, design: .default))
				
				//Progress detail text
				Text(RenderAllowanceController.shared.getProgressString())
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
				
				ZStack {
					//Background of progress bar
					RoundedRectangle(cornerRadius: standartPadding)
						.foregroundStyle(.gray.opacity(0.2))
					
					//Actual progress bar
					RoundedRectangle(cornerRadius: standartPadding)
						.frame(width: (frame*widthFactor-frame)*progress + frame, height: frame)
					
						.foregroundStyle(.blue.opacity(0.8))
					
					//Small Rectangle with emoji :)
						.overlay(alignment: .trailing) {
							ZStack {
								RoundedRectangle(cornerRadius: standartPadding*0.85)
									.frame(width: frame*0.85, height: frame*0.85)
									.padding(frame*0.075)
									.foregroundStyle(.white)
								
								Text(randomEmoji())
									.font(.system(size: frame*0.85*0.65, weight: .regular, design: .default))
									//.rotationEffect(Angle(degrees: progress*360*5), anchor: .center)
							}
						}
					
						.padding(.trailing, (frame*widthFactor-frame)*(1-progress))
				}
				
				//Motivational text
				Text(motivationalText)
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
			}
			.frame(width: frame*widthFactor, height: frame)
		}
		.onAppear {frame = globalUserSettings.UISize.large}
    }
}

#Preview {
	ProjectLoadingScreen()
		.padding(standartPadding*2)
		.environment(GlobalUserSettings())
}
