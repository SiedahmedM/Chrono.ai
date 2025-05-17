// AIService.swift
// Chrono.ai
//
// Created by Mohamed Siedahmed on 5/14/25.

import Foundation

class AIService {
    // OpenAI API configuration
    private func getAPIKey() -> String {
        // Replace with your actual OpenAI API key
        return "API Key"
    }
    
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    func processScheduleInput(_ input: String, completion: @escaping (Result<[ScheduleItem], Error>) -> Void) {
        // Prepare the API request with system prompt that instructs the AI how to format the response
        let systemPrompt = """
        Parse the user's schedule description into structured events and tasks. 
        For each item, determine if it's an event (with start/end time) or a task (with optional due date).
        Respond in JSON format like this:
        {
          "items": [
            {
              "type": "event",
              "title": "Meeting with John",
              "startDate": "2025-05-14T10:00:00",
              "endDate": "2025-05-14T11:00:00",
              "notes": "Discuss project timeline"
            },
            {
              "type": "task",
              "title": "Buy groceries",
              "dueDate": "2025-05-14T18:00:00",
              "notes": "Milk, eggs, bread"
            }
          ]
        }
        """
        
        // Create the OpenAI API request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "temperature": 0.2
        ]
        
        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Execute request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received from API")
                completion(.failure(NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: Print response for troubleshooting
            if let responseString = String(data: data, encoding: .utf8) {
                print("OpenAI API Response: \(responseString)")
            }
            
            // Check for error in response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = json["error"] as? [String: Any],
               let errorMessage = errorInfo["message"] as? String {
                print("API Error: \(errorMessage)")
                completion(.failure(NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMessage)"])))
                return
            }
            
            do {
                // Parse the OpenAI API response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Extract the JSON portion from the response
                    if let jsonStartIndex = content.range(of: "{")?.lowerBound,
                       let jsonEndIndex = content.range(of: "}", options: .backwards)?.upperBound {
                        
                        let jsonString = String(content[jsonStartIndex..<jsonEndIndex])
                        
                        if let jsonData = jsonString.data(using: .utf8),
                           let parsedJson = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let items = parsedJson["items"] as? [[String: Any]] {
                            
                            // Convert JSON items to ScheduleItem objects
                            let scheduleItems = items.compactMap { itemJson -> ScheduleItem? in
                                guard let title = itemJson["title"] as? String,
                                      let typeString = itemJson["type"] as? String else {
                                    return nil
                                }
                                
                                let type: ScheduleItemType = typeString == "event" ? .event : .task
                                let notes = itemJson["notes"] as? String
                                
                                let dateFormatter = ISO8601DateFormatter()
                                
                                var startDate: Date? = nil
                                var endDate: Date? = nil
                                var dueDate: Date? = nil
                                
                                if let startDateString = itemJson["startDate"] as? String {
                                    startDate = dateFormatter.date(from: startDateString)
                                }
                                
                                if let endDateString = itemJson["endDate"] as? String {
                                    endDate = dateFormatter.date(from: endDateString)
                                }
                                
                                if let dueDateString = itemJson["dueDate"] as? String {
                                    dueDate = dateFormatter.date(from: dueDateString)
                                }
                                
                                return ScheduleItem(
                                    title: title,
                                    type: type,
                                    startDate: startDate,
                                    endDate: endDate,
                                    dueDate: dueDate,
                                    notes: notes
                                )
                            }
                            
                            completion(.success(scheduleItems))
                            return
                        }
                    }
                    
                    // If we can't find or parse JSON in the response
                    completion(.failure(NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response JSON structure: \(content)"])))
                } else {
                    completion(.failure(NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])))
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
