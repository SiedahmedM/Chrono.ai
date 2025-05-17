// ScheduleInputViewController.swift
// Chrono.ai
//
// Created by Mohamed Siedahmed on 5/14/25.

import UIKit
import EventKit

class ScheduleDisplayViewController: UIViewController {
    convenience init(scheduleItems: [ScheduleItem]) {
        self.init()
    }
}

class ScheduleInputViewController: UIViewController {
    
    // UI Elements
    private let inputTextView = UITextView()
    private let submitButton = UIButton()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Services
    private let aiService = AIService()
    private let calendarManager = CalendarManager()
    private let taskManager = TaskManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestCalendarAccess()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Chrono.ai"
        
        // Configure text view
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.layer.borderColor = UIColor.systemGray4.cgColor
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.cornerRadius = 8.0
        inputTextView.font = UIFont.systemFont(ofSize: 16)
        inputTextView.text = "Tell me your schedule..."
        inputTextView.textColor = .placeholderText
        inputTextView.delegate = self
        view.addSubview(inputTextView)
        
        // Configure submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Process Schedule", for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.layer.cornerRadius = 8.0
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        view.addSubview(submitButton)
        
        // Configure loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            inputTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputTextView.heightAnchor.constraint(equalToConstant: 200),
            
            submitButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 200),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 20)
        ])
    }
    
    private func requestCalendarAccess() {
        calendarManager.requestAccess { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Calendar Access Denied", message: "Please enable calendar access in Settings to use this feature.")
                }
            }
        }
        
        taskManager.requestAccess { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Reminders Access Denied", message: "Please enable reminders access in Settings to use this feature.")
                }
            }
        }
    }
    
    @objc private func submitButtonTapped() {
        guard let inputText = inputTextView.text, !inputText.isEmpty, inputText != "Tell me your schedule..." else {
            showAlert(title: "Empty Input", message: "Please describe your schedule first.")
            return
        }
        
        // Start loading
        loadingIndicator.startAnimating()
        submitButton.isEnabled = false
        
        // Process with AI
        aiService.processScheduleInput(inputText) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.submitButton.isEnabled = true
                
                switch result {
                case .success(let scheduleItems):
                    self?.handleScheduleItems(scheduleItems)
                case .failure(let error):
                    self?.showAlert(title: "Processing Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleScheduleItems(_ items: [ScheduleItem]) {
        // Create calendar events and tasks based on the returned items
        for item in items {
            switch item.type {
            case .event:
                calendarManager.createEvent(title: item.title, startDate: item.startDate, endDate: item.endDate, notes: item.notes)
            case .task:
                taskManager.createTask(title: item.title, dueDate: item.dueDate, notes: item.notes)
            }
        }
        
        // Show success and navigate to display view
        showAlert(title: "Schedule Processed", message: "Added \(items.count) items to your calendar/tasks!") { [weak self] _ in
            let displayVC = ScheduleDisplayViewController(scheduleItems: items)
            self?.navigationController?.pushViewController(displayVC, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
}

// MARK: - Text View Delegate
extension ScheduleInputViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Tell me your schedule..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Tell me your schedule..."
            textView.textColor = .placeholderText
        }
    }
}
