//
//  EventDetailView.swift
//  CSE 335 Project
//
//  Created by asalha2 on 3/30/25.
//


// EventDetailView.swift
import SwiftUI
import MapKit
import SwiftData

struct EventDetailView: View {
    let event: Event
    @Environment(\.modelContext) private var modelContext
    @State private var isSaved = false
    @State private var showShareSheet = false
    @State private var showReminderSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.name)
                    .font(.title.bold())
                
                HStack {
                    Text(event.venue ?? "Unknown Venue")
                    Spacer()
                    Text(event.date ?? "Date not available")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                // Map View
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: event.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // Wider zoom
                        )
                    )
                ) {
                    Annotation(event.venue ?? "Venue", coordinate: event.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                            .background(.white)
                            .clipShape(Circle())
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button {
                    toggleSave()
                } label: {
                    Label(isSaved ? "Saved" : "Save",
                         systemImage: isSaved ? "heart.fill" : "heart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isSaved ? .red : .blue)
                
                Button("Set Reminder") {
                    showReminderSheet = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("Share") {
                    showShareSheet = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [eventShareContent])
        }
        .sheet(isPresented: $showReminderSheet) {
            EventReminderSheet(event: event)
        }
        .task {
            await checkIfSaved()
        }
    }
    
    private var eventShareContent: String {
        "Check out \(event.name) at \(event.venue ?? "a venue") on \(event.date ?? "a date")"
    }
    
    private func toggleSave() {
        if isSaved {
            deleteEvent()
        } else {
            saveEvent()
        }
        isSaved.toggle()
    }
    
    private func saveEvent() {
        let savedEvent = SavedEvent(
            id: event.id,
            name: event.name,
            date: event.date ?? "Date not available",
            venue: event.venue ?? "Unknown Venue",
            latitude: String(event.coordinate.latitude),
            longitude: String(event.coordinate.longitude)
        )
        modelContext.insert(savedEvent)
    }
    
    private func deleteEvent() {
        let descriptor = FetchDescriptor<SavedEvent>(
            predicate: #Predicate { $0.id == event.id }
        )
        do {
            if let eventToDelete = try modelContext.fetch(descriptor).first {
                modelContext.delete(eventToDelete)
            }
        } catch {
            print("Error deleting event: \(error)")
        }
    }
    
    private func checkIfSaved() async {
        let descriptor = FetchDescriptor<SavedEvent>(
            predicate: #Predicate { $0.id == event.id }
        )
        do {
            let count = try modelContext.fetchCount(descriptor)
            await MainActor.run {
                isSaved = count > 0
            }
        } catch {
            print("Error checking saved status: \(error)")
        }
    }
}

// MARK: - Helper Views

struct EventReminderSheet: View {
    let event: Event
    @State private var reminderDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Remind me at",
                    selection: $reminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
            .navigationTitle("Set Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        Task {
                            try await NotificationManager.shared.scheduleReminder(
                                for: event,
                                at: reminderDate
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
