//
//  hardcoded UI values.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 26.11.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



//FOR DEBUG
var debugMode: Bool = false



//UI STANDARTS
let standartPadding: CGFloat = 6
let standartAnimation = Animation.spring(duration: 0.2)

//Because iOS/macOS 26+ have larger border radii on the sheet views, the padding needs to be bigger; the padding for sheet views is therefore defined seperately here.
let standartSheetPadding: CGFloat = {
	if #available(iOS 26, macOS 26, *) {
		return 23
	} else {
		return standartPadding
	}
}()



//UI COLORS
let primaryUIelement: Color = .primary.opacity(0.6) //Text, buttons etc.
