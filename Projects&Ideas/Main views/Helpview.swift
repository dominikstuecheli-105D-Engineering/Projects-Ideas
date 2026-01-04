//
//  Helpview.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 15.10.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



///NOTE: The "H" in front of the struct names stands for "HelpView", because "Text" itself is already used by SwiftUI.



enum HTextType {
	case title1
	case title2
	case title3
	case body
	case description
}

private struct HText: View {
	
	let hTextType: HTextType
	let text: String
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	init(_ hTextType: HTextType, _ text: String) {
		self.hTextType = hTextType
		self.text = text
	}
	
	var body: some View {
		switch hTextType {
		case .title1: Text(text)
				.font(.system(size: globalUserSettings.UISize.largeText, weight: .bold, design: .default))
			
		case .title2: Text(text)
				.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
			
		case .title3: Text(text)
				.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
			
		case .body: Text(text)
				.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
				.foregroundStyle(primaryUIelement)
			
		case .description: Text(text)
				.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
				.italic()
				.foregroundStyle(primaryUIelement)
		}
	}
}



private struct Paragraph<Content: View>: View {
	
	let titleHTextType: HTextType
	let title: String
	let content: Content
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	@State var expanded: Bool = false
	
	init(_ titleHTextType: HTextType, _ title: String, @ViewBuilder content: () -> Content) {
		self.titleHTextType = titleHTextType
		self.title = title
		self.content = content()
	}
	
	var body: some View {
		HStack(spacing: 0) {
			//Leading bar & arrow to indicate that it can be expanded
			ZStack {
				RoundedRectangle(cornerRadius: standartPadding)
					.frame(width: standartPadding*2)
					.foregroundStyle(expanded ? .blue.opacity(0.5) : .gray.opacity(0.2))
					.padding(.trailing, standartPadding)
				
				VStack {
					Image(systemName: "chevron.right")
						.resizable()
						.scaledToFit()
						.frame(width: standartPadding)
						.offset(x: -standartPadding/2)
						.rotationEffect(Angle(degrees: expanded ? 90 : 0), anchor: .leading)
						.padding(.top, standartPadding/3)
						.foregroundStyle(expanded ? .blue : primaryUIelement)
					
					Spacer(minLength: 0)
				}
			}
			
			//PARAGRAPH CONTENT
			
			VStack(alignment: .leading, spacing: 0) {
				
				//Title
				HStack { HText(titleHTextType, title); Spacer() }
				
				//Content
				if expanded { content .padding(.top, standartPadding) }
			}
		}
		.padding(standartPadding)
		.fixedSize(horizontal: false, vertical: true)
		
		.background(RoundedRectangle(cornerRadius: standartPadding*2)
			.foregroundStyle(.gray.opacity(expanded ? 0.12 : 0.05)))
		.overlay(RoundedRectangle(cornerRadius: standartPadding*2).stroke(.gray.opacity(0.1), lineWidth: 2).padding(1))
		
		.onTapGesture {
			withAnimation(standartAnimation) {
				expanded.toggle()
			}
		}
	}
}



//From here on its all the hardcoded HelpView
struct Helpview: View {
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	var body: some View {
		ScrollView {
			
			//HEADER&INTRODUCTION
			Paragraph(.title1, "The help menu") {
				HText(.body, "This documention aims to help new users find their way in Projects&Ideas. last updated 1. Jan 2026 for 1.0")
			}
			
			//TOOLBAR BUTTONS
			
			Paragraph(.title1, "Toolbar") {
				
				//Sidebar buttons
				HText(.title2, "Sidebar")
				
				HStack {
					Image(systemName: "document.badge.plus") .foregroundStyle(primaryUIelement)
					HText(.description, "Add a new Project, already preset with one Bucket")
				}
				
				HStack {
					Image(systemName: "tag") .foregroundStyle(primaryUIelement)
					HText(.description, "Whether or not to sort the Projects in the sidebar by their tags instead of their age")
				}
				
				//Accessibility buttons
				HText(.title2, "Accessibility")
					HStack {
						Image(systemName: "minus") .foregroundStyle(primaryUIelement)
						Text("20px") .foregroundStyle(Color.gray)
						Image(systemName: "plus") .foregroundStyle(primaryUIelement)
						
						HText(.body, "Size adjustment for all visual elements. This aims to help with difficulties when reading small text.")
					}
				
				//Projectview buttons
				HText(.title2, "in Project view")
				
				HStack {
					Image(systemName: "arrow.right.and.line.vertical.and.arrow.left") .foregroundStyle(primaryUIelement)
					Text("350px") .foregroundStyle(primaryUIelement)
					Image(systemName: "arrow.left.and.line.vertical.and.arrow.right") .foregroundStyle(primaryUIelement)
					
					HText(.description, "Width adjustment for Buckets. only accessible if \"Horizontal scroll view for Buckets\" is enabled.")
				}
				
				HStack {
					Image(systemName: "gearshape") .foregroundStyle(primaryUIelement)
					HText(.description, "Open the Project setting view, for further information on Project settings go to paragraph \"Project settings\" found under \"Editing a Project\"")
				}
				
				HStack {
					Image(systemName: "tray") .foregroundStyle(primaryUIelement)
					HText(.description, "Add another Bucket to current Project")
				}
			}
			
			//EDITING A PROJECT
			
			Paragraph(.title1, "Editing a Project") {
				Paragraph(.title2, "General text editing") {
					HText(.body, "Generally, all text seen in the Project view is editable. Therefore, to edit Bucket titles, Idea titles or descriptions, simply click on the respective text you want to edit.")
				}
				
				//Bucket buttons
				Paragraph(.title2, "Buttons on Buckets") {
					
					HText(.body, "Not all buttons are immediately accessible: They can be expanded with the following button: ")
					
					HStack {
						standartButton(systemName: "gearshape", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Expand the buttons")
						
					}
					
					Divider()
					
					HStack {
						standartButton(systemName: "arrow.left", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Move Bucket 1 position to the left")
					}
					
					HStack {
						standartButton(systemName: "arrow.right", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Move Bucket 1 position to the right")
					}
					
					HStack {
						standartButton(systemName: "plus", color: .blue, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Add another Idea to the bottom of the Bucket")
					}
					
					HStack {
						standartButton(systemName: "document.on.clipboard", color: .blue, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Insert Idea from clipboard to the top of the Bucket: only appears if the clipboard is not empty.")
					}
					
					HStack {
						standartButton(systemName: "trash", color: .red, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Delete this Bucket")
					}
					
					HStack {
						standartButton(systemName: "paintpalette", color: .purple, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Customize the Bucket color")
					}
				}
				
				//Idea buttons
				Paragraph(.title2, "Buttons on Ideas") {
					HStack {
						standartButton(systemName: "document.on.document", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Copy this Idea to clipboard")
					}
					
					HStack {
						standartButton(systemName: "trash", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Delete this Idea")
					}
					
					HStack {
						standartButton(systemName: "arrowshape.up", color: primaryUIelement, frame: globalUserSettings.UISize.small) {}
						HText(.description, "Minimize the Idea window")
					}
				}
				
				//Idea Extensions
				Paragraph(.title2, "Idea Extensions") {
					HText(.body, "Idea Extensions allow you to describe or plan your ideas even better. They can be added to your idea with the \"+\" Button on the bottom of each Idea:")
					
					IdeaExtensionSelector(idea: Idea(title: "", desc: "", position: 1))
					
					HText(.title3, "Checklists:")
					HText(.body, "The Checklist extension allows a checkable list of text items. checked-of items go to the bottom of the list. To create a new item, press enter while editing another item. To delete an item, delete all text within it and press delete.")
					
					HText(.title3, "Image Galleries:")
					HText(.body, "The Image gallery extension allows saving Image files within an Idea. Drag&Drop an image file into the extension to save it. Reorder the images by Drag&Drop. Images are also exportable by Drag&Drop.")
				}
				
				//Drag&Drop of Ideas
				Paragraph(.title2, "Idea movement through Drag&Drop") {
					HText(.body, "Ideas can be reordered or moved between buckets by dragging&dropping. To drag an Idea, it is best to drag it by the \"dragging handle\", shown below, located on the leading side of the Idea. If now hovered over a space between two Ideas or either on top or bottom of the Idea list, a blue bar appears to show where the Idea would be inserted if dropped.")
					
					HStack {
						//leading drag&drop handle
						DragAndDropHandle() .frame(height: globalUserSettings.UISize.large)
						HText(.description, "The dragging handle, located on the leading side of each Idea")
					}
				}
				
				//Copy&Paste of Ideas
				Paragraph(.title2, "Idea movement and duplication through the clipboard") {
					HText(.body, "Ideas can be copied and duplicated using the clipboard function. Clicking the \"Copy to clipboard\" Button on the Idea sets the clipboard to this Idea. Clicking the \"Insert from clipboard\" Button on the bucket inserts the Idea in the clipboard to the top of the bucket and clears the clipboard. The clipboard is not Project-specific, which means Ideas can be moved between Projects by copying&pasting.")
				}
				
				//Project settings
				Paragraph(.title2, "Project settings") {
					HText(.body, "In similar fashion to Buckets and Ideas, the Project title is editable by clicking on it in the Project settings window. Below is a list of all options that can be found in the Project settings.")
					
					HText(.title3, "\"Require confirmation to delete Ideas\"")
					HText(.body, "Whether or not the programm should ask you if you really want to delete an Idea. Intented as a safety feature.")
					
					HText(.title3, "\"Horizontal scroll view for Buckets\"")
					HText(.body, "Normally all Buckets are distributed evenly across the width of the screen. This can become quite cluttered with a large amount of Buckets. Therefore, this option allows you to use a horizontal scroll view for the Buckets. You will not be able to see all Buckets at once anymore, but all Buckets will have a fixed width and Ideas can be looked at and edited in a more easy-on-the-eyes way.")
										
					HText(.title3, "\"Check-off button for Ideas\"")
					HText(.body, "With this setting enabled, every Idea gets a check-off button, identifiable by the checkmark icon. This button automatically moves the idea to the last Bucket and minimizes it. It is meant to be used in a context where the last Bucket is used as a Bucket in which all \"finished\" Ideas are stored.")
				}
			}
			
			//TAGS
			
			Paragraph(.title1, "Tags") {
				HStack {
					TagView(Tag("Red tag", colorIdentifier: 2), addAction: {}, removeAction: {})
					TagView(Tag("Orange tag", colorIdentifier: 3), addAction: {}, removeAction: {})
					TagView(Tag("Blue tag", colorIdentifier: 5), addAction: {}, removeAction: {})
				}
				
				HText(.body, "With tags, projects can be marked or categorised. Your tag list can be opened by clicking the \"+\" button in a projects settings:")
				
				HStack {
					standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.small, withBackground: true) {}
					
					HText(.description, "Open your tag list to add tags to the project")
				}
				
				HText(.body, "A tag can then be added to a project by clicking its label:")
				
				HStack {
					//Dummy tag view, compacted view code
					HStack(spacing: 0) {
						HStack(spacing: 3) {
							ZStack {
								Circle() .foregroundStyle(.black.opacity(0.5))
								Circle() .foregroundStyle(.gray) .frame(width: globalUserSettings.UISize.small - standartPadding*2, height: globalUserSettings.UISize.small - standartPadding*2)
							}
							.frame(width: globalUserSettings.UISize.small - standartPadding, height: globalUserSettings.UISize.small - standartPadding) .padding(.leading, standartPadding/2)
							
							Text("Red tag") .font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
						}
						.padding([.leading, .trailing], 3) .frame(height: globalUserSettings.UISize.large)
						.background(.red)
						
						Group {
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
							
							Group {
								Image(systemName: "trash") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
							}
							.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
							.background(.red)
							
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
							
							Group {
								Image(systemName: "gearshape") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
							}
							.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
							.background(.red)
						} .opacity(0.4)
					} .clipShape(RoundedRectangle(cornerRadius: standartPadding))
					
					HText(.description, "Add this tag to the project")
				}
				
				HText(.body, "Note that a tag cannot appear in the opened projects tag list and your tag list simultaniously.")
				HText(.body, "Tags can be configured by clicking their \"settings\" button:")
				
				HStack {
					//Dummy tag view, compacted view code
					HStack(spacing: 0) {
						Group {
							HStack(spacing: 3) {
								ZStack {
									Circle() .foregroundStyle(.black.opacity(0.5))
									Circle() .foregroundStyle(.gray) .frame(width: globalUserSettings.UISize.small - standartPadding*2, height: globalUserSettings.UISize.small - standartPadding*2)
								}
								.frame(width: globalUserSettings.UISize.small - standartPadding, height: globalUserSettings.UISize.small - standartPadding) .padding(.leading, standartPadding/2)
								
								Text("Red tag") .font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
							}
							.padding([.leading, .trailing], 3) .frame(height: globalUserSettings.UISize.large)
							.background(.red)
							
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
							
							Group {
								Image(systemName: "trash") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
							}
							.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
							.background(.red)
							
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
						} .opacity(0.4)
						
						Group {
							Image(systemName: "gearshape") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
						}
						.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
						.background(.red)
					} .clipShape(RoundedRectangle(cornerRadius: standartPadding))
					
					HText(.description, "Open this tags settings")
				}
				
				HText(.body, "When clicking a tags \"Delete\" button, it is either removed from the project (if it was in the projects tag list) or deleted completely.")
				
				HStack {
					//Dummy tag view, compacted view code
					HStack(spacing: 0) {
						Group {
							HStack(spacing: 3) {
								ZStack {
									Circle() .foregroundStyle(.black.opacity(0.5))
									Circle() .foregroundStyle(.gray) .frame(width: globalUserSettings.UISize.small - standartPadding*2, height: globalUserSettings.UISize.small - standartPadding*2)
								}
								.frame(width: globalUserSettings.UISize.small - standartPadding, height: globalUserSettings.UISize.small - standartPadding) .padding(.leading, standartPadding/2)
								
								Text("Red tag") .font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
							}
							.padding([.leading, .trailing], 3) .frame(height: globalUserSettings.UISize.large)
							.background(.red)
							
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
						} .opacity(0.4)
						
						Group {
							Image(systemName: "trash") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
						}
						.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
						.background(.red)
						
						Group {
							Divider() .frame(height: globalUserSettings.UISize.large) .background(.red)
							
							Group {
								Image(systemName: "gearshape") .resizable() .scaledToFit() .bold() .frame(height: globalUserSettings.UISize.small*0.75)
							}
							.frame(height: globalUserSettings.UISize.large) .padding([.leading, .trailing], 3)
							.background(.red)
						} .opacity(0.4)
					} .clipShape(RoundedRectangle(cornerRadius: standartPadding))
					
					HText(.description, "Remove this tag from a project or delete it completely")
				}
			}
			
			//NOTIFICATIONS
			
			Paragraph(.title1, "Notifications") {
				HText(.body, "Notifications appear at the bottom of the screen to alert you of important things or changes. They will disappear automatically after a certain amount of time. They are seperated into 3 categories to underline their meaning:")
				
				VStack(alignment: .leading, spacing: 0) {
					Button {
						withAnimation(standartAnimation) {
							customNotificationCentre.shared.new("Easter egg!")
						}
					} label: {
						NotificationView(notification: customNotification(title: "This is a standart notification: Not especially important", duration: 1, level: .standart))
					}
					.buttonStyle(.plain)
					
					Button {
						withAnimation(standartAnimation) {
							customNotificationCentre.shared.new("Very important easter egg.", level: .important)
						}
					} label: {
						NotificationView(notification: customNotification(title: "This is an important notification: Please read!", duration: 1, level: .important))
					}
					.buttonStyle(.plain)
					
					Button {
						withAnimation(standartAnimation) {
							customNotificationCentre.shared.new("Deleted easter egg", level: .destructive)
						}
					} label: {
						NotificationView(notification: customNotification(title: "This is a notification about a destructive event: You have just deleted something", duration: 1, level: .destructive))
					}
					.buttonStyle(.plain)
				}
			}
		}
		.contentMargins(standartPadding)
		.navigationTitle("Help menu")
		.toolbarTitleDisplayMode(.inline)
	}
}



#Preview {
	Helpview()
		.environment(GlobalUserSettings())
		#if os(macOS)
		.frame(width: 500, height: 550)
		#endif
}
