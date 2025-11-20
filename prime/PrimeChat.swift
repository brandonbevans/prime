//
//  PrimeChat.swift
//  prime
//
//  Copied from ElevenLabs ConversationalAISwift example:
//  https://github.com/elevenlabs/elevenlabs-examples/tree/main/examples/conversational-ai/swift/ConversationalAISwift
//

import SwiftUI
import ElevenLabs
import Combine
import LiveKit
import AVFoundation
import AVFAudio

// MARK: - Connection State

enum ConnectionState {
  case idle
  case connecting
  case active
  case reconnecting
  case disconnected
}

// MARK: - Orb UI with Agent State Animation

struct AnimatedOrbView: View {
  let agentState: ElevenLabs.AgentState
  var size: CGFloat = 160 // Default size
  @State private var pulseAmount: CGFloat = 1.0
  @State private var rotation: Double = 0
  
  var body: some View {
    ZStack {
      glowRings
      mainOrb
      shimmerEffect
      stateIcon
    }
    .frame(width: size, height: size)
    .onAppear {
      startAnimation()
    }
    .onChange(of: agentState) { _, _ in
      startAnimation()
    }
  }
  
  private var glowRings: some View {
    ForEach(0..<3) { index in
      Circle()
        .stroke(lineWidth: 2)
        .foregroundStyle(ringGradient)
        .frame(width: size + CGFloat(index) * (size * 0.2), height: size + CGFloat(index) * (size * 0.2))
        .scaleEffect(pulseAmount + CGFloat(index) * 0.1)
        .opacity(1.0 - Double(index) * 0.3)
    }
  }
  
  private var ringGradient: LinearGradient {
    LinearGradient(
      colors: [
        Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.6),
        Color.purple.opacity(0.3)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
  
  private var mainOrb: some View {
    Circle()
      .fill(orbGradient)
      .frame(width: size, height: size)
      .shadow(color: Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.5), radius: size * 0.125, x: 0, y: size * 0.06)
      .scaleEffect(pulseAmount)
  }
  
  private var orbGradient: RadialGradient {
    RadialGradient(
      colors: [
        Color(red: 0.5, green: 0.3, blue: 1.0),
        Color(red: 0.39, green: 0.27, blue: 0.92),
        Color(red: 0.3, green: 0.2, blue: 0.7)
      ],
      center: .topLeading,
      startRadius: 0,
      endRadius: size * 0.625
    )
  }
  
  private var shimmerEffect: some View {
    Circle()
      .fill(shimmerGradient)
      .frame(width: size * 0.6, height: size * 0.6)
      .rotationEffect(.degrees(rotation))
      .blur(radius: size * 0.05)
  }
  
  private var shimmerGradient: AngularGradient {
    AngularGradient(
      colors: [
        .white.opacity(0.8),
        .clear,
        .white.opacity(0.4),
        .clear
      ],
      center: .center
    )
  }
  
  private var stateIcon: some View {
    Image(systemName: iconName)
      .font(.system(size: size * 0.2, weight: .semibold))
      .foregroundColor(.white)
      .scaleEffect(pulseAmount)
  }
  
  private var iconName: String {
    switch agentState {
    case .listening:
      return "waveform"
    case .speaking:
      return "speaker.wave.3.fill"
    case .thinking:
      return "brain"
    default:
      return "waveform"
    }
  }
  
  private var animationSpeed: Double {
    switch agentState {
    case .listening:
      return 2.0
    case .speaking:
      return 0.8
    case .thinking:
      return 1.5
    default:
      return 2.0
    }
  }
  
  private var pulseRange: (min: CGFloat, max: CGFloat) {
    switch agentState {
    case .listening:
      return (0.95, 1.05)
    case .speaking:
      return (0.9, 1.15)
    case .thinking:
      return (0.92, 1.08)
    default:
      return (0.95, 1.05)
    }
  }
  
  private func startAnimation() {
    // Pulse animation
    withAnimation(
      .easeInOut(duration: animationSpeed)
      .repeatForever(autoreverses: true)
    ) {
      pulseAmount = pulseRange.max
    }
    
    // Rotation animation for shimmer
    withAnimation(
      .linear(duration: 4)
      .repeatForever(autoreverses: false)
    ) {
      rotation = 360
    }
  }
}

// MARK: - Conversation ViewModel (using latest ElevenLabs Swift SDK)

@MainActor
final class OrbConversationViewModel: ObservableObject {
  @Published var conversation: Conversation?
  @Published var isConnected: Bool = false
  @Published var isSpeaking: Bool = false
  @Published var audioLevel: Float = 0.0
  @Published var connectionState: ConnectionState = .idle
  @Published var errorMessage: String?
  @Published var isInteractive: Bool = false
  @Published var userProfile: SupabaseManager.UserProfile?
  @Published var microphoneDenied: Bool = false
  @Published var isArchivingSession: Bool = false
  @Published var lastArchiveError: String?
  
  private var cancellables = Set<AnyCancellable>()
  private let audioSession = AVAudioSession.sharedInstance()
  private var lastConversationStartDate: Date?
  private var archivedConversationIds = Set<String>()
  
  func loadUserProfile() async {
    do {
      userProfile = try await SupabaseManager.shared.fetchUserProfile()
      print("✅ Loaded user profile: \(userProfile?.firstName ?? "Unknown")")
    } catch {
      print("⚠️ Failed to load user profile: \(error)")
      errorMessage = "Failed to load profile data"
    }
  }
  
  func toggleConversation(agentId: String) async {
    if isConnected {
      await endConversation()
    } else {
      await startConversation(agentId: agentId)
    }
  }
  
  private func startConversation(agentId: String) async {
    connectionState = .connecting
    errorMessage = nil
    lastArchiveError = nil
    isArchivingSession = false
    
    do {
      let hasPermission = await requestMicrophonePermission()
      guard hasPermission else {
        microphoneDenied = true
        connectionState = .idle
        errorMessage = "Microphone access is required to talk to your coach."
        return
      }
      
      try configureAudioSession()
      
      // Prepare dynamic variables to pass to the agent
      var dynamicVariables: [String: String] = [:]
      
      // Add firstname from user profile if available
      if let firstName = userProfile?.firstName {
        dynamicVariables["firstname"] = firstName
        print("📤 Passing dynamic variable to agent: firstname = \(firstName)")
      }
      
      // Add primary goal from user profile if available
      if let primaryGoal = userProfile?.primaryGoal {
        dynamicVariables["primary_goal"] = primaryGoal
        print("📤 Passing dynamic variable to agent: primary_goal = \(primaryGoal)")
      }
      
      // Add coaching style from user profile if available
      if let coachingStyle = userProfile?.coachingStyle {
        dynamicVariables["coaching_style"] = coachingStyle
        print("📤 Passing dynamic variable to agent: coaching_style = \(coachingStyle)")
      }
      
      let config = ConversationConfig(
        conversationOverrides: ConversationOverrides(textOnly: false),
        dynamicVariables: dynamicVariables
      )
      
      let conv = try await ElevenLabs.startConversation(
        agentId: agentId,
        config: config
      )
      
      conversation = conv
      lastConversationStartDate = Date()
      isInteractive = true
      setupObservers(for: conv)
    } catch {
      print("Error starting conversation: \(error)")
      errorMessage = error.localizedDescription
      connectionState = .disconnected
    }
  }
  
  func endConversation() async {
    await conversation?.endConversation()
    conversation = nil
    isConnected = false
    isSpeaking = false
    audioLevel = 0.0
    connectionState = .idle
    isInteractive = false
    cancellables.removeAll()

    Task { [weak self] in
      await self?.archiveMostRecentConversation()
    }
  }
  
  private func setupObservers(for conversation: Conversation) {
    // Connection state → isConnected and connectionState
    conversation.$state
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .active:
          self?.isConnected = true
          self?.connectionState = .active
        case .connecting:
          self?.isConnected = false
          self?.connectionState = .connecting
        default:
          self?.isConnected = false
          self?.connectionState = .idle
        }
      }
      .store(in: &cancellables)
    
    // Agent state → speaking / listening + simple audio level
    conversation.$agentState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] agentState in
        guard let self else { return }
        switch agentState {
        case .listening:
          self.isSpeaking = false
          self.audioLevel = 0.1
        case .speaking:
          self.isSpeaking = true
          self.audioLevel = 0.7
        case .thinking:
          self.isSpeaking = true
          self.audioLevel = 0.5
        default:
          break
        }
      }
      .store(in: &cancellables)
  }
  
  private func requestMicrophonePermission() async -> Bool {
    if #available(iOS 17.0, *) {
      return await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermissionWithCompletionHandler { granted in
          continuation.resume(returning: granted)
        }
      }
    }

    return await withCheckedContinuation { continuation in
      audioSession.requestRecordPermission { granted in
        continuation.resume(returning: granted)
      }
    }
  }
  
  private func configureAudioSession() throws {
    let currentCategory = audioSession.category
    let requiredCategory: AVAudioSession.Category = .playAndRecord
    let requiredMode: AVAudioSession.Mode = .voiceChat
    
    if currentCategory != requiredCategory || audioSession.mode != requiredMode {
      try audioSession.setCategory(
        requiredCategory,
        mode: requiredMode,
        options: [.allowBluetoothHFP, .defaultToSpeaker]
      )
    }
    
    if !audioSession.isOtherAudioPlaying {
      try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
    } else {
      try audioSession.setActive(true)
    }
  }

  // MARK: - Session Archiving

  private func archiveMostRecentConversation() async {
    isArchivingSession = true
    lastArchiveError = nil

    defer { isArchivingSession = false }

    do {
      let summaries = try await ElevenLabsAPI.fetchConversationSummaries()
      guard
        let conversationId = selectConversationId(
          from: summaries,
          startedAt: lastConversationStartDate
        )
      else {
        print("⚠️ No matching conversation found to archive")
        return
      }

      guard !archivedConversationIds.contains(conversationId) else {
        print("ℹ️ Conversation \(conversationId) already archived")
        return
      }

      try await archiveConversation(withId: conversationId)
      archivedConversationIds.insert(conversationId)
      lastConversationStartDate = nil
    } catch {
      lastArchiveError = error.localizedDescription
      print("⚠️ Failed to archive conversation audio: \(error)")
    }
  }

  private func selectConversationId(
    from summaries: [ElevenLabsAPI.ConversationSummary],
    startedAt startDate: Date?
  ) -> String? {
    guard !summaries.isEmpty else { return nil }

    let ordered = summaries.sorted { $0.sortDate > $1.sortDate }

    guard let startDate else {
      return ordered.first?.id
    }

    let windowStart = startDate.addingTimeInterval(-300) // 5 minutes before start
    let windowEnd = Date().addingTimeInterval(600) // up to 10 minutes after now

    return ordered.first { summary in
      guard let createdAt = summary.createdAt else { return true }
      return createdAt >= windowStart && createdAt <= windowEnd
    }?.id
  }

  private func archiveConversation(withId conversationId: String) async throws {
    let userId = try await SupabaseManager.shared.getCurrentUserId()

    var existingRecord = try await SupabaseManager.shared.fetchSessionRecord(
      conversationId: conversationId
    )
    var sessionId = existingRecord?.id ?? UUID()

    if existingRecord == nil {
      existingRecord = try await SupabaseManager.shared.insertSessionRecord(
        sessionId: sessionId,
        userId: userId,
        conversationId: conversationId
      )
      if let persistedId = existingRecord?.id {
        sessionId = persistedId
      }
    } else if let persistedId = existingRecord?.id {
      sessionId = persistedId
    }

    let downloadedAudio = try await ElevenLabsAPI.downloadConversationAudio(
      conversationId: conversationId
    )

    let fileExtension = Self.preferredFileExtension(
      agentFormat: nil,
      mimeType: downloadedAudio.mimeType
    )
    let mimeType = downloadedAudio.mimeType ?? Self.defaultMimeType(forExtension: fileExtension)

    let storagePath = try await SupabaseManager.shared.uploadSessionAudio(
      data: downloadedAudio.data,
      userId: userId,
      sessionId: sessionId,
      fileExtension: fileExtension,
      mimeType: mimeType
    )

    print("✅ Archived conversation \(conversationId) to \(storagePath)")
  }

  private static func preferredFileExtension(
    agentFormat: String?,
    mimeType: String?
  ) -> String {
    if let mimeType,
      let ext = fileExtension(fromMimeType: mimeType)
    {
      return ext
    }

    guard let agentFormat else {
      return "mp3"
    }

    let normalized = agentFormat.lowercased()
    if normalized.contains("wav") || normalized.contains("pcm") {
      return "wav"
    }
    if normalized.contains("webm") {
      return "webm"
    }
    if normalized.contains("ogg") {
      return "ogg"
    }
    if normalized.contains("mp4") || normalized.contains("m4a") {
      return "m4a"
    }
    if normalized.contains("mp3") {
      return "mp3"
    }
    return "mp3"
  }

  private static func fileExtension(fromMimeType mimeType: String) -> String? {
    let baseMime = mimeType.split(separator: ";", maxSplits: 1).first?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    switch baseMime {
    case "audio/mpeg":
      return "mp3"
    case "audio/webm":
      return "webm"
    case "audio/ogg":
      return "ogg"
    case "audio/x-wav", "audio/wav", "audio/vnd.wave":
      return "wav"
    case "audio/mp4", "audio/m4a":
      return "m4a"
    default:
      return nil
    }
  }

  private static func defaultMimeType(forExtension ext: String) -> String {
    switch ext.lowercased() {
    case "webm":
      return "audio/webm"
    case "ogg":
      return "audio/ogg"
    case "wav":
      return "audio/wav"
    case "m4a", "mp4":
      return "audio/mp4"
    default:
      return "audio/mpeg"
    }
  }
}

// MARK: - Error and Warning Views

struct ErrorBanner: View {
  let message: String
  let onDismiss: () -> Void
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.white)
        .font(.system(size: 20))
      
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .lineLimit(2)
      
      Spacer()
      
      Button(action: onDismiss) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.white)
          .padding(8)
      }
    }
    .padding()
    .background(Color.red.opacity(0.9))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    .padding(.horizontal)
    .padding(.top, 8)
  }
}

struct WarningBanner: View {
  let message: String
  
  var body: some View {
    HStack(spacing: 12) {
      ProgressView()
        .tint(.white)
      
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
    }
    .padding()
    .background(Color.orange.opacity(0.9))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    .padding(.horizontal)
    .padding(.top, 8)
  }
}

// MARK: - Main View

struct PrimeChat: View {
  @StateObject private var viewModel = OrbConversationViewModel()
  
  // Use the Agent ID from config directly.
  // If it's empty, we pass empty string, which relies on SDK default behavior or failing gracefully.
  private let agentId = Config.elevenLabsAgentId
  
  var body: some View {
    ZStack(alignment: .top) {
      // Background
      Color.white.ignoresSafeArea()
      
      // Decorative Background Elements
      GeometryReader { geometry in
        ZStack {
          // Soft blue/purple gradients
          Circle()
            .fill(Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.1))
            .frame(width: 300, height: 300)
            .blur(radius: 60)
            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
          
          Circle()
            .fill(Color.blue.opacity(0.1))
            .frame(width: 250, height: 250)
            .blur(radius: 50)
            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.6)
        }
      }
      .ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Top Bar
        HStack {
          // Profile / Session Indicator
          HStack(spacing: 8) {
            HStack(spacing: 4) {
              Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 20, height: 20)
                .overlay(
                  Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                )
              
              Text("1")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98)) // #F4F8FB
            .cornerRadius(20)
            
            Spacer()
            
            // User Profile Picture
            Circle()
              .stroke(Color.white.opacity(0.3), lineWidth: 1)
              .background(
                Circle().fill(Color.gray.opacity(0.2))
              )
              .frame(width: 40, height: 40)
              .overlay(
                Text(viewModel.userProfile?.firstName.prefix(1).uppercased() ?? "U")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(.gray)
              )
          }
          .padding(.horizontal, 20)
            .padding(.top, 16)
          
          Spacer()
        }
        
        Spacer()
        
        // Center Content
        VStack(spacing: 32) {
          if !viewModel.isConnected {
            // Central decorative element (MaskGroup in Figma) - Simplified
             ZStack {
               Circle()
                 .fill(Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.05))
                 .frame(width: 150, height: 150)
               
               Image(systemName: "sparkles")
                 .font(.system(size: 40))
                 .foregroundStyle(
                    LinearGradient(
                      colors: [Color(red: 0.39, green: 0.27, blue: 0.92), Color.blue],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                 )
             }
          
          VStack(spacing: 8) {
               Text("Hi \(viewModel.userProfile?.firstName ?? "there"), Welcome to Prime.")
                 .font(.system(size: 24, weight: .regular))
              .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
                 .multilineTextAlignment(.center)
               
               Text("I am your personal AI coach that helps you get things done.")
                 .font(.system(size: 20, weight: .regular))
                 .foregroundColor(Color.black.opacity(0.3)) // #211028 with 0.28 opacity
                 .multilineTextAlignment(.center)
                 .padding(.horizontal, 40)
             }
          } else {
             // When connected, show status
             VStack(spacing: 16) {
                Text(viewModel.isSpeaking ? "Speaking..." : "Listening...")
                 .font(.system(size: 24, weight: .medium))
                 .foregroundColor(Color(red: 0.39, green: 0.27, blue: 0.92))
          }
          }
        }
        
        Spacer()
        
        // Bottom Control Bar
        HStack(spacing: 16) {
          // Delete / Reset Button
          Button(action: {
            Task {
               await viewModel.endConversation()
            }
          }) {
              Circle()
               .fill(Color(red: 0.55, green: 0.55, blue: 0.55).opacity(0.2)) // #8d8d8d roughly
               .frame(width: 50, height: 50)
               .overlay(
                 Image(systemName: "trash")
                   .font(.system(size: 20))
                   .foregroundColor(.white)
               )
          }
          
          // Center Pulse / Orb Button
          Button(action: {
             Task {
                await viewModel.toggleConversation(agentId: agentId)
            }
          }) {
             ZStack {
                if viewModel.isConnected {
                   // Show animated orb when connected
                   AnimatedOrbView(agentState: viewModel.conversation?.agentState ?? .listening, size: 80)
                } else {
                   // Idle state
                   Circle()
                     .fill(Color.white)
                     .frame(width: 80, height: 80)
                     .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                     .overlay(
                        Image(systemName: "waveform")
                           .font(.system(size: 30))
                           .foregroundColor(Color(red: 0.39, green: 0.27, blue: 0.92))
                     )
                }
             }
          }
          .frame(width: 80, height: 80)
          
          // Transcribe Button
          Button(action: {
             // Placeholder for transcribe action
             print("Transcribe tapped")
          }) {
             Circle()
               .fill(Color(red: 0.55, green: 0.55, blue: 0.55).opacity(0.2))
               .frame(width: 50, height: 50)
               .overlay(
                 Image(systemName: "text.bubble")
                   .font(.system(size: 20))
                   .foregroundColor(.white)
               )
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(red: 0.55, green: 0.55, blue: 0.55).opacity(0.3)) // Gray bar background
        .cornerRadius(40)
        .padding(.bottom, 30)
        .padding(.horizontal, 20)
      }
      
      // Banners
        VStack {
        if case .reconnecting = viewModel.connectionState {
          WarningBanner(message: "Reconnecting...")
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        
        if let errorMessage = viewModel.errorMessage {
          ErrorBanner(message: errorMessage) {
            viewModel.errorMessage = nil
          }
          .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
  }
    .onAppear {
      Task {
        await viewModel.loadUserProfile()
          }
        }
    .onDisappear {
      Task {
        if viewModel.isConnected {
          await viewModel.endConversation()
      }
    }
  }
}
}

#Preview {
  PrimeChat()
}
