//
//  toolbarthings.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 11.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//



import SwiftUI



//Because SwiftUI does not provide a universal Divider for the Toolbar
struct customToolbarDivider: View {
	var body: some View {
		RoundedRectangle(cornerRadius: 1)
			.frame(width: 2, height: 20)
			.foregroundStyle(toolbarItemColor(opacity: 0.75))
	}
}



//Because SwiftUI only adjusts the color for normal toolbar stuff like Buttons, this replicates the color
func toolbarItemColor(opacity: Double = 1) -> Color {
	#if os(iOS)
	if #available(iOS 26, *) {
		return .white //iOS 26+
	} else {
		return .blue.opacity(opacity) //iOS 18 and older
	}
	#else
	if #available(macOS 26, *) {
		return .white //macOS 26+
	} else {
		return .gray.opacity(opacity) //Older macOS Versions
	}
	#endif
}



#Preview {
	customToolbarDivider()
}
