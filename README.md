# Nearby Events — iOS Event Finder

A native iOS app in **Swift / SwiftUI** that finds live events near the user, shows them on a map,
and lets the user save favorites and schedule reminders. Built solo for CSE 335 (Principles of Mobile
Application Development) at Arizona State University, Spring 2025.

## Features
- **Nearby events:** uses Core Location to get the user's position and queries the Ticketmaster Discovery API for events sorted by distance.
- **Global search:** keyword search across events by country.
- **Map view:** MapKit annotations for each event.
- **Event details:** venue, date and links.
- **Favorites:** saved locally with SwiftData.
- **Reminders:** local notifications scheduled with UserNotifications.

## Architecture
MVVM with SwiftUI views (`EventsListView`, `EventMapView`, `EventDetailView`, `FavoritesView`, `ReminderSheet`),
an `EventsListViewModel`, and separate managers for networking (async/await + Codable), location and notifications.

## Run it
1. Get a free API key from the [Ticketmaster Developer Portal](https://developer.ticketmaster.com/).
2. Copy `CSE 335 Project/Secrets.swift.example` to `CSE 335 Project/Secrets.swift` and paste in your key.
3. Open `CSE 335 Project.xcodeproj` in Xcode and run on a simulator or device (allow location access).

## Demo
<!-- Add your demo video link or a GIF here -->

*Ayman Salha*
