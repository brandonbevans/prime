//
//  OnboardingViewModel.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import Combine
import Foundation

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

enum ProcessDifficulty: String, CaseIterable {
  case effortless = "Effortless — answers flowed"
  case thoughtful = "Took some thought"
  case deepReflection = "Deep reflection — worth it"
  case draining = "Draining — too much right now"
}

enum OnboardingStep: Int, CaseIterable {
  case gender = 0
  case name = 1
  case age = 2
  case mood = 3
  case goalRecency = 4
  case goalWritingInfo = 5
  case primaryGoal = 6
  case goalVisualization = 7
  case visualizationInfo = 8
  case microAction = 9
  case trajectoryFeeling = 10
  case obstacles = 11
  case habitReplacement = 12
  case deferredAction = 13
  case habitLawInfo = 14
  case coachingStyle = 15
  case accountability = 16
  case motivationShift = 17
  case postSessionMood = 18
  case processDifficulty = 19
  case planCalculation = 20

  var totalSteps: Int {
    OnboardingStep.allCases.count
  }
}

class OnboardingViewModel: ObservableObject {
  @Published var currentStep: OnboardingStep = .gender
  @Published var selectedGender: Gender?
  @Published var firstName: String = ""
  @Published var age: String = ""
  @Published var selectedMoods: Set<Mood> = []
  @Published var selectedGoalRecency: GoalRecency?
  @Published var primaryGoal: String = ""
  @Published var goalVisualization: String = ""
  @Published var microAction: String = ""
  @Published var selectedTrajectoryFeelings: Set<TrajectoryFeeling> = []
  @Published var selectedObstacles: Set<Obstacle> = []
  @Published var habitToReplace: String = ""
  @Published var deferredAction: String = ""
  @Published var selectedCoachingStyle: CoachingStyle?
  @Published var accountabilityPreferences: Set<AccountabilityPreference> = []
  @Published var motivationShift: MotivationShift?
  @Published var postSessionMoods: Set<Mood> = []
  @Published var processDifficulty: ProcessDifficulty?

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
    case .mood:
      return !selectedMoods.isEmpty
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
    case .trajectoryFeeling:
      return !selectedTrajectoryFeelings.isEmpty
    case .obstacles:
      return !selectedObstacles.isEmpty
    case .habitReplacement:
      return !habitToReplace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .deferredAction:
      return !deferredAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .habitLawInfo:
      return true
    case .coachingStyle:
      return selectedCoachingStyle != nil
    case .accountability:
      return !accountabilityPreferences.isEmpty
    case .motivationShift:
      return motivationShift != nil
    case .postSessionMood:
      return !postSessionMoods.isEmpty
    case .processDifficulty:
      return processDifficulty != nil
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

  func toggleMood(_ mood: Mood) {
    if selectedMoods.contains(mood) {
      selectedMoods.remove(mood)
    } else {
      selectedMoods.insert(mood)
    }
  }

  func isMoodSelected(_ mood: Mood) -> Bool {
    selectedMoods.contains(mood)
  }

  var moodOptions: [Mood] {
    Mood.allCases
  }

  func selectGoalRecency(_ recency: GoalRecency) {
    selectedGoalRecency = recency
  }

  var goalRecencyOptions: [GoalRecency] {
    GoalRecency.allCases
  }

  var trajectoryOptions: [TrajectoryFeeling] {
    TrajectoryFeeling.allCases
  }

  var obstacleOptions: [Obstacle] {
    Obstacle.allCases
  }

  var coachingStyleOptions: [CoachingStyle] {
    CoachingStyle.allCases
  }

  var accountabilityOptions: [AccountabilityPreference] {
    AccountabilityPreference.allCases
  }

  var motivationShiftOptions: [MotivationShift] {
    MotivationShift.allCases
  }

  var difficultyOptions: [ProcessDifficulty] {
    ProcessDifficulty.allCases
  }

  func toggleTrajectoryFeeling(_ feeling: TrajectoryFeeling) {
    if selectedTrajectoryFeelings.contains(feeling) {
      selectedTrajectoryFeelings.remove(feeling)
    } else {
      selectedTrajectoryFeelings.insert(feeling)
    }
  }

  func toggleObstacle(_ obstacle: Obstacle) {
    if selectedObstacles.contains(obstacle) {
      selectedObstacles.remove(obstacle)
    } else {
      selectedObstacles.insert(obstacle)
    }
  }

  func selectCoachingStyle(_ style: CoachingStyle) {
    selectedCoachingStyle = style
  }

  func toggleAccountability(_ preference: AccountabilityPreference) {
    if accountabilityPreferences.contains(preference) {
      accountabilityPreferences.remove(preference)
    } else {
      accountabilityPreferences.insert(preference)
    }
  }

  func selectMotivationShift(_ shift: MotivationShift) {
    motivationShift = shift
  }

  func togglePostSessionMood(_ mood: Mood) {
    if postSessionMoods.contains(mood) {
      postSessionMoods.remove(mood)
    } else {
      postSessionMoods.insert(mood)
    }
  }

  func selectProcessDifficulty(_ difficulty: ProcessDifficulty) {
    processDifficulty = difficulty
  }

  private var isValidAge: Bool {
    let sanitized = age.filter { $0.isNumber }
    guard let value = Int(sanitized) else {
      return false
    }
    return value > 0 && value <= 120
  }
}
