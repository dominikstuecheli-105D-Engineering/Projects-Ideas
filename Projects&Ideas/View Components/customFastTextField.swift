//
//  customFastTextField.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI



//custom text field to only saves when it is finished being edited, better performance because SwiftData is somehow saving on every change or at least laggs the app significantly.
struct customFastTextField: View {
	
	var placeHolder: String //What to show if the string for the textField is empty
	@Binding var string: String
	
	///NOTE: On iOS, the textEditor works totally different (mostly worse) and can therefore not be used. The only difference between TextFields and TextEditors is that editors allow for Paragraphs. I wanted this, at least for macOS. This variable defines if a TextField or a TextEditor is used. on macOS it has to be actively enabled on init(), on iOS it is on by default.
	#if os(iOS)
	var useActualTextField: Bool = true
	#else
	var useActualTextField: Bool = false
	#endif
	
	@State var localString: String = "" //Local placeholder string, not bound to SwiftData modelContext
	@State var isEditing: Bool = false
	
	var executeAtOnChange: (_ oldValue: String, _ newValue: String) -> String = {oldValue, newValue in return newValue} //This allows for more flexibility on what to do if the string changes, but by default it does not modify the string.
	
	//CUSTOM SAVE LOGIC FOR SWIFTDATA PERFORMANCE
	
	@State private var saveWorkItem: DispatchWorkItem?
	
	//Cancel old save order, create new, delayed one
	private func scheduleSave() {
		saveWorkItem?.cancel() //Cancel old save order
		isEditing = true
		
		saveWorkItem = DispatchWorkItem {
			string = localString
			isEditing = false
			ModelContextManager.shared.save() //Save everything after change
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: saveWorkItem!) //Schedule next save order
	}
	
	//Viewcode
	var body: some View {
		ZStack {
			//If string is empty, display the placeholder
			if localString == "" && !useActualTextField {
				HStack {
					Text(placeHolder)
						.padding(.leading, 4)
						.opacity(0.5)
					Spacer()
				}
			}
			
			Group {
				if useActualTextField {
					//When TextField is used
					
					TextField(placeHolder, text: $localString, axis: .vertical)
						.textFieldStyle(PlainTextFieldStyle())
						.autocorrectionDisabled()
						.scrollDisabled(true)
						.fixedSize(horizontal: false, vertical: true)
				} else {
					//When TextEditor is used
					
					TextEditor(text: $localString)
						.textEditorStyle(PlainTextEditorStyle())
						.autocorrectionDisabled()
						.scrollDisabled(true)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			
			//Handling the string saving in SwiftData
			.onAppear { localString = string }
			.onChange(of: localString) { oldValue, newValue in
				if (oldValue == "" && newValue == string) != true {
					scheduleSave(); localString = executeAtOnChange(oldValue, newValue)
				} //This if clause only triggers false if the textField view was just created, so that there arent like 50 save orders for the modelContext when a project view is opened
			}
			
			//Showing a little Icon on the right of the text field to show that the string is not yet saved into storage/modelContext, not needed but gives nice visual feedback
			if isEditing {
				HStack {
					Spacer()
					Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
						.resizable()
						.scaledToFit()
						.frame(height: 15)
						.bold()
						.foregroundStyle(Color.blue.opacity(0.5))
				}
			}
		}
	}
}



#Preview {
	@Previewable @State var string: String = ""
	
	customFastTextField(placeHolder: "No string", string: $string)
		.frame(width: 200)
		.padding(standartPadding)
}
