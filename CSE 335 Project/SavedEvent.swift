//
//  SavedEvent.swift
//  CSE 335 Project
//
//  Created by asalha2 on 3/30/25.
//


// SavedEvent.swift
import SwiftData
import Foundation

@Model
final class SavedEvent {
    var id: String
    var name: String
    var date: String
    var venue: String
    var latitude: String?
    var longitude: String?
    var eventURL: String?
    
    init(id: String, name: String, date: String, venue: String, latitude: String? = nil, longitude: String? = nil, eventURL: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.venue = venue
        self.latitude = latitude
        self.longitude = longitude
        self.eventURL = eventURL
    }
}
