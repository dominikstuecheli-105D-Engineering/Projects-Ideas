//
//  ContentView.swift
//  Projects&Ideas
//
//  Created by Dominik Stücheli on 02.07.2025.
//  Copyright © 2025 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



struct ContentView: View {
    @Environment(\.modelContext) var modelContext
	
	@Query(sort: \Project.timestamp, order: .reverse) var projects: [Project]
	
	//FILTER LOGIC
	@State var searchText: String = ""
	@State var filteredProjects: [Project] = []
	
	private func filterProjects() {
		DispatchQueue.main.async {
			filteredProjects = []
			if searchText == "" {filteredProjects = projects; return} //If the filter is empty
			
			for project in projects {
				if project.title.contains(searchText) {
					filteredProjects.append(project) //If the title contains the filter text
				} else if project.tags.contains(where: {$0.tag.title.contains(searchText)}) {
					filteredProjects.append(project) //If any of the projects tags contain the filter text
				}
			}
		}
	}
	
	private func projectsFilteredByTag(_ tag: Tag) -> [Project] {
		return filteredProjects.filter({$0.tags.contains(where: {$0.tag == tag})})
	}
	
	@State var categoriseByTags: Bool = false
	@State var selection: UUID? //Which page is selected to be open
	@State var openedPage: UUID? //Which page is actually open
	@State var isLoadingView: Bool = false
	
	private func openPage(id: UUID?) {
		RenderAllowanceController.shared.fullRenderAllowed = false
		isLoadingView = true
		openedPage = nil
		DispatchQueue.main.async {openedPage = id; RenderAllowanceController.shared.queryInitiationTimePoint = .now}
	}
	
	@State var clipBoard: Idea? = nil //App wide clipboard
	
	//The Helpview also gets an ID to integrate well with the id based project selection
	let helpViewId = UUID()
	
	//TOTAL VIEW RELOADING LOGIC
	//View reloading code for proper View updating on UISize changes
	@State private var isChangingUISize: Bool = false
	@State private var reloadWorkItem: DispatchWorkItem?
	
	private func scheduleViewReload() {
		reloadWorkItem?.cancel()
		let lastOpenedPage: UUID? = openedPage
		isChangingUISize = true
		
		reloadWorkItem = DispatchWorkItem {
			DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
				isChangingUISize = false
				openPage(id: lastOpenedPage)
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: reloadWorkItem!)
	}
	
	//STATE VALUES
	@State var importWindowOpen: Bool = false
    
	//Viewcode
    var body: some View {
        NavigationSplitView {
			
			List(selection: $selection) {
				
				//All Tags
				if categoriseByTags && ModelContextManager.shared.globalUserSettings != nil {
					ForEach(ModelContextManager.shared.globalUserSettings!.tagCollection.sorted(by: {$0.timestamp < $1.timestamp})) { tag in
						
						let projectList = projectsFilteredByTag(tag)
						if projectList.count > 0 {
							Section(tag.title, isExpanded: Binding(
								get: {return tag.isExpandedInSidebar},
								set: {bool in tag.isExpandedInSidebar = bool})) {
									ForEach(projectList.sorted{$0.timestamp > $1.timestamp}) { project in
										NavigationLink(value: project.id) {SideBarTitle(project: project, primaryTag: tag)}
									}
								}
						}
					}
					
					//Projects without Tags
					let projectsWithNoTagList = filteredProjects.filter({$0.tags.count == 0})
					if projectsWithNoTagList.count > 0 {
						Section("No tag") {
							ForEach(projectsWithNoTagList.sorted{$0.timestamp > $1.timestamp}) { project in
								NavigationLink(value: project.id) {SideBarTitle(project: project)}
							}
						}
					}
					
				} else {
					Section("Projects") {
						ForEach(filteredProjects.sorted{$0.timestamp > $1.timestamp}) { project in
							NavigationLink(value: project.id) {SideBarTitle(project: project)}
						}
					}
				}
				
				Section("Other") {
					NavigationLink(value: helpViewId) {Text("Help")}
				}
			}
			//Search field an filter updates
			.searchable(text: $searchText, placement: .sidebar, prompt: "Search Projects or tags")
			.onChange(of: searchText) {filterProjects()}
			.onAppear {filterProjects()}
            
            .navigationSplitViewColumnWidth(min: 220, ideal: 220)
			.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
			
			//If the selection changes, do the whole view reloading
			.onChange(of: selection) { _, new in if new != nil {
				ModelContextManager.shared.globalUserSettings?.lastOpenedProject = (new == helpViewId ? nil : new) //Update the values in the GlobalUserSettings object
				ModelContextManager.shared.save()
				openPage(id: new)
			} }
			
			.onChange(of: categoriseByTags) { _, new in
				ModelContextManager.shared.globalUserSettings?.categoriseByTags = new
			}
			
			.onChange(of: projects.count) { _,_ in filterProjects()}
            
            //TOOLBAR
			.toolbar {
				
				//Add new Project
				ToolbarItem {  Button {
					withAnimation {
						newProject()
						customNotificationCentre.shared.new("Created new Project: for help, got to Help page", duration: 10, level: .important)
					}
				} label: {
					Label("Add Project", systemImage: "plus")
				} }
				
				//Button to open the import window for project import via json
				ToolbarItem {  Button {
					importWindowOpen.toggle()
				} label: {
					Label("Import Project", systemImage: "folder")
				} }
				
				//Toggle for categorising by tags
				ToolbarItem {
					Toggle(isOn: $categoriseByTags) {
						Label("Categorise by tags", systemImage: categoriseByTags ? "tag.fill" : "tag")
					}
				}
			}
			
			//PROJECT IMPORT VIA JSON
			//Drag&Drop
			.dropDestination(for: URL.self) { urls,_ in
				for url in urls {
					Task { do {
						let project = try await decodeProjectFromJson(url: url, to: modelContext)
						selection = project.id
					} catch {
						customNotificationCentre.shared.new("Import failed: \(error)", level: .destructive)
					} }
				}; return true
			}
			
			//Manual import
			.fileImporter(isPresented: $importWindowOpen, allowedContentTypes: [.json]) { result in
				Task { do {
					let url = try result .get()
					let project = try await decodeProjectFromJson(url: url, to: modelContext)
					selection = project.id
				} catch {
					customNotificationCentre.shared.new("Import failed: \(error)", level: .destructive)
				} }
			}
			
        } detail: {
			
			Group {
				//PROJECTVIEW
				if let viewedProject = projects.first(where: {$0.id == openedPage}) {
					Projectview(project: viewedProject, clipBoard: $clipBoard) {scheduleViewReload()}
						.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
						.task {
							isLoadingView = false
							RenderAllowanceController.shared.startRender(forProject: viewedProject)
						}
					
				//HELPVIEW
				} else if openedPage == helpViewId {
					Helpview()
						.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
						.task {isLoadingView = false; RenderAllowanceController.shared.fullRenderAllowed = true}
					
				//LOADING SCREEN
				} else if isLoadingView {
					ProjectLoadingScreen()
						.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
					
				//PLACEHOLDER IF NO PROJECT IS OPEN
				} else {
					NoProjectPlaceholder() .task {isLoadingView = false}
				}
			}
			#if os(macOS)
			.opacity((isLoadingView || !RenderAllowanceController.shared.fullRenderAllowed) && selection != nil ? 0.2 : 1)
			#else
			.opacity((isLoadingView || !RenderAllowanceController.shared.fullRenderAllowed) && selection != nil ? 0.3 : 1)
			#endif
			
			.overlay(alignment: .center) { if (isLoadingView || !RenderAllowanceController.shared.fullRenderAllowed) && selection != nil {
				ProjectLoadingScreen()
					.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
			} }
			
			//ACCESSIBILITY TOOLBAR
			.toolbar {
				
				ToolbarItemGroup {
					//Smaller
					Button {
						ModelContextManager.shared.globalUserSettings?.UISize.smaller()
						scheduleViewReload()
					} label: { Label("Smaller", systemImage: "minus") }
					
					//Size
					Text("\(ModelContextManager.shared.globalUserSettings?.UISize.sizeValue ?? 0)px")
						.foregroundStyle(isChangingUISize ? .red : toolbarItemColor())
					
					//Larger
					Button {
						ModelContextManager.shared.globalUserSettings?.UISize.larger()
						scheduleViewReload()
					} label: { Label("Larger", systemImage: "plus") }
				}
			}
		}
		
		//"Start" the modelContextManager
		.task {
			ModelContextManager.shared.setToContext(modelContext)
			//Only open last opened project if it actually exists, without this the render allowance controller tries to load something that doesnt exist
			let newSelection = ModelContextManager.shared.globalUserSettings?.lastOpenedProject
			if projects.contains(where: {$0.id == newSelection}) {self.selection = newSelection}
			self.categoriseByTags = ModelContextManager.shared.globalUserSettings!.categoriseByTags
			
			//Dont mind this random thing here
			PeerConnectionController.shared.changeProjectSelection = {id in selection = id}
		}
		
		//Peer-to-Peer invitation
		.alert(PeerConnectionController.shared.invitationTitle(), isPresented: Binding(
			get: {return PeerConnectionController.shared.receivedInvite},
			set: { _ in })) {
				Button(role: .none) {
					//Accept invitation
					PeerConnectionController.shared.handleInvite(accept: true)
				} label: {
					Text("Accept")
				}
				Button(role: .cancel) {
					//Decline invitation
					PeerConnectionController.shared.handleInvite(accept: false)
				} label: {
					Text("Cancel")
				}
			} message: {
				Text(PeerConnectionController.shared.receivedDataContext.asString())
			}
		
		//Peer-to-Peer connection select sheet
		.sheet(isPresented: Binding(get: {return PeerConnectionController.shared.isBrowsing},
									set: {setVar in PeerConnectionController.shared.setIsBrowsing(to: setVar)})) {
			PeerSearchSheet()
				.environment(ModelContextManager.shared.unwrappedGlobalUserSettings())
		}
		
    }
    
    func newProject() {
		let project = Project()
		modelContext.insert(project)
		project.buckets.append(Bucket(title: "new Bucket", position: 1))
		selection = project.id
    }
}



#Preview {
    ContentView() .modelContainer(for: [Project.self, GlobalUserSettings.self])
}
