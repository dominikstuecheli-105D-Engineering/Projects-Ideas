//
//  ProjectSettingsview.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 08.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//



import SwiftUI



struct ProjectSettingsview: View {
    @Environment(\.modelContext) var modelContext
    
	@Binding var settingsOpened: Bool
    @Bindable var project: Project
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
    
	@State var tagAddingWindowOpen: Bool = false
	@State var tagScrollPosition: ScrollPosition = ScrollPosition(y: 0)
	
    var body: some View {
		VStack(spacing: standartPadding) {
			
			//TITLEBAR
			
			HStack {
				//Title
				Spacer(minLength: 3)
				customFastTextField(placeHolder: "Project title", string: $project.title)
				
				//TextEditor
					.font(.system(size: globalUserSettings.UISize.largeText, weight: .bold, design: .default))
				
				standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationStartAngle: 45) {
					settingsOpened = false
				}
			}
			//The Padding is handled weirdly here, but this is so that the hoverEffect on iOS works properly
			.padding([.leading, .trailing], standartSheetPadding)
			
			Divider()
			
			//TAGS
			
			HStack(spacing: 0) {
				Text("Tags:")
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
				
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: standartPadding) {
						ForEach(project.tags.sorted(by: {$0.position < $1.position})) { tagReference in
							TagView(tagReference.tag) {} removeAction: {
								withAnimation(standartAnimation) {project.tags.remove(tagReference)}
							}
						}
					}
					.padding(.leading, standartPadding*2)
				} .scrollPosition($tagScrollPosition)
				
				//Mask for the nice fade effects of the tag list
				.mask(
					GeometryReader { geometry in
						LinearGradient(gradient: Gradient(stops: [
								.init(color: .clear, location: 0),
								.init(color: .black, location: standartPadding*2 / geometry.size.width),
								.init(color: .black, location: 1 - (standartPadding*2 / geometry.size.width)),
								.init(color: .clear, location: 1),
						]),
							startPoint: .leading, endPoint: .trailing)
					}
				)
				
				//Add tags to project
				standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true) {
					tagAddingWindowOpen.toggle()
				}
				
				//Popover to add tags to the project
				.popover(isPresented: $tagAddingWindowOpen) {
					TagSelector(opened: $tagAddingWindowOpen, existingTags: $project.tags, scrollPosition: $tagScrollPosition)
				}
			}
			.padding([.leading, .trailing], standartSheetPadding)
			
			Divider()
			
			//SUMMARY
			
			Text("Project settings")
				.font(.system(size: globalUserSettings.UISize.largeText, weight: .regular, design: .default))
			
			//Timestamp
			Text("Created \(project.timestamp.formatted(date: .abbreviated, time: .shortened))")
				.font(.footnote)
				.foregroundStyle(primaryUIelement)
			
			//Summary
			Text(project.summary())
				.font(.footnote)
				.foregroundStyle(primaryUIelement)
			
			//ACTUAL SETTINGS
			
			standartCheckbox(label: "Require confirmation to delete Ideas and Idea Extensions", isChecked: $project.settings.ideaDeletionRequiresConfirmation)
				.padding([.leading, .trailing], standartSheetPadding)
			
			standartCheckbox(label: "Horizontal scroll view for Buckets", isChecked: $project.settings.useScrollViewForBuckets)
				.padding([.leading, .trailing], standartSheetPadding)
			
				.onChange(of: project.settings.useScrollViewForBuckets) { _, new in settingsOpened = false}
			
			standartCheckbox(label: "Check-off button for Ideas", isChecked: $project.settings.useCheckOffIdeaButton)
				.padding([.leading, .trailing], standartSheetPadding)
			
			//Delete project button
			standartButton(systemName: "Delete project", color: .red, frame: globalUserSettings.UISize.smallText, withBackground: true, containsText: true, withAlert: true, alertTitle: "Delete \(project.title)?") {
				withAnimation {
					modelContext.delete(project)
					
					//Notification on delete
					customNotificationCentre.shared.new("Deleted Project: \(project.title)", level: .destructive)
				}
			}
		}
		.padding([.top, .bottom], standartSheetPadding)
		//Because it is shown in sheets, no further frame stuff is needed
    }
}

#Preview {
	@Previewable @State var settingsOpened: Bool = true
    ProjectSettingsview(settingsOpened: $settingsOpened, project: previewproject)
		.environment(GlobalUserSettings())
		.frame(width: 450)
}
