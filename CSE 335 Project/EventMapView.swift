//
//  EventMapView.swift
//  CSE 335 Project
//
//  Created by asalha2 on 4/18/25.
//


import SwiftUI
import MapKit

struct EventMapView: View {
    let event: Event
    @State private var position: MapCameraPosition
    
    init(event: Event) {
        self.event = event
        
        // Default to SF coordinates if venue not available
        let defaultCoordinate = CLLocationCoordinate2D(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        // Try to get venue coordinates if available
        if let venue = event._embedded?.venues?.first,
           let latString = venue.location?.latitude,
           let lonString = venue.location?.longitude,
           let latitude = Double(latString),
           let longitude = Double(lonString) {
            self._position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))
        } else {
            self._position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: defaultCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            ))
        }
    }
    
    var body: some View {
        Map(position: $position) {
            if let venueName = event._embedded?.venues?.first?.name {
                Annotation(venueName, coordinate: position.region?.center ?? CLLocationCoordinate2D()) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
