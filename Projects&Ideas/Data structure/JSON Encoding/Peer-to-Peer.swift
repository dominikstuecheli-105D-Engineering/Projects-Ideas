//
//	Peer-to-Peer.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 15.01.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SwiftUI



//A small struct that is sent with the invitation to give more context
struct SendableDataContext: Codable {
	var primaryString: String
	var secondaryString: String
	var tertiaryString: String
	
	func asString() -> String {
		return "\(primaryString)\n\(secondaryString)\n\(tertiaryString)\n"
	}
	
	init(primary: String = "No further information available", secondary: String = "No further information available", tertiary: String = "No further information available") {
		self.primaryString = primary
		self.secondaryString = secondary
		self.tertiaryString = tertiary
	}
	
	//Initialise from Data
	init(decode data: Data) throws {
		let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
		self = try decoder.decode(SendableDataContext.self, from: data)
	}
	
	func encode() -> Data? {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.prettyPrinted]
		do {
			return try encoder.encode(self)
		} catch {
			return nil
		}
	}
}







//The actual controller that handles all the peer-to-peer connection stuff
@Observable class PeerConnectionController: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
	
	static var shared = PeerConnectionController()
	
	static let serviceIdentifier: String = "projects-ideas" //The String that identifies the service when connecting to other Peers
	private let selfPeerId: MCPeerID //The Peer identifier that identifies this instance of the app
	
	//Session and other control objects
	let session: MCSession
	private let advertiser: MCNearbyServiceAdvertiser
	private let browser: MCNearbyServiceBrowser
	var isBrowsing: Bool = false
	var availablePeers: [MCPeerID] = [] //The found peers in the local network
	
	//Invitation stuff
	var receivedInvite: Bool = false
	private var receivedInviteFrom: MCPeerID?
	private var invitationHandler: ((Bool, MCSession?) -> Void)?
	var receivedDataContext: SendableDataContext = SendableDataContext()
	
	var waitingForInviteResponse: MCPeerID? = nil
	
	func invitationTitle() -> String {
		return "\(receivedInviteFrom?.displayName ?? "No one") is trying to share a Project"
	}
	
	func handleInvite(accept isAccepted: Bool) {
		if let handler = invitationHandler {
			handler(isAccepted, self.session)
		}
		receivedInvite = false
		receivedInviteFrom = nil
		invitationHandler = nil
	}
	
	//Sending progress
	var sendingProgress: Progress? //If the data is being sent, this shows the progress
	
	//Things that are to be sent are stored here before they are sent
	var dataToBeSent: Data?
	var dataContext: SendableDataContext?
	
	func prepareBuffer(data: Data, context: SendableDataContext) {
		dataToBeSent = data
		dataContext = context
		setIsBrowsing(to: true)
	}
	
	func resetBuffer() {
		dataToBeSent = nil; dataContext = nil
	}
	
	var changeProjectSelection: ((UUID?) -> Void)? //Given by ContentView to change the selected Project
	
	//INIT
	
	override init() {
		///NOTE: Since iOS 15+ .name on iOS does not return the user given name but a generic name describing the device, so its just "iPad". Identity protection stuff... So the software version is used as another point of identification, even tho its still not very helpful.
		#if os(macOS)
		selfPeerId = MCPeerID(displayName: Host.current().localizedName ?? "Unnamed Device")
		#else
		selfPeerId = MCPeerID(displayName: "\(UIDevice.current.name) (iOS \(UIDevice.current.systemVersion))")
		#endif
		
		session = MCSession(peer: selfPeerId, securityIdentity: nil, encryptionPreference: .required)
		advertiser = MCNearbyServiceAdvertiser(peer: selfPeerId, discoveryInfo: nil, serviceType: PeerConnectionController.serviceIdentifier)
		browser = MCNearbyServiceBrowser(peer: selfPeerId, serviceType: PeerConnectionController.serviceIdentifier)
		
		super.init()
		session.delegate = self
		advertiser.delegate = self
		browser.delegate = self
		
		setIsAdvertising(to: true)
	}
	
	deinit {
		setIsAdvertising(to: false)
		setIsBrowsing(to: false)
	}
	
	//ADVERTISEMENT IN LOCAL NETWORK
	
	//Set advertisement
	func setIsAdvertising(to isTrue: Bool) {
		if isTrue {
			advertiser.startAdvertisingPeer()
		} else {
			advertiser.stopAdvertisingPeer()
		}
	}
	
	//Receiving an invitation
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) { DispatchQueue.main.async {
		self.receivedInvite = true
		self.receivedInviteFrom = peerID
		self.invitationHandler = invitationHandler
		
		//Decoding the context object
		if context != nil {
			do {
				self.receivedDataContext = try SendableDataContext(decode: context!)
			} catch {
				//No error handling
			}
		}
	} }
	
	//BROWSING LOCAL NETWORK
	
	//Set browsing
	func setIsBrowsing(to isTrue: Bool) {
		if isTrue {
			browser.startBrowsingForPeers()
			self.isBrowsing = true
		} else {
			browser.stopBrowsingForPeers()
			availablePeers.removeAll()
			self.isBrowsing = false
			dataToBeSent = nil
		}
	}
	
	//Found a new peer
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		DispatchQueue.main.async {
			if !self.availablePeers.contains(peerID) {self.availablePeers.append(peerID)}
		}
	}
	
	//Lost connection to peer
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		DispatchQueue.main.async {self.availablePeers.removeAll(where: {$0 == peerID})}
	}
	
	//SESSION HANDLING
	
	//Invite was accepted and data transfer starts
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		DispatchQueue.main.async {
			switch state {
			//If a connection is established, start data transfer
			case .connected: do {if self.dataToBeSent != nil {self.sendResource(to: peerID)}}
			case .notConnected: do {self.waitingForInviteResponse = nil}
			default: do {}
			}
		}
	}
	
	//Dummy function because this app doesnt use streams
	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		stream.close()
	}
	
	//DATA SEND&RECEIVE
	
	//Requesting a connection (Sending an invite)
	func requestSend(to peerID: MCPeerID) {
		browser.invitePeer(peerID, to: session, withContext: dataContext?.encode(), timeout: 30)
		self.waitingForInviteResponse = peerID
		DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
			//If the invite is still pending after 30 seconds, discard
			if self.waitingForInviteResponse == peerID {self.waitingForInviteResponse = nil}
		}
	}
	
	//Sending large resources that should already be in the buffer
	private func sendResource(to peerID: MCPeerID) {
		if session.connectedPeers.contains(peerID) && dataToBeSent != nil {
			do {
				let tempId = UUID()
				let tempURL = FileManager.default.temporaryDirectory
					.appendingPathComponent(tempId.uuidString)

				try dataToBeSent!.write(to: tempURL)
				sendingProgress = session.sendResource(at: tempURL, withName: tempId.uuidString, toPeer: peerID)
				self.waitingForInviteResponse = nil //AFTER The sendingProgress is set, so that the UI is right
				
				resetBuffer()
			} catch {
				customNotificationCentre.shared.new("Error while sending Data: \(error)", level: .destructive)
				resetBuffer()
			}
		} else {self.waitingForInviteResponse = nil}
	}
	
	//Sending Data directly
	private func send(_ data: Data, to peerID: MCPeerID) {
		if session.connectedPeers.contains(peerID) {
			do {
				try session.send(data, toPeers: [peerID], with: .reliable)
			} catch {
				customNotificationCentre.shared.new("Error while sending Data: \(error)", level: .destructive)
			}
		}
	}
	
	//Receiving Data directly
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		//Not handled
	}
	
	//Receiving Data via URL
	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		customNotificationCentre.shared.new("Started receiving Data from \"\(peerID.displayName)\"")
	}
	
	//Finished receiving Data via URL
	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
		Task { @MainActor in do {
			
			guard let localURL else {return}
			
			if let context = ModelContextManager.shared.modelContext {
				let project = try await decodeProjectFromJson(url: localURL, to: context) //Decode
				customNotificationCentre.shared.new("Received \"\(project.title)\" from \"\(peerID.displayName)\"")
				if let changeProjectSelection {changeProjectSelection(project.id)} //Open the imported project
			}
			
			try await Task.sleep(for: .seconds(1)) //Wait a bit until disconnect
			session.disconnect()
			
		} catch {
			customNotificationCentre.shared.new("Import failed: \(error)", level: .destructive)
			session.disconnect()
		} }
	}
	
	
}
