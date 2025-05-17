// CalendarManager.swift
// Chrono.ai
//
// Created by Mohamed Siedahmed on 5/14/25.

import Foundation
import EventKit

// MARK: - Calendar Manager
class CalendarManager {
    private let eventStore = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                completion(granted)
            }
        }
    }
    
    func createEvent(title: String, startDate: Date?, endDate: Date?, notes: String?) {
        guard let startDate = startDate, let endDate = endDate else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error saving event: \(error.localizedDescription)")
        }
    }
    
    // Additional helper method to fetch existing events
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
