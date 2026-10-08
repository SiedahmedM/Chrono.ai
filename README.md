# Chrono.ai

A native iOS scheduling experiment that turns a written description of your day into calendar events and reminders. The code connects a UIKit input screen, an OpenAI request, and Apple's EventKit APIs. The checked-in project still needs cleanup before it is ready to run end to end.

## The scheduling path

[SceneDelegate](Chrono.ai/SceneDelegate.swift) opens `ScheduleInputViewController` inside a navigation controller. The screen requests calendar and reminder permissions, then passes the user's text to [AIService](Chrono.ai/AIService.swift).

The service calls OpenAI's chat completions endpoint with `gpt-3.5-turbo` and asks for JSON containing titles, item types, dates, and notes. It parses that response into `ScheduleItem` values. [CalendarManager](Chrono.ai/CalendarManager.swift) saves events, and [TaskManager](Chrono.ai/TaskManager.swift) saves reminders through EventKit.

The current flow attempts to save items immediately after parsing. It does not include a review step before writing to the calendar.

## Working on the project

Open `Chrono.ai.xcodeproj` in Xcode on macOS. The app target specifies iOS 16.2; the test targets specify iOS 18.2. The implementation uses Swift, UIKit, Foundation, and EventKit without third-party package dependencies.

Before running the full flow, resolve the duplicate `ScheduleDisplayViewController`, `ScheduleItem`, and `ScheduleItemType` declarations across the input, display, and model files. The display controller's filename also ends in a space, which prevents a normal Windows checkout.

`AIService.getAPIKey()` currently returns a placeholder. API configuration is still local prototype code, with requests sent directly from the device. Keep test credentials out of commits and verify the configured model is available to your account.

## Status

Input handling, response parsing, and EventKit writes are present. Date parsing and save failures need further handling: the success alert counts parsed items even when an event is skipped or a save fails. The Core Data model is empty, and the test targets contain starter tests rather than scheduling coverage.
