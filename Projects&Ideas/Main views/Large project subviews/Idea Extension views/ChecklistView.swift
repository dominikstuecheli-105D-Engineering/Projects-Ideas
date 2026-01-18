//
//  ChecklistView.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.09.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



private struct ChecklistItemView: View {
	
	@Bindable var item: ChecklistItem
	@FocusState private var focusedOn: UUID?
	
	//Making this a closure is easier because it requires access to the item arrays which are in the ChecklistView.
	var executeAtOnChange: (_ oldValue: String, _ newValue: String) -> String
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	var body: some View {
		HStack(spacing: 3) {
			
			//CHECKMARK
			Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
				.resizable() .scaledToFit()
				.foregroundStyle(item.checked ? .green.opacity(0.8) : primaryUIelement)
				.frame(height: globalUserSettings.UISize.small)
			
				.onTapGesture {
					withAnimation(standartAnimation) {
						item.checked.toggle()
					}
				}
				.customHoverEffect()
			
			//STRING
			customFastTextField(placeHolder: "", string: $item.title, useActualTextField: true) { oldValue, newValue in
				return executeAtOnChange(oldValue, newValue)
			}
			.frame(minHeight: globalUserSettings.UISize.small)
			.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
			.foregroundStyle(primaryUIelement)
		}
	}
}



struct IdeaExtensionChecklistView: View {
	
	@Bindable var checklist: Checklist
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	@FocusState var focus: UUID?

	var body: some View {
		
		Divider() .padding(.top, 3)
		Spacer(minLength: 3) .frame(height: 3)
		
		DragAndDropList(checklist.items) { item in
			
			ChecklistItemView(item: item) { oldValue, newValue in
				
				var returnValue: String = newValue
				
				//Making sure there is always the safety space at the beginning
				if newValue.first != " " {
					returnValue = " " + newValue
				}
				
				//If trying to delete the ChecklistItem
				if newValue == "" && checklist.items.count != 1 {
					withAnimation(standartAnimation) { checklist.items.remove(item) }
					
					//Focus on the next best line
					if item.position != 1 {
						focus = checklist.items.first(where: {$0.position == item.position-1})?.id
					} else {
						focus = checklist.items.first(where: {$0.position == 1})?.id
					}
				}
				
				return returnValue
			}
			
			//If pressed enter make new ChecklistItem
			.onSubmit {
				withAnimation(standartAnimation) {
					let newItem = ChecklistItem(" ", position: item.position+1)
					newItem.checked = item.checked
					
					checklist.items.add(newItem)
					focus = checklist.items[checklist.items.count-1].id
				}
			}
			
			//Move item to the end if checked off
			.onChange(of: item.checked) { oldvalue, newValue in
				if newValue == true { withAnimation(standartAnimation) {
					checklist.items.move(item, toPos: checklist.items.count+1)
				} }
			}
			
			//Focusstate
			.focused($focus, equals: item.id)
			
			//Drag&Drop functionality
			//Here, the localPayload is not the checklistItem itself but the checklist extension it is contained in. this makes it easier to remove when being moved to another extension instance, as it does not need to be searched for first.
			.localTransferable(ChecklistItemTransferable(from: item), localPayload: checklist) {
				HStack(spacing: 3) {
					Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
						.resizable() .scaledToFit()
						.foregroundStyle(item.checked ? .green.opacity(0.8) : primaryUIelement)
						.frame(height: globalUserSettings.UISize.small)
					
					Text(item.title)
						.frame(minHeight: globalUserSettings.UISize.small)
						.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
						.foregroundStyle(primaryUIelement)
				}
			}
			
		} onDrop: { transferable, position in
			let _: ChecklistItemTransferable = transferable //The compiler needs to know what type the transferable has, even tho it does not really have a function
			let localPayload: Checklist? = getLocalDragAndDropPayload()
			
			withAnimation(standartAnimation) {
				if localPayload == checklist {
					//If moved inside of this checklist extension
					if let first = checklist.items.first(where: {$0.id == transferable.id}) {
						checklist.items.move(first, toPos: position)
					}
				} else {
					//If moved between two different checklist extensions
					checklist.items.add(ChecklistItem(fromTransferable: transferable, newPosition: position))
					if let first = localPayload?.items.first(where: {$0.id == transferable.id}) {
						localPayload!.items.remove(first)
					}
				}
			}
			return true
		}
		
		//Making sure there is always one element in the list
		.onChange(of: checklist.items.count) { old, new in
			if new == 0 { withAnimation(standartAnimation) {
				checklist.items.add(ChecklistItem(" ", position: 1))
			} }
		}
	}
}



#if os(macOS)
#Preview {
	@Previewable @State var idea: Idea = Idea(title: "Idea 1", desc: "", position: 1, extensions: [
		IdeaExtension(.checklist, content: Checklist(), position: 1),
		IdeaExtension(.imageCatalogue, content: ImageCatalogue(images: [
			
			ImageCatalogueItem(NSImage(named: "A350")!.tiffRepresentation!, position: 1),
			ImageCatalogueItem(NSImage(named: "A350")!.tiffRepresentation!, position: 2),
			ImageCatalogueItem(NSImage(named: "A350")!.tiffRepresentation!, position: 3)
		]), position: 2)
	])
	
	ZStack {
		Rectangle()
			.frame(width: 350, height: 350)
			.foregroundStyle(Color.clear)
		
		IdeaExtensionView(idea: idea, ideaExtension: idea.extensions[0])
			.padding(standartPadding)
			.frame(width: 350)
		
			.environment(Project())
			.environment(GlobalUserSettings())
	}
}
#endif
