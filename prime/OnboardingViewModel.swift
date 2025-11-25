//
//  OnboardingViewModel.swift
//  prime
//
//  Created by Brandon Bevans on 11/10/25.
//

import Combine
import Foundation
import Speech

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
  case welcomeIntro = 0
  case goalRecency = 1
  case goalWritingInfo = 2
  case primaryGoal = 3
  case microAction = 4
  case coachingStyle = 5
  case allDone = 6
  case planCalculation = 7

  var totalSteps: Int {
    OnboardingStep.allCases.count
  }
}

@MainActor
class OnboardingViewModel: ObservableObject {
  @Published var currentStep: OnboardingStep = .welcomeIntro
  @Published var selectedGoalRecency: GoalRecency?
  @Published var primaryGoal: String = ""
  @Published var goalVisualization: String = ""
  @Published var microAction: String = ""
  @Published var selectedCoachingStyle: CoachingStyle?
  @Published var isRecording: Bool = false
  @Published var isSaving: Bool = false
  @Published var saveError: Error?

  // Speech recognition
  let speechManager: SpeechRecognitionManager
  private var cancellables = Set<AnyCancellable>()

  // Supabase integration
  private let supabaseManager = SupabaseManager.shared

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

    // Load any existing onboarding data
    Task {
      await loadExistingOnboardingData()
    }
  }

  /// Load existing onboarding data if user has partial progress
  func loadExistingOnboardingData() async {
    guard await supabaseManager.isAuthenticated() else {
      print("⚠️ No authenticated user - skipping data load")
      return
    }

    do {
      if let profile = try await supabaseManager.fetchUserProfile() {
        print("📥 Loading existing onboarding data...")

        // Restore saved values
        if let recencyString = profile.goalRecency {
          selectedGoalRecency = mapDatabaseToGoalRecency(recencyString)
        }

        primaryGoal = profile.primaryGoal != "Not set yet" ? profile.primaryGoal : ""
        goalVisualization =
          profile.goalVisualization != "Not set yet" ? profile.goalVisualization : ""
        microAction = profile.microAction != "Not set yet" ? profile.microAction : ""

        if let styleString = profile.coachingStyle {
          selectedCoachingStyle = mapDatabaseToCoachingStyle(styleString)
        }

        // If onboarding was completed, start from the beginning anyway
        // (they might want to update their info)
        if profile.onboardingCompleted {
          print("ℹ️ User previously completed onboarding")
        }

        print("✅ Loaded existing progress")
      }
    } catch {
      print("⚠️ Could not load existing data: \(error)")
    }
  }

  private func mapDatabaseToGoalRecency(_ value: String) -> GoalRecency? {
    switch value {
    case "lastWeek": return .lastWeek
    case "lastMonth": return .lastMonth
    case "lastYear": return .lastYear
    case "cantRemember": return .cantRemember
    default: return nil
    }
  }

  private func mapDatabaseToCoachingStyle(_ value: String) -> CoachingStyle? {
    switch value {
    case "direct": return .direct
    case "dataDriven": return .dataDriven
    case "encouraging": return .encouraging
    case "reflective": return .reflective
    default: return nil
    }
  }

  var progress: Double {
    Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
  }

  var canContinue: Bool {
    switch currentStep {
    case .welcomeIntro:
      return true
    case .goalRecency:
      return selectedGoalRecency != nil
    case .goalWritingInfo:
      return true
    case .primaryGoal:
      return !primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .microAction:
      return !microAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .coachingStyle:
      return selectedCoachingStyle != nil
    case .allDone:
      return true
    case .planCalculation:
      return true
    }
  }

  func nextStep() {
    // Stop recording if active before moving to next step
    if speechManager.isRecording {
      speechManager.stopRecording()
      activeRecordingField = nil
      textBeforeRecording = ""
      isRecording = false
    }

    // Save current step data before moving to next
    Task {
      await saveCurrentStepData()
    }

    guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
      // Onboarding complete - final save is handled by PlanCalculationView
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
    let combinedText =
      textBeforeRecording.isEmpty
      ? transcribedText
      : textBeforeRecording + " " + transcribedText

    switch field {
    case .microAction:
      microAction = combinedText
    default:
      break
    }
  }

  // MARK: - Supabase Integration

  /// Save current step data to Supabase (incremental save)
  func saveCurrentStepData() async {
    // Only save if user is authenticated
    guard await supabaseManager.isAuthenticated() else {
      print("⚠️ Skipping save - user not authenticated")
      return
    }

    // Only save if we have meaningful data to save
    switch currentStep {
    case .goalRecency:
      if selectedGoalRecency == nil { return }
    case .primaryGoal:
      if primaryGoal.isEmpty { return }
    case .microAction:
      if microAction.isEmpty { return }
    case .coachingStyle:
      if selectedCoachingStyle == nil { return }
    default:
      return  // Don't save for info screens
    }

    print("💾 Auto-saving progress at step: \(currentStep)")

    do {
      // Save current progress (will upsert if profile already exists)
      _ = try await supabaseManager.saveOnboardingData(
        goalRecency: selectedGoalRecency,
        primaryGoal: primaryGoal.isEmpty ? "Not set yet" : primaryGoal,
        goalVisualization: goalVisualization.isEmpty ? "Not set yet" : goalVisualization,
        microAction: microAction.isEmpty ? "Not set yet" : microAction,
        coachingStyle: selectedCoachingStyle,
        lastCompletedStep: String(describing: currentStep)
      )

      print("✅ Progress saved successfully")
    } catch {
      print("⚠️ Failed to save progress: \(error.localizedDescription)")
      // Don't show error to user for incremental saves
    }
  }

  /// Save onboarding data to Supabase (final save)
  func saveOnboardingData() async {
    isSaving = true
    saveError = nil

    do {
      print("📝 Attempting to save onboarding data...")
      print("  - Goal: \(primaryGoal)")
      print("  - Coaching Style: \(selectedCoachingStyle?.rawValue ?? "nil")")

      // Save to Supabase
      let savedProfile = try await supabaseManager.saveOnboardingData(
        goalRecency: selectedGoalRecency,
        primaryGoal: primaryGoal,
        goalVisualization: goalVisualization,
        microAction: microAction,
        coachingStyle: selectedCoachingStyle
      )

      print("✅ Successfully saved onboarding data")
      print("  - Profile ID: \(savedProfile.id ?? -1)")
      print("  - User ID: \(savedProfile.userId)")

      // Also create a goal record for tracking
      let goal = try await supabaseManager.createGoal(
        goalText: primaryGoal,
        visualizationText: goalVisualization,
        microAction: microAction,
        goalType: "primary"
      )

      print("✅ Created goal with ID: \(goal.id?.uuidString ?? "unknown")")

    } catch let error as NSError {
      saveError = error
      print("❌ Failed to save onboarding data:")
      print("  - Error: \(error.localizedDescription)")
      print("  - Code: \(error.code)")
      print("  - Domain: \(error.domain)")
      print("  - Full error: \(error)")

      // Try to extract more specific error information
      if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error {
        print("  - Underlying error: \(underlyingError)")
      }
    } catch {
      saveError = error
      print("❌ Failed to save onboarding data: \(error)")
    }

    isSaving = false
  }
}

