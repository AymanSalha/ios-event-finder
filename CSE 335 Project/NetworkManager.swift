//
//  NetworkManager.swift
//  CSE 335 Project
//
//  Created by asalha2 on 3/30/25.
//


import Foundation
import CoreLocation

class NetworkManager {
    static let shared = NetworkManager()
    private let apiKey = Secrets.ticketmasterAPIKey
    
    func fetchNearbyEvents(latitude: Double, longitude: Double, radius: Int = 50) async throws -> [Event] {
        let urlString = "https://app.ticketmaster.com/discovery/v2/events.json?apikey=\(apiKey)&latlong=\(latitude),\(longitude)&radius=\(radius)&unit=miles&sort=distance,asc"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Debug: Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(APIResponse.self, from: data)
            return result._embedded?.events ?? []
        } catch {
            print("Decoding error details: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    func searchEvents(query: String, countryCode: String = "US") async throws -> [Event] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://app.ticketmaster.com/discovery/v2/events.json?apikey=\(apiKey)&keyword=\(encodedQuery)&countryCode=\(countryCode)&sort=date,asc"
        
        print("[Network] Searching with URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode)
            }
            
            let result = try JSONDecoder().decode(APIResponse.self, from: data)
            return result._embedded?.events ?? []
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - Response Models
struct APIResponse: Codable {
    let _embedded: EmbeddedEvents?
    let page: PageInfo?
}

struct PageInfo: Codable {
    let totalElements: Int?
}

struct EmbeddedEvents: Codable {
    let events: [Event]?
}

struct Event: Codable, Identifiable {
    let id: String
    let name: String
    let dates: EventDates
    let _embedded: EventVenue?
    let url: String?
    let distance: Double?
    
    var venue: String? {
        _embedded?.venues?.first?.name
    }
    
    var date: String? {
        dates.start.localDate
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        return String(format: "%.1f mi", distance)
    }
    
    var coordinate: CLLocationCoordinate2D {
        if let venue = _embedded?.venues?.first,
           let latString = venue.location?.latitude,
           let lonString = venue.location?.longitude,
           let latitude = Double(latString),
           let longitude = Double(lonString) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    var shareContent: [Any] {
        if let eventUrl = url, let url = URL(string: eventUrl) {
            return ["Check out '\(name)' on Ticketmaster", url]
        }
        return ["Check out '\(name)' at \(venue ?? "unknown venue") on \(date ?? "unknown date")"]
    }
}

struct EventDates: Codable {
    let start: StartDate
    let timezone: String?
}

struct StartDate: Codable {
    let localDate: String?
    let localTime: String?
    let dateTime: String?
}

struct EventVenue: Codable {
    let venues: [Venue]?
    let attractions: [Attraction]?
}

struct Venue: Codable {
    let name: String?
    let type: String?
    let id: String?
    let location: VenueLocation?
    let address: VenueAddress?
}

struct VenueLocation: Codable {
    let latitude: String?
    let longitude: String?
}

struct VenueAddress: Codable {
    let line1: String?
    let line2: String?
    let line3: String?
    let city: City?
}

struct City: Codable {
    let name: String?
}

struct Attraction: Codable {
    let name: String?
    let type: String?
    let id: String?
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse(statusCode: Int?)
    case decodingError(Error)
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse(let statusCode):
            return "Server returned error: \(statusCode ?? 0)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
