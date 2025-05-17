// ScheduleItem.swift
// Chrono.ai
//
// Created by Mohamed Siedahmed on 5/14/25.

import Foundation

// MARK: - Schedule Data Models
enum ScheduleItemType {
    case event // Calendar event
    case task  // Reminder/todo item
}

struct ScheduleItem {
    let id = UUID()
    let title: String
    let type: ScheduleItemType
    let startDate: Date?
    let endDate: Date?
    let dueDate: Date?
    let notes: String?
}
