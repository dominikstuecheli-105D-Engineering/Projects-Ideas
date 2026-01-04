//
//  Drag&Drop Logic&Views.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



///NOTE: This Drag&Drop system goes way beyond the native SwiftUI system. To understand it better, this is what happens during a drag&drop process:
///
///`1. The user clicks on the item that is to be moved and starts to drag it`
///The .activate function of the DragAndDropController is called and does the following:
///
/// - The currentType variable is set to the type of the Transferable used: This is for the dropDestinations to only expand when their expected type is the same as the currentType. If the currentType is nil (When the content comes from outside the app) they expand regardless of type as it is not known.
///
/// - The localPayload variable is set to the payload, if given. This serves as a bypass to the limitations of the Transferable protocol.
///
/// - A 5-second timer starts, after which the currentType is reset to nil. I made it like this because I did not find a reliable way to detect when drag operations end (including cases where the dragged item is not dropped anywhere). The localPayload variable is NOT reset, as it is essential to some drag operations like moving an Idea which should still work, even after 5 seconds.
///
///<It is important to know what type of Transferable is currently being dragged so that only the dropDestinations which accept that type are allowed to expand. This is important as the drop destinations of Idea lists cover the drop destinations of Idea extensions which could be confusing to the user. This problem is really the whole reason the system is so complicated, together with the fact that the app also needs to be able to handle external imports.>
///
/// <All of these actions are also executed if the user only clicks on the item and doesnt start to move it because I did not find a reliable way to detect the start of a drag operation that is pre iOS/macOS 26 compatible. This is only a problem if the user tries to import something from outside the app within 5 seconds of clicking something (Buttons are excluded because they do their hit-testing before the background) which I consider an edge-case.>
///
/// `2. The user drags the item into a DragAndDropList`
///This is detected if any of the standartDropDestinationHitboxes are touched.
///
/// - All the standartDropDestinationHitboxes expand to their maximum size. all of the space available to the DragAndDropList is now covered in hitboxes. In practice this means that the nearest drop destination to the pointer shows its blue bar which means that the item would be dropped there. The standartDropDestinationHitboxes cannot always have this size as their hit-testing blocks the buttons below.
///
/// - The 5-second timer for the reset is restarted as the user is seemingly still doing something.
///
/// `3. The user drops the item`
/// - The given function on what to do when something is dropped is called on a different thread. This function differs between use cases but they mostly make use of the localPayload variable. They can also have differentiations on what to do if the content is from within the app or not.
/// 
/// - The .reset() function on the DragAndDropController is called which does the same thing as the 5-second timer does at its end. The timer is cancelled.







//Global DragAndDropController class to improve drag&drop app-internally while still allowing external imports.

///NOTE: I only implented this Transferable bypass much later in the development process, which is why there are still Transferable objects being used for ChecklistItems. The bypass is mainly made to allow classes like Ideas, which themselfes are not Codable (which is required for Transferables), to be directly moved without having to search for them by the content of the Transferable. ChecklistItems only contain a Bool and a String, so they are Codable, which is why i didnt update them to also use this bypass.

class DragAndDropController {
	static var shared = DragAndDropController()
	var currentType: (any Transferable.Type)? //The type that is currently being Drag&Dropped
	var localPayload: Any? = nil //app-internal payload to complelety bypass Transferables
	var isActive: Bool = false //If a drag operation is active
	
	//Reset process handling
	///NOTE: I have not found a way to reliably detect when drag operation ends (including cases where the dragged item is not dropped anywhere) so I just reset the process after a certain amount of time. this reset process is restarted when a new dragging process starts.
	
	var resetWorkItem: DispatchWorkItem?
	func scheduleReset() {
		resetWorkItem?.cancel() //Cancel old reset order
		resetWorkItem = DispatchWorkItem {self.reset()}
		DispatchQueue.main.asyncAfter(deadline: .now()+5, execute: resetWorkItem!) //Schedule next reset
	}
	
	func reset() {currentType = nil; isActive = false}
	
	//Activation
	var recentlyActivated: Bool = false //Because the drag gesture is triggered for multiple views if they are layered, the activation is triggered multiple times for multiple Transferable types. this logic prevents that and only respects the first of multiple activation orders.
	func activate(type: any Transferable.Type, _localPayload: Any? = nil) { if recentlyActivated == false {
		resetWorkItem?.cancel()
		recentlyActivated = true
		DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {self.recentlyActivated = false})
		currentType = type; localPayload = _localPayload; isActive = true
		scheduleReset()
	} }
	
	func currentIsType(_ type: any Transferable.Type, _default: Bool = false) -> Bool {
		if currentType != nil {
			return currentType == type
		} else {return _default} //If the currentType is nil even tho there is something being dragged, it has to be something from outside the app. In that case it just returns the given default.
	}
}

//Functions outside the class for better readability
func currentDragAndDropTypeIs(_ type: any Transferable.Type, _default: Bool = false) -> Bool {
	return DragAndDropController.shared.currentIsType(type, _default: _default)}

func getLocalDragAndDropPayload<PayloadType>() -> PayloadType? {
	if DragAndDropController.shared.localPayload is PayloadType {
		return DragAndDropController.shared.localPayload as? PayloadType
	} else {return nil}
}



//View modifier to automatically handle everything with the DragAndDropController: meant to replace .draggable {}
struct LocalTransferableModifier<PreviewContent: View, TransferableType: Transferable>: ViewModifier {
	var payload: TransferableType
	var localPayload: Any?
	var preview: () -> PreviewContent
	
	@State private var isDragging = false
	
	func body(content: Content) -> some View {
		content
			.draggable(payload) {preview()}
		
			//Detect when dragging starts
			.onLongPressGesture(minimumDuration: 0, pressing: { pressing in
				if pressing && !isDragging {
					isDragging = true
				}
			}, perform: {})
			
			.onChange(of: isDragging) { _, new in
				if new == true {
					DragAndDropController.shared.activate(type: TransferableType.self, _localPayload: localPayload)
					isDragging = false
				}
			}
	}
}

extension View {
	func localTransferable<ViewContent: View, TransferableType: Transferable>(_ payload: TransferableType, localPayload: Any? = nil, @ViewBuilder preview: @escaping () -> ViewContent) -> some View {
		modifier(LocalTransferableModifier(payload: payload, localPayload: localPayload, preview: preview))
	}
}



///NOTE: The DragAndDropList view construction is quite complicated because I wanted the hitboxes to feel right, which means the nearest gaps in list items is shown as the position the dragged item would be dropped in. This is achieved by storing geometry values of all list items and then calculating the hitboxes from that. The hitboxes are seperate views layered over the list. The visual bars are just dummy-views that get the command to appear from the dropDestinationHitbox view. The hitbox views work a lot with paddings and frames. .offset and .position would not work for hit-testing. To see the hitboxes for testing activate debug mode.

//The visual part of the dropDestination; detached because the functional part lives in a different part of the view construction
struct DropDestinationVisualBar: View {
	
	var shown: Bool
	@State var animatedShown: Bool = false //Another variable that is changed via withAnimation() for proper animations
	
	var body: some View {
		RoundedRectangle(cornerRadius: standartPadding/2)
			.frame(height: standartPadding)
			.foregroundStyle(animatedShown ? Color.blue : Color.clear)
		
			.padding([.top, .bottom], animatedShown ? standartPadding/2 : 0)
		
			.onChange(of: shown) { _, new in
				withAnimation(standartAnimation) {
					animatedShown = new
				}
			}
	}
}

//The functional part; mainly handles its hitbox
struct DropDestinationHitbox<DataType: Transferable>: View {
	
	var position: Int //At which Position in whatever List it is
	
	var aboveContent: CGRect
	var belowContent: CGRect //The coordinates and sizes of the items above and below are needed to calculate the hitbox size and position
	
	@State var color: Color = Color(red: .random(in: 0.5...1), green: .random(in: 0.5...1), blue: .random(in: 0.5...1)) //Assign self a random color so hitboxes can be seen better in debugMode
	
	@Binding var hoveredOverPosition: Int? //The position of the space the pointer is hovering over
	@State var localHoverState: Bool = false
	
	var doWhenDropped: (_ object: DataType, _ at: Int) -> Bool //What to do with the dropped Transferable: returns true if the drop was successfull
	
	var body: some View {
		VStack(spacing: 0) {
			//The Rectangle which forms the hitbox
			ZStack {
				Rectangle() .foregroundStyle(.clear)
				if debugMode {Text("insert at: \(position)") .foregroundStyle(color)}
			}
			
			//If the blue bar is shown the space between the content is larger
			.frame(height: hoveredOverPosition == position ? standartPadding*2 : standartPadding)
			
			//if expanded, expand to the middle of the content above
			.padding(.top, hoveredOverPosition != nil ? aboveContent.height/2 : standartPadding)
			
			//if expanded, expand to the middle of the content below
			.padding(.bottom, hoveredOverPosition != nil ? belowContent.height/2 : standartPadding)
			
			//If the height of the content above is 0, expand by standartPadding anyways
			.padding(.top, aboveContent.height == 0 && hoveredOverPosition != nil ? standartPadding : 0)
			
			//If the height of the content below is 0, expand by standartPadding anyways
			.padding(.bottom, belowContent.height == 0 && hoveredOverPosition != nil ? standartPadding : 0)
			
			.background(debugMode ? color.opacity(0.1) : .clear) .contentShape(Rectangle()) //Needed for proper functionality
			
			//Dropdestination code
			.dropDestination(for: DataType.self) { items, destination in
				var successfullDrop: Bool = false
				var counter: Int = 0
				
				DispatchQueue.main.async {
					for item in items {
						if doWhenDropped(item, position+counter) {successfullDrop = true; counter += 1}
					}
					DragAndDropController.shared.resetWorkItem?.cancel()
					DragAndDropController.shared.reset()
				}
				
				return successfullDrop
				
			//If hovered over, show blue bar
			} isTargeted: { hovering in
				if currentDragAndDropTypeIs(DataType.self, _default: true) {localHoverState = hovering}
			}
			
			//If in debugMode show the hitbox
			.border(debugMode ? color.opacity(0.5) : .clear)
			
			//Distance to the top of the list: if expanded subtract half the height of the content above as it expands
			.offset(y: hoveredOverPosition != nil ? aboveContent.midY : aboveContent.maxY - standartPadding)
			
			//If the height of the content above is 0, it still stays at a padding of standartPadding, that needs to be subtracted too
			.offset(y: aboveContent.height == 0 && hoveredOverPosition != nil ? -standartPadding : 0)
			
			//Handling the drag&drop logic correctly
			.onChange(of: localHoverState) { old, new in
				if new == true {hoveredOverPosition = position; DragAndDropController.shared.scheduleReset()} //Reset the 5-second timer
				
				if new == false { DispatchQueue.main.asyncAfter(deadline: .now()+0.05) {
					if hoveredOverPosition == position {
						hoveredOverPosition = nil
					}
				} }
			}
			
			Spacer(minLength: 0) //As this is technically a view positioned in a ZStack over the list, the spacer is needed so that the hitbox doesnt expand more than it should
		}
	}
}



struct CGRectPreferenceKey: PreferenceKey {
	static var defaultValue: [Int: CGRect] = [:]

	static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
		value.merge(nextValue(), uniquingKeysWith: {$1})
	}
}



//A generic view struct that makes it easier to implement drag&drop for various list views: The action which happens when an object is dropped is not the same for every application so it has to be specifically defined. This view automatically places dropDestinations between all elements as well as at the start and the end of the list.
struct DragAndDropList<DataType: PersistentArrayCompatible, TransferableType: Transferable, ViewContent: View, DividerContent: View>: View {
	
	var array: [DataType]
	
	let itemContent: (DataType) -> ViewContent
	let dividerContent: () -> DividerContent
	let onDrop: (TransferableType, Int) -> Bool
	
	private let id = UUID() //The id of this list view, needed to name the local coordinate space
	@State private var hoveredOverPosition: Int? = nil //The position of the space the pointer is hovering over
	
	@State private var contentCoordinates: [Int: CGRect] = [:]
	@State private var forceContentCoordinateUpdateValue: Bool = false //This variable is basically just here to force view updates when it changes, its value has no meaning
	@State private var pendingcontentCoordinateUpdate: Bool = false //If there is already an update pending
	
	//Force saved content coordinate value updates: starts a cycle that does an update every second
	///NOTE: I know this is a very unclean solution but it seems to be the only solution that is both not overcomplicated and works reliably.
	func contentCoordinateUpdate() {
		if pendingcontentCoordinateUpdate {return}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			for key in contentCoordinates.keys {
				if array.contains(where: {$0.position == key}) == false {
					contentCoordinates[key] = nil
				}
			}
			forceContentCoordinateUpdateValue.toggle()
			pendingcontentCoordinateUpdate = false
			contentCoordinateUpdate()
		}
	}
	
	init(_ array: [DataType], @ViewBuilder itemContent: @escaping (DataType) -> ViewContent, @ViewBuilder dividerContent: @escaping () -> DividerContent = {EmptyView()}, onDrop: @escaping (TransferableType, Int) -> Bool) {
		self.array = array
		self.itemContent = itemContent
		self.dividerContent = dividerContent
		self.onDrop = onDrop
	}
	
	var body: some View {
		VStack(spacing: 0) {
			
			//DropDestination at start of list
			DropDestinationVisualBar(shown: hoveredOverPosition == 1)
			
			//List items
			ForEach(array.sorted(by: {$0.position < $1.position})) { item in
				itemContent(item)
				
				//Geometry reader to read out the geometry data for the drag&drop hitboxes
					.background {
						GeometryReader { geometry in
							Rectangle() .foregroundStyle(.clear)
							
							//When a view update is forced, update the stored values
								.onChange(of: forceContentCoordinateUpdateValue) {_,_ in
									contentCoordinates[item.position] = geometry.frame(in: .named("\(id)"))
								}
						}
					}
				
				//DropDestination after every item and dividerContent if inbetween two items
				if item.position != array.count {
					ZStack { if !(hoveredOverPosition == item.position+1) {dividerContent()}
						DropDestinationVisualBar(shown: hoveredOverPosition == item.position+1) }
				} else {
					DropDestinationVisualBar(shown: hoveredOverPosition == item.position+1)
				}
			}
		}
		.onAppear {contentCoordinateUpdate()} //start the continuous update loop
		.coordinateSpace(name: "\(id)") //local coordinate space to get the coordinates of the list items
		
		//Custom dropDestination hitboxes
		.overlay { ZStack {
			//One at the beginning of the list
			DropDestinationHitbox(position: 1,
								  aboveContent: CGRect(x: 0, y: 0, width: 0, height: 0),
								  belowContent: contentCoordinates[1] ??
								  CGRect(x: 0, y: 0, width: 0, height: 0),
								  hoveredOverPosition: $hoveredOverPosition,
								  doWhenDropped: onDrop)
			
			//One after every list item
			ForEach(contentCoordinates.sorted(by: {$0.key < $1.key}), id: \.key) { key, rect in
				DropDestinationHitbox(position: key+1,
									  aboveContent: contentCoordinates[key] ??
									  CGRect(x: 0, y: 0, width: 0, height: 0),
									  belowContent: contentCoordinates[key+1] ??
									  CGRect(x: rect.height, y: 0, width: 0, height: 0),
									  hoveredOverPosition: $hoveredOverPosition,
									  doWhenDropped: onDrop)
			} }
		}
	}
}



//Small Drag&Drop handle on the leading side of each Idea
struct DragAndDropHandle: View {
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: standartPadding)
				.foregroundStyle(Color.gray.opacity(0.2))
				.frame(width: standartPadding*2)
			
			RoundedRectangle(cornerRadius: standartPadding-3)
				.foregroundStyle(Color.gray.opacity(0.2))
				.padding(3)
				.frame(width: standartPadding*2)
		}
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
