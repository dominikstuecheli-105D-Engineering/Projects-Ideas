//
//  customColorPicker.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 06.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//



import SwiftUI



//The preset color palette for the Buckets



struct ColorPaletteColor: Identifiable {
    let color: Color
	let name: String
	
	//Light mode and Dark mode require slightly different colors
	let lightOpacity: Double
	let darkOpacity: Double
	
	//This Integer identifies the color
    let id: Int
}

//CUSTOM BUCKET COLORS
	
//The color palette from which the user can change the color of buckets. iOS and macOS require slightly different values because iOS apps are drawn on a black background whereas macOS apps are drawn on a dark gray background.
let iOSColors: [ColorPaletteColor] = [ //iOS color palette
	ColorPaletteColor(color: .gray, 	name: "Gray", 	lightOpacity: 0.2,	darkOpacity: 0.2, 	id: 1),
	ColorPaletteColor(color: .red, 		name: "Red", 	lightOpacity: 0.35,	darkOpacity: 0.25, 	id: 2),
	ColorPaletteColor(color: .orange, 	name: "Orange", lightOpacity: 0.4,	darkOpacity: 0.35, 	id: 3),
	ColorPaletteColor(color: .green, 	name: "Green", 	lightOpacity: 0.4,	darkOpacity: 0.25, 	id: 4),
	ColorPaletteColor(color: .blue, 	name: "Blue", 	lightOpacity: 0.25,	darkOpacity: 0.25, 	id: 5),
	ColorPaletteColor(color: .purple, 	name: "Purple", lightOpacity: 0.3,	darkOpacity: 0.25, 	id: 6),
	ColorPaletteColor(color: .teal, 	name: "Teal", 	lightOpacity: 0.4,	darkOpacity: 0.35, 	id: 7),
]
	
let macOSColors: [ColorPaletteColor] = [ //macOS color palette
	ColorPaletteColor(color: .gray,		name: "Gray", 	lightOpacity: 0.2,	darkOpacity: 0.1, 	id: 1),
	ColorPaletteColor(color: .red, 		name: "Red", 	lightOpacity: 0.35, darkOpacity: 0.2, 	id: 2),
	ColorPaletteColor(color: .orange, 	name: "Orange", lightOpacity: 0.4, 	darkOpacity: 0.3, 	id: 3),
	ColorPaletteColor(color: .green, 	name: "Green", 	lightOpacity: 0.3, 	darkOpacity: 0.2, 	id: 4),
	ColorPaletteColor(color: .blue, 	name: "Blue", 	lightOpacity: 0.25, darkOpacity: 0.2, 	id: 5),
	ColorPaletteColor(color: .purple, 	name: "Purple", lightOpacity: 0.3, 	darkOpacity: 0.2, 	id: 6),
	ColorPaletteColor(color: .teal, 	name: "Teal", 	lightOpacity: 0.4,	darkOpacity: 0.3, 	id: 7),
]
	
//Computed property to iterate through
var colorPalette: [ColorPaletteColor] = {
#if os(iOS)
	return iOSColors
#else
	return macOSColors
#endif
}()

//getColor function that is used for buckets to get the Color by its identifier
func getColor(_ id: Int,_ colorScheme: ColorScheme, respectOpacity: Bool = true) -> Color {
	var returnColor: Color = .gray
	
	if let foundColor = colorPalette.first(where: {$0.id == id}) {
		if respectOpacity {
			returnColor = foundColor.color.opacity(colorScheme == .light ? foundColor.lightOpacity : foundColor.darkOpacity)
		} else {
			returnColor = foundColor.color
		}
	}; return returnColor
}

extension Bucket {
	func getSelfColor(_ colorScheme: ColorScheme, respectOpacity: Bool = true) -> Color {
		return getColor(self.colorIdentifier, colorScheme, respectOpacity: respectOpacity)
	}
}



//CUSTOM COLOR PICKER VIEW

//The view that is shown for every color in the following color picker
struct customColorPickerCard: View {
	
	var color: ColorPaletteColor
	@Binding var selectedColorIdentifier: Int
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	@Environment(\.colorScheme) var colorScheme
	
	@State var hoverEffect: Bool = false
	
	var body: some View {
		Button {
			withAnimation(standartAnimation) {selectedColorIdentifier = color.id}
		} label: {
			HStack(spacing: 0) {
				Rectangle()
					.foregroundStyle(color.color)
				
				ZStack {
					Rectangle()
						.foregroundStyle(getColor(color.id, colorScheme))
					
					Text(color.name)
						.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
						.foregroundStyle(primaryUIelement)
				}
			}
			.clipShape(RoundedRectangle(cornerRadius: standartPadding))
			.frame(width: globalUserSettings.UISize.small*7, height: globalUserSettings.UISize.small)
			
			//If the color is the one that is selected, highlight it with a border
			.overlay { if selectedColorIdentifier == color.id || hoverEffect {
				RoundedRectangle(cornerRadius: standartPadding*1.5)
					.stroke(.gray.opacity(hoverEffect ? 0.25 : 0.5), lineWidth: standartPadding).padding(-standartPadding/2)
			} }
		}
		.buttonStyle(.plain)
		.customHoverEffect(Binding(get: {return hoverEffect},
								   set: {bool in hoverEffect = bool}), disableTint: true)
	}
}

//The whole color picker for the Buckets
struct customColorPicker: View {
    
    @Binding var selectedColorIdentifier: Int
    
    var body: some View {
        VStack(spacing: standartPadding) {
			ForEach(colorPalette) { color in
				customColorPickerCard(color: color, selectedColorIdentifier: $selectedColorIdentifier)
			}
        }
    }
}



#Preview {
	@Previewable @Environment(\.colorScheme) var colorScheme
	@Previewable @State var selectedColorIdentifier = 1
	
	VStack(spacing: standartPadding) {
		customColorPicker(selectedColorIdentifier: $selectedColorIdentifier)
			.environment(GlobalUserSettings())
		
		HStack(spacing: standartPadding) {
			ForEach(macOSColors) { color in
				Rectangle()
					.foregroundStyle(color.color.opacity(colorScheme == .light ? color.lightOpacity : color.darkOpacity))
					.clipShape(RoundedRectangle(cornerRadius: standartPadding))
			}
		}
		.padding([.leading, .trailing], standartPadding)
		
		HStack(spacing: standartPadding) {
			ForEach(iOSColors) { color in
				Rectangle()
					.foregroundStyle(color.color.opacity(colorScheme == .light ? color.lightOpacity : color.darkOpacity))
					.clipShape(RoundedRectangle(cornerRadius: standartPadding))
			}
		}
		.background(colorScheme == .light ? .clear : .black)
		.padding([.leading, .trailing, .bottom], standartPadding)
	}
}
