//
//  ImageCatalogueView.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.09.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI



//Custom PhotosPicker so it fits the app
private struct customPhotosPicker: View {
	
	@State var selectedItems: [PhotosPickerItem] = []
	let label: AnyView
	let doWithImport: (_ item: Data) -> Void
	
	init(@ViewBuilder label: () -> some View, doWithImport: @escaping (_: Data) -> Void)
	{ self.label = AnyView(label()); self.doWithImport = doWithImport }
	
	var body: some View {
		PhotosPicker(selection: $selectedItems, matching: .images) { label }
			.onChange(of: selectedItems) { _, newItems in
				for item in newItems {
					//Removing the itemsfrom selection so if the photosPicker is reopened nothing is selected
					selectedItems.remove(at: selectedItems.firstIndex(where: {$0 == item})!)
					
					//Task is the same as DispatchQueue.main.async but integrates better with SwiftUI
					Task {
						if let itemData = try? await item.loadTransferable(type: Data.self) {
							doWithImport(itemData)
						}
					}
				}
			}
	}
}



//View for each image item, image loading (multithreading) is handled here
private struct SelfLoadingImageView: View {
	
	var imageData: Data
	var imageItem: ImageCatalogueItem //only needed for the draggable localPayload
	
	@State var uiImage: Image? = nil
	@State var imageLoaded: Bool = false
	
	//not all platforms handle images the same way
	private func imageFromData() -> Image? {
		
		let data: Data = self.imageData
		
		#if os(iOS)
		if let uiImage = UIImage(data: data) {
			return Image(uiImage: uiImage)
		}
		#elseif os(macOS)
		if let nsImage = NSImage(data: data) {
			return Image(nsImage: nsImage)
		}
		#endif
		return nil
	}
	
	//Viewcode
	var body: some View {
		
		Group {
			if imageLoaded {
				uiImage! .resizable() .scaledToFill()
				//Drag&Drop functionality, for the ability to get the image out of the app as an image file. not using the .localTransferable modifier because this works with NSItemProviders which use different logic on creation.
				.onDrag {
					let url = FileManager.default.temporaryDirectory
						.appendingPathComponent("\(UUID().uuidString).png")
					try? imageData.write(to: url)
					DragAndDropController.shared.activate(type: Data.self, _localPayload: imageItem)
					return NSItemProvider(contentsOf: url)!
				} preview: {
					uiImage! .resizable() .scaledToFit()
				}
				
			} else {
				
				//Placeholder if the image is not loaded yet
				Rectangle() .frame(height: 100)
					.foregroundStyle(.gray.opacity(0.1))
			}
		}
		
		//Load the image from the Data on another thread
		.onAppear {
			DispatchQueue.main.async { uiImage = imageFromData() }
		}
		
		//if the image is finished being loaded, display it
		.onChange(of: uiImage) {
			withAnimation(standartAnimation) { imageLoaded = true }
		}
	}
}



//Actual View
struct IdeaExtensionImageCatalogueView: View {
	
	@Bindable var imageCatalogue: ImageCatalogue
	
	//This variable gives the sheet view the image it needs to display
	@State var fullscreenImageData: Data? = nil
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(ProjectSettings.self) var projectSettings: ProjectSettings
	@Environment(\.colorScheme) var colorScheme
	
	//Code for the dropDestination (as well as the PhotosPicker)
	func doWhenDropped(_ item: Data, insertPosition: Int) -> Bool {
		
		var successfullDrop: Bool = false
		
		#if os(iOS)
		if UIImage(data: item) != nil {
			let newItem = ImageCatalogueItem(item, position: insertPosition)
			withAnimation(standartAnimation) {
				imageCatalogue.images.add(newItem)
			}; successfullDrop = true
		}
		#elseif os(macOS)
		if NSImage(data: item) != nil {
			let newItem = ImageCatalogueItem(item, position: insertPosition)
			withAnimation(standartAnimation) {
				imageCatalogue.images.add(newItem)
			}; successfullDrop = true
		}
		#endif
		
		return successfullDrop
	}
	
	//Viewcode
	var body: some View {
		if imageCatalogue.images.count == 0 {
			
			//Placeholder if there are no images
			VStack {
				Image(systemName: "photo.badge.arrow.down.fill")
					.resizable() .scaledToFit()
					.frame(height: globalUserSettings.UISize.small)
					.foregroundStyle(primaryUIelement)
				Text("Drop image here")
					.foregroundStyle(primaryUIelement)
			}
			//Larger hitbox for Drag&Drop
			.frame(height: globalUserSettings.UISize.small/20*75)
			.frame(maxWidth: .infinity)
			.contentShape(Rectangle())
			
			//Dropdestination for placeholder
			.dropDestination(for: Data.self) { items, location in
				var successfullDrop: Bool = false
				
				for item in items {
					if doWhenDropped(item, insertPosition: 1) { successfullDrop = true }
				}; return successfullDrop
			}
			
		} else {
			//If there are images to display
			
			DragAndDropList(imageCatalogue.images) { imageItem in
				
				//Image card
				ZStack {
					Rectangle()
						.foregroundStyle(.gray.opacity(0.2))
						.clipShape(RoundedRectangle(cornerRadius: standartPadding))
					
					VStack(spacing: 0) {
						
						//Image view
						SelfLoadingImageView(imageData: imageItem.image, imageItem: imageItem)
							.clipShape(RoundedRectangle(cornerRadius: standartPadding))
						
						//If tapped on, open fullscreen view
							.onTapGesture { fullscreenImageData = imageItem.image }
						
						//Image title and delete button
						HStack {
							
							//Image title
							customFastTextField(placeHolder: "Image title", string: Binding {
								return imageItem.title
							} set: { newValue in
								imageItem.title = newValue
							})
							.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
							.foregroundStyle(primaryUIelement)
							
							Spacer()
							
							//Delete image
							standartButton(systemName: "trash", color: primaryUIelement, frame: globalUserSettings.UISize.small, withAlert: projectSettings.ideaDeletionRequiresConfirmation ? true : false, alertTitle: "Delete Image: \(imageItem.title)?") {
								withAnimation(standartAnimation) {
									imageCatalogue.images.remove(imageItem)
									
									//Notification
									customNotificationCentre.shared.new("Deleted Image: \(imageItem.title)", level: .destructive)
								}
							}
							
						}
						.padding(standartPadding/2)
					}
				}
				
			} onDrop: { data, position in
				var returnValue = false
				let localPayload: ImageCatalogueItem? = getLocalDragAndDropPayload()
				
				withAnimation(standartAnimation) {
					if localPayload != nil && currentDragAndDropTypeIs(Data.self) {
						//If only moved locally
						imageCatalogue.images.move(localPayload!, toPos: position)
						returnValue = true
					} else {
						//If imported
						returnValue = doWhenDropped(data, insertPosition: position)
					}
				}
				
				return returnValue
			}
			
			#if os(macOS)
			.sheet(isPresented: Binding(get: {return fullscreenImageData != nil}, set: {bool in if bool {fullscreenImageData = nil}})) {
				if let data = fullscreenImageData {
					SelfLoadingImageView(imageData: data, imageItem: ImageCatalogueItem(data, position: 1))
					
					//Close button
						.overlay(alignment: .topTrailing) {
							standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationStartAngle: 45) {
								fullscreenImageData = nil
							}
							.background(colorScheme == .light ? .white.opacity(0.8) : .black.opacity(0.8))
							.clipShape(RoundedRectangle(cornerRadius: standartPadding))
							.padding(standartSheetPadding)
						}
				}
			}
			#else
			.fullScreenCover(isPresented: Binding(get: {return fullscreenImageData != nil}, set: {bool in if bool {fullscreenImageData = nil}})) {
				if let data = fullscreenImageData {
					SelfLoadingImageView(imageData: data, imageItem: ImageCatalogueItem(data, position: 1))
						.scaledToFit()
					
					//Close button
						.overlay(alignment: .topTrailing) {
							standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationStartAngle: 45) {
								fullscreenImageData = nil
							}
							.background(colorScheme == .light ? .white.opacity(0.8) : .black.opacity(0.8))
							.clipShape(RoundedRectangle(cornerRadius: standartPadding))
							.padding(standartSheetPadding)
						}
				}
			}
			#endif
		}
		
		//Photos picker, always at the bottom
		customPhotosPicker {
			ZStack {
				RoundedRectangle(cornerRadius: standartPadding)
					.foregroundStyle(Color.blue.opacity(0.25))
				
				HStack {
					Image(systemName: "plus")
						.resizable() .scaledToFit()
						.frame(height: globalUserSettings.UISize.smallText*0.85)
						.foregroundStyle(Color.blue)
						.padding(standartPadding)
						.bold()
					Spacer()
					
					Text("Import from device")
						.font(.system(size: globalUserSettings.UISize.smallText, weight: .bold, design: .default))
						.foregroundStyle(Color.blue)
					Spacer()
				}
			}
		} doWithImport: { item in
			_ = doWhenDropped(item, insertPosition: imageCatalogue.images.count+1) //Same code as the dropDestinations as both actions are Data -> ImageCatalogueItem
		}
		.buttonStyle(.plain)
		.customHoverEffect()
		.fixedSize(horizontal: false, vertical: true)
	}
}



#if os(macOS)
#Preview {
	@Previewable @State var idea: Idea = Idea(title: "Idea 1", desc: "", position: 1, extensions: [
		IdeaExtension(.checklist, content: Checklist(), position: 1),
		IdeaExtension(.imageCatalogue, content: ImageCatalogue(images: [
			ImageCatalogueItem(NSImage(named: "A350")!.tiffRepresentation!, position: 1),
			ImageCatalogueItem(NSImage(named: "A350")!.tiffRepresentation!, position: 2),
		]), position: 2)
	])
	
	ZStack {
		Rectangle()
			.frame(width: 350, height: 350)
			.foregroundStyle(Color.clear)
		
		IdeaExtensionView(idea: idea, ideaExtension: idea.extensions[1])
			.padding(standartPadding)
			.frame(width: 350)
			.environment(GlobalUserSettings())
			.environment(ProjectSettings())
	}
}
#endif
