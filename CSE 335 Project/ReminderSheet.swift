//
//  ReminderSheet.swift
//  CSE 335 Project
//
//  Created by asalha2 on 4/18/25.
//

import SwiftUI

struct ReminderSheet: View {
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
