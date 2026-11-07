//
//  EventsListView.swift
//  CSE 335 Project
//
//  Created by asalha2 on 3/30/25.
//


// EventsListView.swift
import SwiftUI
import SwiftData

struct EventsListView: View {
    @StateObject private var viewModel = EventsListViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    
    var displayedEvents: [Event] {
        viewModel.isSearching ? viewModel.searchResults : viewModel.events
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading events...")
                } else if let error = viewModel.errorMessage {
                    errorView(error: error)
                } else if displayedEvents.isEmpty {
                    emptyContentView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Upcoming Events")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onSubmit(of: .search) {
                Task {
                    await viewModel.performSearch(query: searchText)
                }
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    Task {
                        await viewModel.fetchNearbyEvents()
                    }
                }
            }
            .refreshable {
                await viewModel.fetchNearbyEvents()
            }
            .task(priority: .userInitiated) {
                await viewModel.fetchNearbyEvents()
            }
        }
    }
    
    @ViewBuilder
    private func errorView(error: String) -> some View {
        VStack {
            Text("Error: \(error)")
                .foregroundColor(.red)
            Button("Retry") {
                Task {
                    if searchText.isEmpty {
                        await viewModel.fetchNearbyEvents()
                    } else {
                        await viewModel.performSearch(query: searchText)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyContentView: some View {
        ContentUnavailableView(
            viewModel.isSearching ? "No Results Found" : "No Nearby Events",
            systemImage: viewModel.isSearching ? "magnifyingglass" : "location.slash",
            description: viewModel.isSearching ?
                Text("Try a different search term") :
                Text("Try moving to a different location")
        )
    }
    
    @ViewBuilder
    private var eventsList: some View {
        List(displayedEvents) { event in
            HStack {
                NavigationLink {
                    EventDetailView(event: event)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.headline)
                        
                        if let distance = event.formattedDistance {
                            Text("\(event.date ?? "Date not available") · \(event.venue ?? "Venue not available") · \(distance)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(event.date ?? "Date not available") · \(event.venue ?? "Venue not available")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    toggleSave(event: event)
                } label: {
                    Image(systemName: isSaved(event: event) ? "heart.fill" : "heart")
                        .foregroundColor(isSaved(event: event) ? .red : .gray)
                }
                .buttonStyle(.plain)
            }
        }    }
    
    private func isSaved(event: Event) -> Bool {
        let predicate = #Predicate<SavedEvent> { $0.id == event.id }
        let descriptor = FetchDescriptor(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }
    
    private func toggleSave(event: Event) {
        if isSaved(event: event) {
            deleteEvent(event: event)
        } else {
            saveEvent(event: event)
        }
    }
    
    private func saveEvent(event: Event) {
        let savedEvent = SavedEvent(
            id: event.id,
            name: event.name,
            date: event.date ?? "Date not available",
            venue: event.venue ?? "Venue not available",
            latitude: String(event.coordinate.latitude),
            longitude: String(event.coordinate.longitude),
            eventURL: event.url
        )
        modelContext.insert(savedEvent)
    }
    
    private func deleteEvent(event: Event) {
        let predicate = #Predicate<SavedEvent> { $0.id == event.id }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let eventToDelete = try? modelContext.fetch(descriptor).first {
            modelContext.delete(eventToDelete)
        }
    }
}
