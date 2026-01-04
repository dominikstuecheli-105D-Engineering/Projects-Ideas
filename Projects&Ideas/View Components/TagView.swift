//
//  TagView.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 11.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct TagViewOLD: View {
	
	@Bindable var tag: Tag
	
	var addAction: () -> Void
	var removeAction: () -> Void
	
	func backgroundColor() -> Color {
		return getColor(tag.colorIdentifier, colorScheme, respectOpacity: false).opacity(0.85)
	}
	
	init(_ tag: Tag, addAction: @escaping () -> Void, removeAction: @escaping () -> Void) {
		self.tag = tag
		self.addAction = addAction
		self.removeAction = removeAction
	}
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(\.colorScheme) var colorScheme
	
	@State var settingsExpanded: Bool = false
	@State var hoverEffect: Bool = false
	
    var body: some View {
		HStack(spacing: 0) {
			
			//LEADING TAG HOLE THING (DESIGN)
			HStack(spacing: 3) {
				ZStack {
					Circle() .foregroundStyle(.black.opacity(0.5))
					
					Circle() .foregroundStyle(.gray)
						.frame(width: globalUserSettings.UISize.small - standartPadding*2, height: globalUserSettings.UISize.small - standartPadding*2)
				}
				.allowsHitTesting(false)
				.frame(width: globalUserSettings.UISize.small - standartPadding, height: globalUserSettings.UISize.small - standartPadding)
					.padding(.leading, standartPadding/2)
				
				Text(tag.title)
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
					.lineLimit(1)
			}
			.padding([.leading, .trailing], 3)
			.frame(height: globalUserSettings.UISize.large)
			.background(backgroundColor())
			.customHoverEffect()
			
			.onTapGesture {addAction()}
			
			Divider()
				.frame(height: globalUserSettings.UISize.large)
				.background(backgroundColor())
			
			//REMOVE ACTION
			Group {
				Image(systemName: "trash") .resizable() .scaledToFit()
					.bold()
					.frame(height: globalUserSettings.UISize.small*0.75)
			}
			.frame(height: globalUserSettings.UISize.large)
			.padding([.leading, .trailing], 3)
			.background(backgroundColor())
			.customHoverEffect()
			
			.onTapGesture {removeAction()}
			
			Divider()
				.frame(height: globalUserSettings.UISize.large)
				.background(backgroundColor())
			
			//OPEN TAG SETTINGS
			Group {
				Image(systemName: "gearshape") .resizable() .scaledToFit()
					.bold()
					.frame(height: globalUserSettings.UISize.small*0.75)
			}
			.frame(height: globalUserSettings.UISize.large)
			.padding([.leading, .trailing], 3)
			.background(backgroundColor())
			.customHoverEffect()
			
			.onTapGesture {
				settingsExpanded.toggle()
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: standartPadding))
		
		//Settings
		.popover(isPresented: $settingsExpanded) {
			VStack(spacing: standartPadding) {
				customFastTextField(placeHolder: "Tag title", string: $tag.title)
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
					.padding(3)
					.background(.gray.opacity(0.1))
					.clipShape(RoundedRectangle(cornerRadius: standartPadding))
				customColorPicker(selectedColorIdentifier: $tag.colorIdentifier)
			}
			.padding(standartSheetPadding)
		}
		.fixedSize(horizontal: true, vertical: false)
    }
}



struct TagView: View {
	
	@Bindable var tag: Tag
	
	var addAction: () -> Void //What to do when the tag is "added" (when the main body, so the text is clicked)
	var removeAction: () -> Void //What to do when the tag is "removed" (when the trashcan is clicked)
	
	func backgroundColor() -> Color {
		return getColor(tag.colorIdentifier, colorScheme, respectOpacity: false).opacity(0.85)
	}
	
	init(_ tag: Tag, addAction: @escaping () -> Void, removeAction: @escaping () -> Void) {
		self.tag = tag
		self.addAction = addAction
		self.removeAction = removeAction
	}
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(\.colorScheme) var colorScheme
	
	@State var settingsExpanded: Bool = false
	@State var hoverEffect: Bool = false
	
	var body: some View {
		HStack(spacing: 0) {
			
			//LEADING TAG HOLE THING (DESIGN)
			HStack(spacing: 3) {
				ZStack {
					Circle() .foregroundStyle(.black.opacity(0.5))
					
					Circle() .foregroundStyle(.gray)
						.frame(width: globalUserSettings.UISize.small - standartPadding*2, height: globalUserSettings.UISize.small - standartPadding*2)
				}
				.allowsHitTesting(false)
				.frame(width: globalUserSettings.UISize.small - standartPadding, height: globalUserSettings.UISize.small - standartPadding)
					.padding(.leading, standartPadding/2)
				
				Text(tag.title)
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
					.lineLimit(1)
			}
			.padding([.leading, .trailing], 3)
			.frame(height: globalUserSettings.UISize.large)
			
			//The background color is handled differently on macOS than on iOS because of how the hoverEffect on iOS works. this is why there are so many #ifs here.
			#if os(macOS)
			.background(backgroundColor())
			#endif
			.customHoverEffect()
			
			.onTapGesture {addAction()}
			
			Divider() .frame(height: globalUserSettings.UISize.large)
			#if os(macOS)
			.background(backgroundColor())
			#endif
			
			//REMOVE ACTION
			Group {
				Image(systemName: "trash") .resizable() .scaledToFit()
					.bold()
					.frame(height: globalUserSettings.UISize.small*0.75)
			}
			.frame(height: globalUserSettings.UISize.large)
			.padding([.leading, .trailing], 3)
			#if os(macOS)
			.background(backgroundColor())
			#endif
			.customHoverEffect()
			
			.onTapGesture {removeAction()}
			
			Divider() .frame(height: globalUserSettings.UISize.large)
			#if os(macOS)
			.background(backgroundColor())
			#endif
			
			//OPEN TAG SETTINGS
			Group {
				Image(systemName: "gearshape") .resizable() .scaledToFit()
					.bold()
					.frame(height: globalUserSettings.UISize.small*0.75)
			}
			.frame(height: globalUserSettings.UISize.large)
			.padding([.leading, .trailing], 3)
			#if os(macOS)
			.background(backgroundColor())
			#endif
			.customHoverEffect()
			
			.onTapGesture {
				settingsExpanded.toggle()
			}
		}
		#if os(iOS)
		.background(backgroundColor())
		#endif
		.clipShape(RoundedRectangle(cornerRadius: standartPadding))
		
		//Settings
		.popover(isPresented: $settingsExpanded) {
			VStack(spacing: standartPadding) {
				customFastTextField(placeHolder: "Tag title", string: $tag.title)
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
					.padding(3)
					.background(.gray.opacity(0.1))
					.clipShape(RoundedRectangle(cornerRadius: standartPadding))
				customColorPicker(selectedColorIdentifier: $tag.colorIdentifier)
			}
			.padding(standartSheetPadding)
		}
		.fixedSize(horizontal: true, vertical: false)
	}
}



//Selector view to also handle an array of available tags so that an object cant have two TagReferences to the same Tag
struct TagSelector: View {
	
	@Binding var opened: Bool //To detect when it is being opened
	@Binding var existingTags: [TagReference] //The tags the object this is attached to already has
	@State var availableTags: [Tag] = [] //The local set of tags that can still be added to the object
	
	@Binding var scrollPosition: ScrollPosition //If the selector is visually connected to a scrollview it should scroll to the new tag if one is added
	
	private func reDoAvailableTags() {
		withAnimation(standartAnimation) {
			var newAvailableTags: [Tag] = []
			for tag in globalUserSettings.tagCollection {
				if !existingTags.contains(where: {$0.tag == tag}) {
					newAvailableTags.append(tag)
				}
			}; availableTags = newAvailableTags
		}
	}
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	@State var tagRemovalAlertPresented: Bool = false
	@State var tagToBeRemoved: Tag?
	
	var body: some View {
		VStack {
			Text("Your tags")
				.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
				.onAppear {reDoAvailableTags()} //This is somehow more reliable than placing it on the ForEach...
			
			Text("Click tags to add to project")
				.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
				.foregroundStyle(primaryUIelement)
			
			Divider()
			
			ForEach(availableTags.sorted(by: {$0.timestamp < $1.timestamp})) { tag in
				TagView(tag) {
					withAnimation(standartAnimation) {
						let newTagReference = TagReference(tag, position: existingTags.count+1)
						existingTags.add(newTagReference)
						scrollPosition.scrollTo(id: newTagReference.id)
					}
				} removeAction: {
					tagRemovalAlertPresented = true
					tagToBeRemoved = tag
				}
			}
			
			//On changes of any array update the availableTags array
			.onChange(of: existingTags.count) { _,_ in
				reDoAvailableTags()}
			.onChange(of: globalUserSettings.tagCollection.count) { _,_ in
				reDoAvailableTags()}
			
			//Alert for removing tags
			.alert("Delete tag: \(tagToBeRemoved?.title ?? "")?", isPresented: $tagRemovalAlertPresented, actions: {
				Button(role: .destructive) {
					if let tag = tagToBeRemoved {
						safelyDeleteTag(tag)
					}
				} label: {Text("Delete")}
				Button(role: .cancel) {} label: {Text("Cancel")}
			})
			
			standartButton(systemName: "Create new Tag", color: primaryUIelement, frame: globalUserSettings.UISize.smallText, withBackground: true, containsText: true) {
				globalUserSettings.tagCollection.append(Tag())
			}
		}
		.padding(standartSheetPadding)
	}
}



#Preview {
	@Previewable @State var globalUserSettings = GlobalUserSettings()
	@Previewable @State var tagAddingWindowOpen: Bool = false
	@Previewable @State var tags: [TagReference] = []
	@Previewable @State var scrollPosition = ScrollPosition()
	
	HStack(spacing: standartPadding) {
		ForEach(tags.sorted(by: {$0.position < $1.position})) { tagReference in
			TagView(tagReference.tag) {} removeAction: {
				withAnimation(standartAnimation) {
					tags.remove(tagReference)
				}
			}
		}
		
		standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true) {
			tagAddingWindowOpen.toggle()
		}
		.popover(isPresented: $tagAddingWindowOpen) {
			TagSelector(opened: $tagAddingWindowOpen, existingTags: $tags, scrollPosition: $scrollPosition)
		}
	}
	.environment(globalUserSettings)
	.frame(width: 200)
	.padding(standartPadding)
}
