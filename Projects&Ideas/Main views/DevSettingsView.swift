//
//  DevSettingsView.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 04.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



///NOTE: Everything in this file in unrelevant to the App and its User. It is merely a developer tool. The Developer window can be opened by clicking the Project settings button while pressing the "option" key.



struct DevSettingsview: View {
	
	@Binding var devSettingsOpened: Bool
	@Binding var debugMode: Bool
	
	//SwiftUI does not update with file-wide values (they are not Observable). debugMode is not an Observed value so this is pseudo value for the checkbox to immediately respond.
	@State var localDebugMode: Bool = false
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	
	var body: some View {
		VStack(spacing: standartPadding) {
			HStack {
				//TITLE
				Spacer(minLength: 3)
				Text("Developer")
					.frame(maxWidth: .infinity, maxHeight: globalUserSettings.UISize.largeText, alignment: .leading)
					.font(.system(size: globalUserSettings.UISize.largeText, weight: .bold, design: .default))
				
				standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationStartAngle: 45) {
					devSettingsOpened = false
				}
			}
			
			Divider()
			
			Text("Internal values")
				.font(.system(size: globalUserSettings.UISize.largeText, weight: .regular, design: .default))
			
			Text("SwiftUI only updates these values on total view updates; changes may not be visible immediately")
				.font(.footnote)
				.foregroundStyle(primaryUIelement)
			
			standartCheckbox(label: "debugMode", isChecked: Binding(get: { return localDebugMode }, set: { value in debugMode = value; localDebugMode = value }))
			
			Divider()
			
			//SWIFTDATA
			
			Text("SwiftData")
				.font(.system(size: globalUserSettings.UISize.largeText, weight: .regular, design: .default))
			
			Text("SwiftData storage URL: \(ModelConfiguration().url.path)")
				.font(.footnote)
				.foregroundStyle(primaryUIelement)
			
			//MODELCONTEXT OVERVIEW
			VStack(spacing: 3) {
				Text("ModelContextManager status values")
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .bold, design: .default))
				
				ForEach(ModelContextManager.shared.getStatus(), id: \.self) { stringPair in
					Divider()
					HStack {Text(stringPair[0]);Spacer(minLength: standartPadding);Text(stringPair[1])}
				}
			}
			.padding(standartSheetPadding)
			.background {
				RoundedRectangle(cornerRadius: standartPadding*2)
					.foregroundStyle(.gray.opacity(0.1))
			}
			
			//RENDER ALLOWANCE
			
			Text("Render allowance")
				.font(.system(size: globalUserSettings.UISize.largeText, weight: .regular, design: .default))
			
			//RENDER ALLOWANCE CONTROLLER OVERVIEW
			VStack(spacing: 3) {
				Text("RenderAllowanceController status values")
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .bold, design: .default))
				
				ForEach(RenderAllowanceController.shared.getStatus(), id: \.self) { stringPair in
					Divider()
					HStack {Text(stringPair[0]);Spacer(minLength: standartPadding);Text(stringPair[1])}
				}
			}
			.padding(standartSheetPadding)
			.background {
				RoundedRectangle(cornerRadius: standartPadding*2)
					.foregroundStyle(.gray.opacity(0.1))
			}
			
			
		}
		.padding(standartSheetPadding)
		//Because it is shown in sheets, no further frame stuff is needed
		
		.onAppear { localDebugMode = debugMode }
	}
}



#Preview {
	@Previewable @State var devSettingsOpened: Bool = true
	
	DevSettingsview(devSettingsOpened: $devSettingsOpened, debugMode: $devSettingsOpened)
		.environment(GlobalUserSettings())
}
