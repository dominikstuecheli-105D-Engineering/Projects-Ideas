//
//  Button&Checkbox.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



//Custom hover effect to work on macOS too and just generally allows for more flexibility
private struct CustomHoverEffect: ViewModifier {
	
	#if os(macOS)
	static let tintValue: CGFloat = 0.65
	#else
	static let tintValue: CGFloat = 1
	#endif
	
	var hoverValueBinding: Binding<Bool>?
	let disableTint: Bool
	@State var hoverEffect: Bool = false
	
	func body(content: Content) -> some View {
		content
			#if os(iOS)
			.hoverEffect(.lift)
			#else
			.opacity((hoverEffect && disableTint == false) ? CustomHoverEffect.tintValue : 1)
			#endif
		
		//Detect hover
			.onHover { hovering in
				hoverEffect = hovering
				hoverValueBinding?.wrappedValue = hovering
			}
	}
}

extension View {
	func customHoverEffect(_ hoverValueBinding: Binding<Bool>? = nil, disableTint: Bool = false) -> some View {
		modifier(CustomHoverEffect(hoverValueBinding: hoverValueBinding, disableTint: disableTint))
	}
}



//This Button is used a lot and therefore is also very flexible. it can be animated, can use alerts and has either an icon or text as the label.
struct standartButton: View {
	
	let systemName: String //The icon systemName
	let color: Color
	let frame: CGFloat //The size
	var withBackground: Bool = false
	var containsText: Bool = false //Use text rather than an icon for the label
	
	//If Animated
	var animationValue: Bool = false //The value to be animated by
	var animationStartAngle: CGFloat = 0
	var animationEndAngle: CGFloat = 0
	
	//If with Alert
	var withAlert: Bool = false
	var alertTitle: String = "" //The alert message
	var alertConfirmationTitle: String = "Delete" //the title of the confirmation button
	
	@State var hoverEffect: Bool = false
	@State var showAlert: Bool = false
	
	//Button action
	let action: () -> Void
	
	//Viewcode
	var body: some View {
		Button (action: withAlert ? {showAlert = true} : action) {
			if containsText == false {
				
				//Icon
				Image(systemName: systemName)
					.resizable()
					.scaledToFit()
					#if os(macOS)
					.bold() //on iOS the system already does this itself
					#endif
					.frame(maxWidth: frame*0.75, maxHeight: frame*0.75)
					.contentShape(Rectangle())
					.foregroundStyle(color)

				//animation
					.rotationEffect(animationValue ? Angle(degrees: animationEndAngle) : Angle(degrees: animationStartAngle))
					.animation(standartAnimation, value: animationValue) //This is redundant in most cases, but in cases where the value is not changed via withAnimation() the icon should still be animated.
				
				//Frame stuff
					.frame(width: frame, height: frame)
					.background(withBackground || hoverEffect ? color.opacity(0.25) : Color.clear)
					.clipShape(RoundedRectangle(cornerRadius: standartPadding))
			} else {
				
				//Text
				HStack {
					Spacer(minLength: 0)
					Text(systemName)
						.font(.system(size: frame, weight: .bold, design: .default))
						.padding(standartPadding)
						.contentShape(Rectangle())
						.foregroundStyle(color)
					Spacer(minLength: 0)
				}
				
				//Frame and background stuff
					.background(withBackground ? color.opacity(0.25).opacity(hoverEffect ? CustomHoverEffect.tintValue : 1) : Color.clear)
					.clipShape(RoundedRectangle(cornerRadius: standartPadding*2))
			}
		}
		
		//Alert
		.alert(alertTitle, isPresented: $showAlert, actions: {
			Button(role: .destructive, action: action) {
				Text(alertConfirmationTitle)
			}
			Button(role: .cancel) {
				//no action
			} label: {
				Text("Cancel")
			}
		})
		
		//Button stuff
		.buttonStyle(.plain)
		.customHoverEffect($hoverEffect, disableTint: !withBackground)
	}
}



//A toggle switch as an alternative to standartButton, usefull for settings etc.
struct standartToggle: View {
	
	@Binding var value: Bool
	let frame: CGFloat //The size
	var hoverEffectOverride: Bool? = nil
	
	func getLeftPadding() -> CGFloat {
		if hoverAnimationState {return value ? frame/3 : frame/12} else {
			if value {return frame/2} else {return 0} }
	}
	
	func getRightPadding() -> CGFloat {
		if hoverAnimationState {return value ? frame/12 : frame/3} else {
			if !value {return frame/2} else {return 0} }
	}
	
	@State var hoverEffect: Bool = false
	@State var hoverAnimationState: Bool = false //If this variable is true the toggle is in a middle state where it has an special visual state. the variable resets when clicked. The variable is !not! the same as hoverEffect.
	
	var body: some View {
		Button {
			value.toggle()
		} label: {
			ZStack {
				RoundedRectangle(cornerRadius: standartPadding)
					.frame(width: frame/2*3, height: frame)
					.foregroundStyle(value ? .green.opacity(0.5) : .red.opacity(0.5))
					.opacity(hoverEffect ? CustomHoverEffect.tintValue : 1)
				
				ZStack {
					RoundedRectangle(cornerRadius: standartPadding*0.85)
						.foregroundStyle(.white)
					
					if hoverAnimationState {
						Image(systemName: value ? "arrow.left" : "arrow.right")
							.resizable()
							.scaledToFit()
							.foregroundStyle(.black.opacity(0.3))
							.bold()
							.padding(frame*0.075)
					}
				}
					.animation(standartAnimation, value: hoverAnimationState)
				
					.frame(width: frame*0.85, height: frame*0.85)
					.padding(frame*0.075)
					.padding(.leading, getLeftPadding())
					.padding(.trailing, getRightPadding())
			}
			.animation(standartAnimation, value: value)
		}
		.buttonStyle(.plain)
		.customHoverEffect($hoverEffect, disableTint: true)
		
		//All of these .onChange modifers make the variables hoverEffect, its external override hoverEffectOverride and hoverAnimationState seamlessly work together.
		.onChange(of: hoverEffectOverride) {_, new in
			if new != nil {hoverEffect = new!} //Copy the external override
		}
		.onChange(of: hoverEffect) {_, new in
			if new == true {hoverAnimationState = true}
			if new == false && hoverAnimationState {hoverAnimationState = false}
		}
		.onChange(of: value) {hoverAnimationState = false}
	}
}



//For true/false || on/off options, mainly used in Project settings.
struct standartCheckbox: View {
	
	var label: String
	@Binding var isChecked: Bool
	
	@State var hoverEffect: Bool = false
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	var body: some View {
		Button {
			isChecked.toggle()
		} label: {
			HStack {
				Text(label)
					.font(.system(size: globalUserSettings.UISize.smallText, weight: .regular, design: .default))
					.padding([.leading], 3)
				
				Spacer(minLength: 3)
				
				standartToggle(value: $isChecked, frame: globalUserSettings.UISize.small, hoverEffectOverride: hoverEffect)
			}
			.contentShape(Rectangle())
			//Frame for everything
			.padding(standartPadding)
			.background(Color.gray.opacity(0.1).opacity(hoverEffect ? CustomHoverEffect.tintValue : 1))
			.clipShape(RoundedRectangle(cornerRadius: standartPadding*2))
		}
		.buttonStyle(.plain)
		.customHoverEffect($hoverEffect, disableTint: true)
	}
}



#Preview {
	@Previewable @State var globalUserSettings = GlobalUserSettings()
	@Previewable @State var value: Bool = false
	
	VStack(spacing: standartPadding) {
		HStack(spacing: standartPadding) {
			standartButton(systemName: "gearshape", color: primaryUIelement, frame: globalUserSettings.UISize.large, animationValue: value, animationStartAngle: 180) {
				value.toggle()
			}
			
			standartButton(systemName: "gearshape.fill", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationValue: value, animationStartAngle: 180) {
				value.toggle()
			}
			
			standartButton(systemName: "value.toggle()", color: .blue, frame: globalUserSettings.UISize.smallText, withBackground: true, containsText: true) {
				value.toggle()
			}
		}
		
		standartCheckbox(label: "Test value", isChecked: $value)
			.environment(globalUserSettings)
	}
	.frame(width: 200)
	.padding(standartPadding)
}
