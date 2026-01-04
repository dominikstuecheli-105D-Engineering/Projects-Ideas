//
//  SideBarTitle.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 12.12.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



//The view that is listed for every project in the sidebar
struct SideBarTitle: View {
	
	var project: Project
	var primaryTag: Tag? //Which tag should be listed as the leftmost one if given
	
	@Environment(\.colorScheme) var colorScheme
	
	@State private var tagDetail: Tag? = nil
	@State private var closeTagDetail: DispatchWorkItem?
	
	private func scheduleTagDetailClose() {
		closeTagDetail?.cancel()
		closeTagDetail = DispatchWorkItem {self.tagDetail = nil}
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: closeTagDetail!)
	}
	
    var body: some View {
		HStack {
			
			//Project title
			Text(project.title) .lineLimit(1)
			Spacer()
			
			//Small coloured circles to show what tags the project has
			HStack {
				ForEach(project.tags.sorted(by: {$0.position < $1.position || $0.tag == primaryTag})) { tagReference in
					Circle() .foregroundStyle(getColor(tagReference.tag.colorIdentifier, colorScheme, respectOpacity: false))
						.frame(idealHeight: 0)
					///NOTE: The .onHover does not trigger when the cursor moves away from the view on iOS which is why disabled. iOS is also really buggy with the colors which are blue the first half-second before turning the right color. I am sure this is a SwiftUI bug and not mine.
						#if os(macOS)
						.onHover { hover in
							if hover {
								closeTagDetail?.cancel()
								tagDetail = tagReference.tag
							} else {
								scheduleTagDetailClose()
							}
						}
						#endif
				}
				.padding([.top, .bottom], 3)
			}
			.popover(isPresented: Binding(get: {tagDetail != nil},
				set: {bool in if !bool {tagDetail = nil; closeTagDetail?.cancel()}})) {
				TagView(tagDetail!) {} removeAction: {
					if let tagReference = project.tags.first(where: {$0.tag == tagDetail}) {
						withAnimation(standartAnimation) {project.tags.remove(tagReference)}
					}
				}
				#if os(macOS)
				.onHover { hover in
					if hover {closeTagDetail?.cancel()}
				}
				#endif
				#if os(iOS)
				.padding(standartSheetPadding)
				#endif
			}
		}
		.id(project.id)
    }
}

#Preview {
	SideBarTitle(project: Project(tags: [TagReference(Tag())]))
		.frame(width: 150, height: 20)
		.padding()
		.border(.gray)
		.padding()
	
		.environment(GlobalUserSettings())
}
