//
//  NoProjectPlaceholder.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 29.12.2025.
//

import SwiftUI



//This placeholder is shown when no project is selected.
struct NoProjectPlaceholder: View {
    var body: some View {
		VStack {
			Image(systemName: "folder.badge.questionmark")
				.resizable() .scaledToFit()
				.frame(width: 50, height: 50)
				.foregroundStyle(Color.blue)
			Text("no Project selected")
				.font(.title2) .bold()
		}
    }
}

#Preview {
    NoProjectPlaceholder()
		.padding(standartPadding*2)
}
