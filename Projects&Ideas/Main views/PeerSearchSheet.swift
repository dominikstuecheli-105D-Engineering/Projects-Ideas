//
//	PeerSearchSheet.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 15.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity



private struct PeerCard: View {
	
	let peer: MCPeerID
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	let connectionController = PeerConnectionController.shared
	
	var body: some View {
		HStack {
			Text(peer.displayName)
				.font(.system(size: globalUserSettings.UISize.mediumText, weight: .regular, design: .default))
				.padding(.leading, 3)
			
			Spacer(minLength: 0)
			
			//If waiting for invite response
			if connectionController.waitingForInviteResponse == peer {
				
				Text("Pending...")
					.font(.system(size: globalUserSettings.UISize.mediumText, weight: .bold, design: .default))
					.foregroundStyle(.gray)
					.padding([.top, .bottom], standartPadding)
				
			//If data transfer is ongoing
			} else if connectionController.sendingProgress != nil && connectionController.session.connectedPeers.contains(peer) {
				TimelineView(.animation) {_ in
					//Progress in percentage
					let progressString = String(format: "%.0f", connectionController.sendingProgress!.fractionCompleted*100)
					
					Text("\(progressString)%")
						.font(.system(size: globalUserSettings.UISize.mediumText, weight: .bold, design: .default))
						.foregroundStyle(.gray)
						.padding([.top, .bottom], standartPadding)
					
				} .padding(.trailing, 3)
				
			//Button to send an invite
			} else {
				//"Send" button
				standartButton(systemName: "Send", color: .blue, frame: globalUserSettings.UISize.smallText, withBackground: true, cornerRadius: standartPadding*2, containsText: true, tryToExpand: false) {
					PeerConnectionController.shared.requestSend(to: peer)
				}
			}
		}
		.padding(standartPadding)
		.background {
			Color.gray.opacity(0.1)
		}
		.clipShape(RoundedRectangle(cornerRadius: standartPadding*3))
	}
}



struct PeerSearchSheet: View {
	
	@Environment(GlobalUserSettings.self) var globalUserSettings: GlobalUserSettings
	let connectionController = PeerConnectionController.shared
	
    var body: some View {
		VStack(spacing: standartPadding) {
			HStack {
				
				//TITLE
				Spacer(minLength: 3)
				Text("Searching network")
					.frame(maxWidth: .infinity, maxHeight: globalUserSettings.UISize.largeText, alignment: .leading)
					.font(.system(size: globalUserSettings.UISize.largeText, weight: .bold, design: .default))
				
				standartButton(systemName: "plus", color: primaryUIelement, frame: globalUserSettings.UISize.large, withBackground: true, animationStartAngle: 45) {
					connectionController.isBrowsing = false
				}
			}
			
			Divider()
			
			ForEach(connectionController.availablePeers, id: \.displayName) { peer in
				PeerCard(peer: peer)
			}
			
			#if os(iOS)
			Spacer()
			#endif
		} .padding(standartSheetPadding)
    }
}



#Preview {
    PeerSearchSheet()
}
