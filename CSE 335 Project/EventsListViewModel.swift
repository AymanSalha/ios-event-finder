//
//  EventsListViewModel.swift
//  CSE 335 Project
//
//  Created by asalha2 on 4/18/25.
//

import SwiftUI
import SwiftData

@MainActor
class EventsListViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var searchResults: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSearching = false
    
    private let networkManager = NetworkManager.shared
    private let locationManager = LocationManager()
    
    func fetchNearbyEvents() async {
        isLoading = true
        defer { isLoading = false }
        isSearching = false
        
        do {
            guard let location = locationManager.userLocation else {
                throw LocationError.permissionDenied
            }
            
            print("[Fetch] Loading nearby events...")
            events = try await networkManager.fetchNearbyEvents(
                latitude: location.latitude,
                longitude: location.longitude
            )
            errorMessage = nil
        } catch {
            handleError(error)
        }
    }
    
    func performSearch(query: String) async {
        guard !query.isEmpty else {
            // If search is empty, show nearby events
            await fetchNearbyEvents()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        isSearching = true
        
        do {
            print("[Search] Performing global search for: \(query)")
            searchResults = try await networkManager.searchEvents(query: query)
            errorMessage = nil
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        let errorMsg: String
        
        switch error {
        case is LocationError:
            errorMsg = "Location services unavailable. Please enable in Settings."
        case let networkError as NetworkError:
            errorMsg = networkError.localizedDescription
        default:
            errorMsg = error.localizedDescription
        }
        
        print("[ViewModel] Error: \(errorMsg)")
        errorMessage = errorMsg
        events = []
        searchResults = []
    }
}

enum LocationError: Error {
    case permissionDenied
}
