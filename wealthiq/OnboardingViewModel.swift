//
//  OnboardingViewModel.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import Combine
import Foundation
import Speech

enum Gender: String, CaseIterable {
  case female = "Female"
  case male = "Male"
}

enum Mood: String, CaseIterable {
  case calm = "Calm"
  case anxious = "Anxious"
  case focused = "Focused"
  case overwhelmed = "Overwhelmed"
  case optimistic = "Optimistic"
  case conflicted = "Conflicted"
  case determined = "Determined"
  case tired = "Tired"
  case energized = "Energized"
  case stressed = "Stressed"
  case grateful = "Grateful"
  case distracted = "Distracted"
  case curious = "Curious"
  case doubtful = "Doubtful"
  case confident = "Confident"
  case frustrated = "Frustrated"
}

enum GoalRecency: String, CaseIterable {
  case lastWeek = "In the last week"
  case lastMonth = "In the last month"
  case lastYear = "In the last year"
  case cantRemember = "Can’t remember"
}

enum TrajectoryFeeling: String, CaseIterable {
  case calm = "Calm"
  case anxious = "Anxious"
  case focused = "Focused"
  case overwhelmed = "Overwhelmed"
  case optimistic = "Optimistic"
  case conflicted = "Conflicted"
  case determined = "Determined"
}

enum Obstacle: String, CaseIterable, Identifiable {
  case time = "Time"
  case energy = "Energy"
  case clarity = "Clarity"
  case money = "Money"
  case discipline = "Discipline"
  case fear = "Fear"
  case skills = "Skills"
  case supportSystem = "Support system"
  case systems = "Systems/organization"
  case other = "Other"

  var id: String { rawValue }
}

enum CoachingStyle: String, CaseIterable {
  case direct = "Direct & no-BS"
  case dataDriven = "Data-driven & practical"
  case encouraging = "Encouraging & supportive"
  case reflective = "Reflective & mindset-oriented"
}

enum AccountabilityPreference: String, CaseIterable, Identifiable {
  case microNudges = "Daily micro-nudges"
  case checkIns = "2–3x/week check-ins"
  case weeklyReview = "Weekly review"
  case milestoneOnly = "Milestone reminders only"
  case quietMode = "Quiet mode (only critical alerts)"

  var id: String { rawValue }
}

enum MotivationShift: String, CaseIterable {
  case muchMore = "Much more motivated"
  case bitMore = "A bit more motivated"
  case same = "About the same"
  case bitLess = "A bit less motivated"
  case less = "Less motivated"
}

enum OnboardingStep: Int, CaseIterable {
  case gender = 0
  case name = 1
  case age = 2
  case welcomeIntro = 3
  case goalRecency = 4
  case goalWritingInfo = 5
  case primaryGoal = 6
  case goalVisualization = 7
  case visualizationInfo = 8
  case microAction = 9
  case coachingStyle = 10
  case planCalculation = 11

  var totalSteps: Int {
    OnboardingStep.allCases.count
  }
}

class OnboardingViewModel: ObservableObject {
  @Published var currentStep: OnboardingStep = .gender
  @Published var selectedGender: Gender?
  @Published var firstName: String = ""
  @Published var age: String = ""
  @Published var selectedGoalRecency: GoalRecency?
  @Published var primaryGoal: String = ""
  @Published var goalVisualization: String = ""
  @Published var microAction: String = ""
  @Published var selectedCoachingStyle: CoachingStyle?
  @Published var isRecording: Bool = false
  
  // Speech recognition
  let speechManager: SpeechRecognitionManager
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    self.speechManager = SpeechRecognitionManager()
    
    // Subscribe to speechManager's isRecording changes
    speechManager.$isRecording
      .sink { [weak self] isRecording in
        self?.isRecording = isRecording
      }
      .store(in: &cancellables)
    
    // Subscribe to transcribed text changes for real-time updates
    speechManager.$transcribedText
      .sink { [weak self] text in
        self?.updateFieldWithTranscription(text)
      }
      .store(in: &cancellables)
  }

  var progress: Double {
    Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
  }

  var canContinue: Bool {
    switch currentStep {
    case .gender:
      return selectedGender != nil
    case .name:
      return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    case .age:
      return isValidAge
    case .welcomeIntro:
      return true
    case .goalRecency:
      return selectedGoalRecency != nil
    case .goalWritingInfo:
      return true
    case .primaryGoal:
      return !primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .goalVisualization:
      return !goalVisualization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .visualizationInfo:
      return true
    case .microAction:
      return !microAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .coachingStyle:
      return selectedCoachingStyle != nil
    case .planCalculation:
      return true
    }
  }

  func nextStep() {
    guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
      // Onboarding complete
      return
    }
    currentStep = nextStep
  }

  func previousStep() {
    guard let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
      return
    }
    currentStep = previousStep
  }



  func selectGoalRecency(_ recency: GoalRecency) {
    selectedGoalRecency = recency
  }

  var goalRecencyOptions: [GoalRecency] {
    GoalRecency.allCases
  }

  var coachingStyleOptions: [CoachingStyle] {
    CoachingStyle.allCases
  }

  func selectCoachingStyle(_ style: CoachingStyle) {
    selectedCoachingStyle = style
  }
  
  // MARK: - Voice Input Methods
  private var activeRecordingField: OnboardingStep?
  private var textBeforeRecording: String = ""
  
  func toggleVoiceRecording(for field: OnboardingStep) {
    if speechManager.isRecording {
      speechManager.stopRecording()
      activeRecordingField = nil
      textBeforeRecording = ""
    } else {
      activeRecordingField = field
      
      // Store existing text to append to
      switch field {
      case .goalVisualization:
        textBeforeRecording = goalVisualization
      case .microAction:
        textBeforeRecording = microAction
      default:
        textBeforeRecording = ""
      }
      
      // Clear the transcription buffer
      speechManager.clearTranscription()
      speechManager.startRecording()
    }
  }
  
  private func updateFieldWithTranscription(_ transcribedText: String) {
    guard let field = activeRecordingField else { return }
    
    // Combine existing text with new transcription
    let combinedText = textBeforeRecording.isEmpty 
      ? transcribedText 
      : textBeforeRecording + " " + transcribedText
    
    switch field {
    case .goalVisualization:
      goalVisualization = combinedText
    case .microAction:
      microAction = combinedText
    default:
      break
    }
  }

  private var isValidAge: Bool {
    let sanitized = age.filter { $0.isNumber }
    guard let value = Int(sanitized) else {
      return false
    }
    return value > 0 && value <= 120
  }
}
