//
//  FavoritesView.swift
//  CSE 335 Project
//
//  Created by asalha2 on 4/18/25.
//


import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query private var savedEvents: [SavedEvent]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    
    var filteredEvents: [SavedEvent] {
        if searchText.isEmpty {
            return savedEvents
        } else {
            return savedEvents.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredEvents.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Saved Events" : "No Results",
                        systemImage: "heart.slash",
                        description: searchText.isEmpty ?
                            Text("Save events to see them here") :
                            Text("Try a different search term")
                    )
                } else {
                    List {
                        ForEach(filteredEvents) { savedEvent in
                            NavigationLink {
                                EventDetailView(event: createEvent(from: savedEvent))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(savedEvent.name)
                                            .font(.headline)
                                        Text("\(savedEvent.date) · \(savedEvent.venue)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        deleteEvent(savedEvent)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                }
            }
            .navigationTitle("Favorites")
        }
    }
    
    private func createEvent(from savedEvent: SavedEvent) -> Event {
        // Create venue location with string coordinates
        let venueLocation = VenueLocation(
            latitude: savedEvent.latitude ?? "37.7749",
            longitude: savedEvent.longitude ?? "-122.4194"
        )
        
        // Create venue with minimal required data
        let venue = Venue(
            name: savedEvent.venue,
            type: nil,
            id: nil,
            location: venueLocation,
            address: nil
        )
        
        // Create event dates with just the date
        let startDate = StartDate(
            localDate: savedEvent.date,
            localTime: nil,
            dateTime: nil
        )
        
        let eventDates = EventDates(
            start: startDate,
            timezone: nil
        )
        
        return Event(
            id: savedEvent.id,
            name: savedEvent.name,
            dates: eventDates,
            _embedded: EventVenue(venues: [venue], attractions: nil),
            url: savedEvent.eventURL,
            distance: nil
        )
    }
    
    private func deleteEvent(_ event: SavedEvent) {
        modelContext.delete(event)
    }
}
