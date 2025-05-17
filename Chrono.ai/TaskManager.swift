// TaskManager.swift
// Chrono.ai
//
// Created by Mohamed Siedahmed on 5/14/25.

import Foundation
import EventKit

// MARK: - Task Manager
class TaskManager {
    private let eventStore = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                completion(granted)
            }
        }
    }
    
    func createTask(title: String, dueDate: Date?, notes: String?) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        
        if let dueDate = dueDate {
            // Set due date with time components
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error saving reminder: \(error.localizedDescription)")
        }
    }
    
    // Additional helper method to fetch reminders
    func fetchReminders(completion: @escaping ([EKReminder]?) -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            completion(reminders)
        }
    }
}
