//
//  Notifications.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 20.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//



import SwiftUI



///NOTE: In hindsight this whole notification system is not very useful. It was originally meant to give the User more visual feedback when he copies an Idea to the clipboard and was then just also used for other things for the sake of consistency. It will maybe be removed in future versions of the app.



enum NotificationLevel {
    case standart
    case important
    case destructive
	case technical
}



class customNotification: Identifiable, Equatable {
	
	//Content
    let title: String
    let level: NotificationLevel
    
    //Meta
    let id = UUID()
    let duration: TimeInterval
    
    init(title: String, duration: TimeInterval, level: NotificationLevel = .standart) {
        self.title = title
        self.level = level
        self.duration = duration
    }
    
    //I cannot believe swift requires this
    static func == (lhs: customNotification, rhs: customNotification) -> Bool {
            return lhs.id == rhs.id
        }
}



//standart notification duration in seconds
private let standartNotificationDuration: TimeInterval = 3



class customNotificationCentre: ObservableObject {
	
	static var shared = customNotificationCentre()
	
    @Published var notifications: [customNotification] = []

	func new(_ title: String, duration: TimeInterval = standartNotificationDuration, level: NotificationLevel = .standart) {
		
		let newNotification = customNotification(title: title, duration: duration, level: level)
		notifications.insert(newNotification, at: 0)
		
		//Remove after certain timeframe
		DispatchQueue.main.asyncAfter(deadline: .now() + newNotification.duration) {
			withAnimation(standartAnimation) {
				self.notifications.removeAll { $0 == newNotification }
			}
		}
		
	}
}



struct NotificationView: View {
    
    let notification: customNotification
    
    var body: some View {
        ZStack {
            
            //Defining color depending on notification level
            let color: Color = switch notification.level {
            case .standart: .blue
            case .important: .teal
            case .destructive: .red
			case .technical: .orange
            }
            
            Text(notification.title)
                .padding(7)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: standartPadding*2))
                .foregroundStyle(color.opacity(0.5))
			
                .padding(.bottom, standartPadding)
        }
    }
}



//This View is on top of the whole App
struct NotificationOverlay: View {
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
			ForEach(customNotificationCentre.shared.notifications) { notification in
                NotificationView(notification: notification)
            }
        }
        .padding(standartPadding)
		.allowsHitTesting(false)
    }
}



#Preview {
    @Previewable @State var settingsOpened = false
    @Previewable @State var clipBoard: Idea? = nil
    
    ZStack {
        ContentView()
        
        VStack(spacing: 0) {
            Spacer(minLength: 7)
            
            //Standart
            NotificationView(notification: customNotification(title: "This is a normal test notification", duration: 1, level: .standart))
            
            //Important
            NotificationView(notification: customNotification(title: "This is an important test notification", duration: 1, level: .important))
            
            //Destructive
            NotificationView(notification: customNotification(title: "This is a destructive test notification", duration: 1, level: .destructive))
                .padding(.bottom, standartPadding)
        }
    }
}
