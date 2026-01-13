//
//  Projectview.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 02.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//



import SwiftUI



///NOTE: This file is very large and contains a lot of stuff. However, it is a lot easier if the thing you are testing can be previewed in the same file; Everything here is part of the main Project View.



//This View is not really the View of the IdeaExtensions: They are handled seperately. This View is only the frame around it as well as the top bar with the extension title and the delete and minimize buttons.
struct IdeaExtensionView: View {
    
    @Bindable var idea: Idea //Needs access to delete itself
    @Bindable var ideaExtension: IdeaExtension
    
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(ProjectSettings.self) var projectSettings: ProjectSettings
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
				
                //TITLE
                Spacer(minLength: 3)
				customFastTextField(placeHolder: "Extension title", string: $ideaExtension.title)
					.frame(minHeight: globalUserSettings.UISize.small)
                
                //TextEditor
                    //.font(.title3)
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
                
                //BUTTONS
                HStack(spacing: standartPadding) {
                    
                    //DELETE
					standartButton(systemName: "trash", color: primaryUIelement, frame: globalUserSettings.UISize.small, withAlert: projectSettings.ideaDeletionRequiresConfirmation ? true : false, alertTitle: "Delete idea Extension: \(ideaExtension.title)?") {
                        withAnimation(standartAnimation) {
                            idea.extensions.remove(ideaExtension)
                            
                            //Notification
							customNotificationCentre.shared.new("Deleted idea Extension: \(ideaExtension.title)", level: .destructive)
                        }
                    }
                    
                    //MINIMIZE
                    standartButton(systemName: "arrowshape.down", color: primaryUIelement, frame: globalUserSettings.UISize.small, animationValue: ideaExtension.minimized, animationStartAngle: -180, animationEndAngle: 0) {
                        withAnimation(standartAnimation) {
                            ideaExtension.minimized.toggle()
                        }
                    }
                }
				//This positions the buttons in the top right corner
				.frame(maxHeight: .infinity, alignment: .top)
            }
			.fixedSize(horizontal: false, vertical: true)
            
            //THE ACTUAL EXTENSION VIEW
            if !ideaExtension.minimized {
				switch ideaExtension.type {
				case .checklist: IdeaExtensionChecklistView(checklist: ideaExtension.checklistContent!)
                case .imageCatalogue: IdeaExtensionImageCatalogueView(imageCatalogue: ideaExtension.imageCatalogueContent!)
                }
            }
            
        }
        //Frame for everything
        .padding(standartPadding)
        .overlay(RoundedRectangle(cornerRadius: standartPadding*2-2).stroke(.gray.opacity(0.1), lineWidth: 2).padding(1))
    }
}



//The Selector with which new IdeaExtension can be added
struct IdeaExtensionSelector: View {
    
    @Bindable var idea: Idea
    @State var extended: Bool = false
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
    
    var body: some View {
        
        VStack(spacing: 3) {
            
            if extended {
                
				//Close menu button
				Button {
					withAnimation(standartAnimation) {
						extended = false
					}
				}   label: {
					HStack {
						Image(systemName: "minus")
							.resizable()
							.scaledToFit()
							.frame(width: globalUserSettings.UISize.smallText*0.85)
							.foregroundStyle(Color.red)
						
						Spacer()
						
						Text("Close")
							.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
							.foregroundStyle(Color.red)
						
						Spacer()
					}
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
				.customHoverEffect()
				
				//List all options
                ForEach(IdeaExtensionType.allCases, id:\.self) { type in
					Divider()
					
                    Button {
                        //add new Idea extension
                        withAnimation(standartAnimation) {
                            switch type {
                                
							case .checklist: idea.extensions.add(IdeaExtension(.checklist, content: Checklist([ChecklistItem(" ", position: 1)]), position: idea.extensions.count+1))
                                
							case .imageCatalogue: idea.extensions.add(IdeaExtension(.imageCatalogue, content: ImageCatalogue(), position: idea.extensions.count+1))
                            }
                            
                            extended = false
                        }
                    } label: {
                        
                        HStack {
                            Image(systemName: "plus")
								.resizable() .scaledToFit()
								.frame(height: globalUserSettings.UISize.smallText*0.85)
								.foregroundStyle(primaryUIelement)
                            Spacer()
                            Text(getIdeaExtensionTitle(type: type))
								.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        
                    }
					.buttonStyle(.plain)
					.customHoverEffect()
                }
                
            } else {
                
                //Open menu button
                Button {
                    withAnimation(standartAnimation) {
                        extended = true
                    }
                }   label: {
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
							.resizable()
							.scaledToFit()
							.frame(height: globalUserSettings.UISize.small*0.6)
                            .foregroundStyle(Color.gray.opacity(0.25))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
				.buttonStyle(.plain)
				.customHoverEffect()
            }
        }
        //Frame for everything
        .padding(standartPadding)
        //.background(RoundedRectangle(cornerRadius: standartPadding*2)
        //.foregroundStyle(Color.gray.opacity(0.1)))
        
        .overlay(RoundedRectangle(cornerRadius: standartPadding*2-2).stroke(.gray.opacity(0.1), lineWidth: 2).padding(1))
    }
}



struct Ideaview: View {
    
    @Bindable var idea: Idea
    @Bindable var bucket: Bucket //Needs access to delete itself
    @Binding var clipBoard: Idea?
    
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(ProjectSettings.self) var projectSettings: ProjectSettings
	@Environment(Project.self) var project: Project
	
	@Environment(\.colorScheme) var colorScheme
	
	@State var shiftPressed = false
    
	var body: some View {
		HStack {
			
			//leading drag&drop handle
			DragAndDropHandle()
			
			VStack(spacing: 0) {
				
				HStack {
					
					//TITLE
					Spacer(minLength: 3)
					customFastTextField(placeHolder: "Idea title", string: $idea.title)
					
					//TextEditor
						.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
					
					//FOR DEBUG
					if debugMode {
						Text(String("pos \(idea.position)"))
							.foregroundStyle(Color.gray)
					}
					
					//BUTTONS
					HStack(spacing: 0) {
						
						//CHECK OFF IDEA
						if projectSettings.useCheckOffIdeaButton {
							standartButton(systemName: "checkmark", color: project.getLastBucketColor(colorScheme), frame: globalUserSettings.UISize.small, withBackground: true) {
								withAnimation(standartAnimation) {
									if !shiftPressed {
										project.checkOffIdea(idea)
									} else {
										bucket.changeForAll(.checkOff, project: project)
									}
								}
							}
							.padding(.trailing, standartPadding/2)
						}
						
						//COPY TO CLIPBOARD
						standartButton(systemName: "document.on.document", color: primaryUIelement, frame: globalUserSettings.UISize.small) {
							withAnimation(standartAnimation) {
								
								//Create a new Instance of the idea so that the Metadata, especially the id, is renewed
								clipBoard = Idea(copy: idea)
								
								//Notification
								customNotificationCentre.shared.new("Copied Idea: \(idea.title) to clipboard")
							}
						}
						
						//DELETE
						standartButton(systemName: "trash", color: primaryUIelement, frame: globalUserSettings.UISize.small, withAlert: projectSettings.ideaDeletionRequiresConfirmation ? true : false, alertTitle: "Delete Idea: \(idea.title)?") {
							withAnimation(standartAnimation) {
								bucket.ideas.remove(idea)
								
								//Notification
								customNotificationCentre.shared.new("Deleted Idea: \(idea.title)", level: .destructive)
							}
						}
						
						//MINIMIZE
						standartButton(systemName: "arrowshape.down", color: primaryUIelement, frame: globalUserSettings.UISize.small, animationValue: idea.minimized, animationStartAngle: -180, animationEndAngle: 0) {
							withAnimation(standartAnimation) {
								if !shiftPressed {
									idea.minimized.toggle()
								} else {
									bucket.changeForAll(.minimized, value: !idea.minimized)
								}
							}
						}
					}
					//This positions the buttons in the top right corner
					.frame(maxHeight: .infinity, alignment: .top)
				}
				
				//Detect when shift is pressed
				#if os(macOS)
				.onAppear {
					NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
						if event.modifierFlags.contains(.shift) {
							shiftPressed = true
						} else {
							shiftPressed = false
						}
						return event
					}
				}
				#endif
				
				if idea.minimized == false {
					VStack {
						
						//DESCRIPTION
						HStack {
							Spacer(minLength: 3)
							customFastTextField(placeHolder: "Description", string: $idea.desc)
								.frame(minHeight: globalUserSettings.UISize.smallText)
							
							//TextEditor
								.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
								.foregroundStyle(primaryUIelement)
						}
						
						//EXTENSIONS
						HStack {
							Spacer(minLength: 3)
							
							VStack(spacing: standartPadding) {
								ForEach(idea.extensions.sorted {$0.position < $1.position}) { ideaExtension in
									IdeaExtensionView(idea: idea, ideaExtension: ideaExtension)
								}
								
								IdeaExtensionSelector(idea: idea)
							}
						}
					}
				}
			}
			//This fixes a lot of "phantom" padding issues, this is on the Idea VStack
			.fixedSize(horizontal: false, vertical: true)
		}
		//Frame for everything
		.padding(standartPadding)
		.background(RoundedRectangle(cornerRadius: standartPadding*2)
			.foregroundStyle(getColor(bucket.colorIdentifier, colorScheme, respectOpacity: false).opacity(0.1)))
		
		//Drag&Drop functionality
		.localTransferable(IdeaTransferable(idea: idea), localPayload: idea) {
			ZStack {
				RoundedRectangle(cornerRadius: standartPadding*2)
					.foregroundStyle(.gray.opacity(0.1))
				
				HStack {
					DragAndDropHandle()
						.padding([.leading, .top, .bottom], standartPadding)
					
					Text(idea.title)
						.padding(.leading, 3)
						.font(.title2)
						.foregroundStyle(primaryUIelement)
					
					Spacer()
				}
			}
		}
	}
}



struct Bucketview: View {
    
    @Bindable var bucket: Bucket
    @Binding var clipBoard: Idea?
    
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(Project.self) var project: Project
	@Environment(\.colorScheme) var colorScheme
	
    @State var buttonsExpanded = false
    @State var colorPickerExpanded = false
	@State var scrollPosition: ScrollPosition = ScrollPosition(x: 0)
	
    var body: some View {
		VStack(spacing: 0) {
			HStack {
				if !buttonsExpanded {
					
					//TITLE
					Spacer(minLength: 3)
					customFastTextField(placeHolder: "Bucket title", string: $bucket.title)
					//TextEditor
						.font(.system(size: globalUserSettings.UISize.largeText, weight: .bold, design: .default))
					
					Spacer()
					
					//FOR DEBUG
					if debugMode {
						Text(String("pos \(bucket.position)"))
							.foregroundStyle(Color.gray)
					}
				}
				
				//BUTTONS
				HStack(spacing: 0) {
					
					//EXPANDABLE BUTTONS LEFT
					if buttonsExpanded {
						Spacer(minLength: 0)
						
						HStack(spacing: 0) {
							if bucket.position > 1 {
								//MOVE BUCKET LEFT
								standartButton(systemName: "arrow.left", color: primaryUIelement, frame: globalUserSettings.UISize.large) {
									withAnimation(standartAnimation) {
										project.moveBucket(bucket.position, direction: .left)
									}
								}
							}
							
							if bucket.position < project.buckets.count {
								//MOVE BUCKET RIGHT
								standartButton(systemName: "arrow.right", color: primaryUIelement, frame: globalUserSettings.UISize.large) {
									withAnimation(standartAnimation) {
										project.moveBucket(bucket.position, direction: .right)
									}
								}
							}
						}
						.background {
							RoundedRectangle(cornerRadius: standartPadding)
								.foregroundStyle(.gray.opacity(0.25))
						}
						.padding(.trailing, standartPadding/2)
					}
					
					//ADD NEW IDEA
					standartButton(systemName: "plus", color: clipBoard != nil ? .blue.opacity(0.5) : .blue, frame: globalUserSettings.UISize.large) {
						let newIdea = Idea(position: bucket.ideas.count+1)
						withAnimation(standartAnimation) {
							bucket.ideas.add(newIdea)
							scrollPosition.scrollTo(id: newIdea.id)
						}
					}
					
					//PASTE FROM CLIPBOARD
					if clipBoard != nil {
						standartButton(systemName: "document.on.clipboard", color: .blue, frame: globalUserSettings.UISize.large) {
							withAnimation(standartAnimation) {
								clipBoard?.position = 1
								bucket.ideas.add(clipBoard!)
								
								//Notification
								customNotificationCentre.shared.new("Pasted Idea: \(clipBoard?.title ?? "N/A") from clipboard to \(bucket.title)")
								
								clipBoard = nil
							}
						}
					}
					
					//EXPANDABLE BUTTONS RIGHT
					if buttonsExpanded {
						
						//DELETE BUCKET
						standartButton(systemName: "trash", color: .red, frame: globalUserSettings.UISize.large, withAlert: true, alertTitle: "Delete \(bucket.title)?") {
							withAnimation(standartAnimation) {
								project.buckets.remove(bucket)
								
								//Notification
								customNotificationCentre.shared.new("Deleted Bucket: \(bucket.title)", level: .destructive)
							}
						}
						
						//CUSTOMIZE COLOR
						standartButton(systemName: "paintpalette", color: .purple, frame: globalUserSettings.UISize.large) {
							withAnimation(standartAnimation) {
								colorPickerExpanded.toggle()
							}
						}
						
						.popover(isPresented: $colorPickerExpanded) {
							customColorPicker(selectedColorIdentifier: $bucket.colorIdentifier)
								.padding(standartSheetPadding)
						}
					}
					
					//EXPAND BUTTONS
					standartButton(systemName: "gearshape", color: primaryUIelement, frame: globalUserSettings.UISize.large, animationValue: buttonsExpanded, animationStartAngle: 180) {
						withAnimation(standartAnimation) {
							buttonsExpanded.toggle()
							colorPickerExpanded = false
						}
					}
				}
				//This positions the buttons in the top right corner
				.frame(maxHeight: .infinity, alignment: .top)
			}
			.padding(standartPadding)
			.background {
				RoundedRectangle(cornerRadius: standartPadding*2)
					.foregroundStyle(getColor(bucket.colorIdentifier, colorScheme, respectOpacity: false).opacity(0.1))
			}
			//Makes the top bar take up less than half of the VStack, just as much space as needed
			.fixedSize(horizontal: false, vertical: true)
			.padding([.leading, .top, .trailing], standartPadding)
			
			//LIST ALL IDEAS
			ScrollView(Axis.Set.vertical, showsIndicators: false) {
				
				DragAndDropList(bucket.ideas) { idea in
					AnyView(Ideaview(idea: idea, bucket: bucket, clipBoard: $clipBoard))
						.renderAllowance(id: idea.id)
				} onDrop: { transferable, position in
					let _: IdeaTransferable = transferable //The compiler needs to know what type the transferable has, even tho it does not really have a function
					var returnValue = false
					withAnimation(standartAnimation) {
						if let localPayload: Idea = getLocalDragAndDropPayload() {
							project.moveIdea(localPayload, toBucket: bucket, toPosition: position)
							scrollPosition.scrollTo(id: localPayload.id)
							returnValue = true
						} else {returnValue = false}
					}; return returnValue
				}
				
				//Spacer at the bottom so it is possible to scroll past the last idea
				Spacer() .frame(height: 500)
			}
			.scrollPosition($scrollPosition)
			
			//Mask for the nice fade effects at the top and bottom
			.mask(
				GeometryReader { geometry in
					LinearGradient(gradient: Gradient(stops: [
							.init(color: .clear, location: 0),
							.init(color: .black, location: standartPadding / geometry.size.height),
							.init(color: .black, location: 1 - (standartPadding*3 / geometry.size.height)),
							.init(color: .clear, location: 1),
					]),
						startPoint: .top, endPoint: .bottom)
				}
			)
			
			.padding([.leading, .trailing], standartPadding)
		}
		//Frame for everything
		.frame(minWidth: 200)
		//if using horizontal scroll view for buckets, fix the width
		.frame(width: project.settings.useScrollViewForBuckets ? CGFloat(project.settings.scrollViewBucketWidth) : nil)
		
		//.containerRelativeFrame(.horizontal, count: 3, spacing: standartPadding)
		/// -> Maybe add some time later, would be an alternative to the fixed pixel width
		
		.background(bucket.getSelfColor(colorScheme))
		
        .clipShape(RoundedRectangle(cornerRadius: standartPadding*3))
    }
}



struct Projectview: View {
    
    @Bindable var project: Project
    @Binding var clipBoard: Idea?
	let scheduleViewReload: () -> Void //If the debugMode value changes a total view reload is required which is only possible in ContentView which is why it needs to be passed down here
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
    
    @State var localSettingsOpened = false
	@State var devSettingsOpened = false
	@State var optionKeyPressed = false
	
	@State var scrollPosition: ScrollPosition = ScrollPosition(y: 0)
    
    var body: some View {
        //Group so that the toolbar works
        Group {
			if project.settings.useScrollViewForBuckets {
				
				//If scrollview is used
				ScrollView(Axis.Set.horizontal, showsIndicators: false) {
					HStack(spacing: standartPadding) {
						ForEach(project.buckets.sorted {$0.position < $1.position}) { bucket in
							Bucketview(bucket: bucket, clipBoard: $clipBoard)
								.renderAllowance(id: bucket.id, placeholder: true, width: CGFloat(project.settings.scrollViewBucketWidth), cornerRadius: standartPadding*3)
						}
					}
				} .scrollPosition($scrollPosition)
				.contentMargins(standartPadding)
				//Should solve weird SwiftUI Hangs?
				.scrollDismissesKeyboard(.interactively)
				
			} else {
                
                //If normal view
                HStack(spacing: standartPadding) {
                    ForEach(project.buckets.sorted {$0.position < $1.position}) { bucket in
						Bucketview(bucket: bucket, clipBoard: $clipBoard)
							.renderAllowance(id: bucket.id, placeholder: true, cornerRadius: standartPadding*3)
                    }
                }
				.padding(standartPadding)
            }
        }
		
		//Make the project settings and the project itself accessible to all subviews
		.environment(project.settings)
		.environment(project)
		
        //Toolbar
        .toolbar {
			//If scroll view is enabled, show the buttons to edit bucket width
			if project.settings.useScrollViewForBuckets {
				ToolbarItemGroup {
					customToolbarDivider()
					
					//Smaller
					Button {
						if project.settings.scrollViewBucketWidth > 200 {
							project.settings.scrollViewBucketWidth -= 10
						}
					} label: {
						Label("Smaller", systemImage: "arrow.right.and.line.vertical.and.arrow.left")
					}
					
					//Size
					Text("\(project.settings.scrollViewBucketWidth)px")
						.foregroundStyle(toolbarItemColor())
						.fixedSize(horizontal: true, vertical: false) //needed for proper function on iOS 26+
					
					//Larger
					Button {
						project.settings.scrollViewBucketWidth += 10
					} label: {
						Label("Wider", systemImage: "arrow.left.and.line.vertical.and.arrow.right")
					}
				}
			}
			
			ToolbarItemGroup {
				customToolbarDivider()
				
				//Open Project settings view
				Button {
					if !optionKeyPressed {
						localSettingsOpened.toggle()
					} else {
						devSettingsOpened.toggle()
					}
				} label: {
					Label("Open Project Settings", systemImage: "gearshape")
				}
				
				//Project settings
				.popover(isPresented: $localSettingsOpened) {
					ProjectSettingsview(settingsOpened: $localSettingsOpened, project: project)
				}
				
				//Developer settings
				.popover(isPresented: $devSettingsOpened) {
					DevSettingsview(devSettingsOpened: $devSettingsOpened, debugMode: Binding(get: { return debugMode }, set: { value in debugMode = value; scheduleViewReload()}))
				}
				
				//Detect when option key is pressed
				#if os(macOS)
				.onAppear {
					NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
						if event.modifierFlags.contains(.option) {
							optionKeyPressed = true
						} else {
							optionKeyPressed = false
						}
						return event
					}
				}
				#endif
				
				//Add new Bucket
				Button {
					let newBucket = Bucket(position: project.buckets.count+1)
					if project.settings.useScrollViewForBuckets {
						project.buckets.add(newBucket)
						withAnimation(standartAnimation) {
							scrollPosition.scrollTo(id: newBucket.id)
						}
					} else {
						withAnimation(standartAnimation) {
							project.buckets.add(newBucket)
						}
					}
				} label: {
					Label("Add Bucket", systemImage: "tray")
				}
			}
        }
        .navigationTitle(project.title)
		.toolbarTitleDisplayMode(.inline)
		.ignoresSafeArea(.keyboard, edges: .bottom) //Resolves really bad hangs on iOS; textFields want to do some resizing when clicked on; does this prevent that? -no :(
    }
}



#Preview {
	@Previewable @Environment(\.colorScheme) var colorScheme
	@Previewable @State var settingsOpened = false
	@Previewable @State var clipBoard: Idea? = nil
	
	ZStack {
		Projectview(project: previewproject, clipBoard: $clipBoard){}
			.environment(GlobalUserSettings())
			.environment(previewproject)
		
		NotificationOverlay()
	}
}


