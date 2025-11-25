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
import MediaPlayer

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
      // Soft outer glow
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color(red: 0.7, green: 0.8, blue: 1.0).opacity(0.3),
              Color.clear
            ],
            center: .center,
            startRadius: size * 0.4,
            endRadius: size * 1.2
          )
        )
        .frame(width: size * 2, height: size * 2)
        .scaleEffect(pulseAmount * 1.1)

      // Main Sphere (Pearl/Bubble look)
      Circle()
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.95, green: 0.96, blue: 1.0), // Top-left highlight (White-ish)
              Color(red: 0.85, green: 0.88, blue: 1.0), // Mid (Soft Blue)
              Color(red: 0.75, green: 0.70, blue: 1.0)  // Bottom-right (Soft Purple)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: size, height: size)
        .shadow(
          color: Color(red: 0.6, green: 0.6, blue: 0.9).opacity(0.25),
          radius: size * 0.15,
          x: 0,
          y: size * 0.1
        )
        .scaleEffect(pulseAmount)
      
      // Inner "Bubble" Highlight
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color.white.opacity(0.8),
              Color.white.opacity(0.0)
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: size * 0.6
          )
        )
        .frame(width: size, height: size)
        .scaleEffect(pulseAmount)
        .offset(x: -size * 0.15, y: -size * 0.15)
      
      // Shimmer/Rotation (Subtle)
      Circle()
        .fill(
          AngularGradient(
            colors: [
              .white.opacity(0.3),
              .clear,
              .white.opacity(0.1),
              .clear
            ],
            center: .center
          )
        )
        .frame(width: size * 0.9, height: size * 0.9)
        .rotationEffect(.degrees(rotation))
        .blur(radius: size * 0.05)
    }
    .onAppear {
      startAnimation()
    }
    .onChange(of: agentState) { _, _ in
      startAnimation()
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
    case .unknown, .connecting, .initializing:
      return 2.0
    @unknown default:
      return 2.0
    }
  }
  
  private var pulseRange: (min: CGFloat, max: CGFloat) {
    switch agentState {
    case .listening:
      return (0.98, 1.02)
    case .speaking:
      return (0.95, 1.1)
    case .thinking:
      return (0.97, 1.03)
    case .unknown, .connecting, .initializing:
      return (0.98, 1.02)
    @unknown default:
      return (0.98, 1.02)
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
      .linear(duration: 8)
      .repeatForever(autoreverses: false)
    ) {
      rotation = 360
    }
  }
}

// MARK: - Chat View

struct ChatView: View {
  @ObservedObject var viewModel: OrbConversationViewModel
  @State private var messageText = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      // Message List
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
              MessageBubble(message: message, isLast: index == viewModel.messages.count - 1)
                .id(message.id)
            }
          }
          .padding()
        }
        .onChange(of: viewModel.messages.count) { _, _ in
          if let lastMessage = viewModel.messages.last {
            withAnimation {
              proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
      }
      
      // Input Area
      HStack(spacing: 12) {
        TextField("Type a message...", text: $messageText)
          .textFieldStyle(.plain)
          .foregroundColor(.black)
          .padding(12)
          .background(Color.primeControlBg)
          .cornerRadius(20)
          .focused($isFocused)
          .submitLabel(.send)
          .onSubmit {
              sendMessage()
          }
        
        Button(action: sendMessage) {
          Image(systemName: "paperplane.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(messageText.isEmpty ? .gray : .primePrimaryText)
        }
        .disabled(messageText.isEmpty)
      }
      .padding()
      .background(Color.white)
      .overlay(
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color.primeDivider),
        alignment: .top
      )
    }
    .background(Color.white)
  }
  
  private func sendMessage() {
      guard !messageText.isEmpty else { return }
      let text = messageText
      messageText = ""
      Task {
          await viewModel.sendMessage(text)
      }
  }
}

struct MessageBubble: View {
    let message: Message
    let isLast: Bool
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            if isUser {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primePrimaryText)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .cornerRadius(4, corners: .bottomRight)
            } else {
                if isLast {
                    TypewriterText(text: message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primeControlBg)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: .bottomLeft)
                } else {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primeControlBg)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: .bottomLeft)
                }
            }
            
            if !isUser { Spacer() }
        }
    }
}

struct TypewriterText: View {
    let text: String
    @State private var displayedText = ""
    @State private var charIndex = 0
    
    // Faster typing speed for better UX
    private let typingSpeed: TimeInterval = 0.02
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onChange(of: text) { _, newText in
                // If text changes (e.g. correction or full load), restart or append
                // For simplicity, if the text is significantly different, we reset
                if !newText.hasPrefix(displayedText) {
                    displayedText = ""
                    charIndex = 0
                    startTyping()
                } else {
                    // Continue typing if it's just an append
                    startTyping()
                }
            }
    }
    
    private func startTyping() {
        // Invalidate existing timer if any (not storing timer here, relying on async dispatch)
        // A simple recursive dispatch is safer for SwiftUI state updates than a Timer in some cases
        
        guard charIndex < text.count else { return }
        
        let remainingCount = text.count - charIndex
        
        // If text is huge, just show it all to avoid long wait
        if remainingCount > 1000 {
            displayedText = text
            charIndex = text.count
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if charIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: charIndex)
                displayedText.append(text[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
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
  @Published var userFirstName: String?
  @Published var microphoneDenied: Bool = false
  @Published var isArchivingSession: Bool = false
  @Published var lastArchiveError: String?
  @Published var isMuted: Bool = false
  @Published var isSpeakerMuted: Bool = false
  @Published var messages: [Message] = []
  @Published var mode: ConversationMode = .talk
  
  enum ConversationMode {
      case talk
      case chat
  }
  
  private var cancellables = Set<AnyCancellable>()
  private let audioSession = AVAudioSession.sharedInstance()
  private let conversationAudioEngine = ConversationAudioEngine.shared
  private var lastConversationStartDate: Date?
  private var archivedConversationIds = Set<String>()
  
  func loadUserProfile() async {
    // Get user's first name from auth (Sign In with Apple)
    userFirstName = await SupabaseManager.shared.getCurrentUserFirstName()
    
    do {
      userProfile = try await SupabaseManager.shared.fetchUserProfile()
      print("✅ Loaded user profile")
      print("  - First name: \(userFirstName ?? "Unknown")")
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
  
  func toggleMute() {
    guard let conversation = conversation else { return }
    Task {
      do {
        try await conversation.toggleMute()
      } catch {
        print("Failed to toggle mute: \(error)")
      }
    }
  }
  
  func toggleSpeakerMute() {
      isSpeakerMuted.toggle()
      ConversationAudioEngine.shared.setVoiceVolume(isSpeakerMuted ? 0.0 : 1.0)
  }
  
  // MARK: - Lock Screen / Background Controls
  
  private func setupLockScreenControls() {
      let center = MPRemoteCommandCenter.shared()
      
      // Clear existing targets
      center.playCommand.removeTarget(nil)
      center.pauseCommand.removeTarget(nil)
      center.stopCommand.removeTarget(nil)
      center.togglePlayPauseCommand.removeTarget(nil)
      
      // Play Command (Resume / Unmute)
      center.playCommand.isEnabled = true
      center.playCommand.addTarget { [weak self] _ in
          guard let self = self else { return .commandFailed }
          if self.isMuted {
              self.toggleMute()
          }
          self.updateNowPlayingInfo(isPlaying: true)
          return .success
      }
      
      // Pause Command (Mute)
      center.pauseCommand.isEnabled = true
      center.pauseCommand.addTarget { [weak self] _ in
          guard let self = self else { return .commandFailed }
          if !self.isMuted {
              self.toggleMute()
          }
          self.updateNowPlayingInfo(isPlaying: false)
          return .success
      }
      
      // Stop Command (End Call)
      center.stopCommand.isEnabled = true
      center.stopCommand.addTarget { [weak self] _ in
          guard let self = self else { return .commandFailed }
          Task {
              await self.endConversation()
          }
          return .success
      }
      
      updateNowPlayingInfo(isPlaying: true)
  }
  
  private func clearLockScreenControls() {
      let center = MPRemoteCommandCenter.shared()
      center.playCommand.removeTarget(nil)
      center.pauseCommand.removeTarget(nil)
      center.stopCommand.removeTarget(nil)
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
  
  private func updateNowPlayingInfo(isPlaying: Bool) {
      var nowPlayingInfo = [String: Any]()
      nowPlayingInfo[MPMediaItemPropertyTitle] = "Prime Coach"
      nowPlayingInfo[MPMediaItemPropertyArtist] = "Conversation"
      nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  private func startConversation(agentId: String) async {
    connectionState = .connecting
    errorMessage = nil
    lastArchiveError = nil
    isArchivingSession = false
    isMuted = false
    
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
      
      // Add firstname from auth metadata if available
      if let firstName = userFirstName {
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
      setupLockScreenControls()
      conversationAudioEngine.startMusic()
      conversationAudioEngine.attach(conversation: conv)
    } catch {
      print("Error starting conversation: \(error)")
      errorMessage = error.localizedDescription
      connectionState = .disconnected
    }
  }
  
  func endConversation() async {
    clearLockScreenControls()
    await conversation?.endConversation()
    conversationAudioEngine.stop()
    conversation = nil
    isConnected = false
    isSpeaking = false
    audioLevel = 0.0
    connectionState = .idle
    isInteractive = false
    cancellables.removeAll()
    messages.removeAll()

    Task { [weak self] in
      await self?.archiveMostRecentConversation()
    }
  }
  
  // MARK: - Chat Functionality
  
  func sendMessage(_ text: String) async {
      guard let conversation = conversation else { return }
      do {
          try await conversation.sendMessage(text)
      } catch {
          print("❌ Failed to send message: \(error)")
          errorMessage = "Failed to send message"
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
        case .ended, .idle, .error:
          self?.isConnected = false
          self?.connectionState = .idle
          self?.conversationAudioEngine.stop()
        @unknown default:
          break
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
        @unknown default:
          break
        }
      }
      .store(in: &cancellables)
      
      // Messages
      conversation.$messages
          .receive(on: DispatchQueue.main)
          .sink { [weak self] messages in
              self?.messages = messages
          }
          .store(in: &cancellables)
      
      // Mute state
      conversation.$isMuted
          .receive(on: DispatchQueue.main)
          .sink { [weak self] isMuted in
              self?.isMuted = isMuted
              self?.updateNowPlayingInfo(isPlaying: !isMuted)
          }
          .store(in: &cancellables)
  }
  
  private func requestMicrophonePermission() async -> Bool {
      return await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermission { granted in
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
        let summary = selectConversationSummary(
          from: summaries,
          startedAt: lastConversationStartDate
        )
      else {
        print("⚠️ No matching conversation found to archive")
        return
      }

      let conversationId = summary.id

      guard !archivedConversationIds.contains(conversationId) else {
        print("ℹ️ Conversation \(conversationId) already archived")
        return
      }

      try await archiveConversation(withId: conversationId, agentId: summary.agentId)
      archivedConversationIds.insert(conversationId)
      lastConversationStartDate = nil
    } catch {
      lastArchiveError = error.localizedDescription
      print("⚠️ Failed to archive conversation audio: \(error)")
      print("Error: \(error)")
      print("Error description: \(String(describing: lastArchiveError))")
    }
  }

  private func selectConversationSummary(
    from summaries: [ElevenLabsAPI.ConversationSummary],
    startedAt startDate: Date?
  ) -> ElevenLabsAPI.ConversationSummary? {
    guard !summaries.isEmpty else { return nil }

    let ordered = summaries.sorted { $0.sortDate > $1.sortDate }

    guard let startDate else {
      return ordered.first
    }

    let windowStart = startDate.addingTimeInterval(-300) // 5 minutes before start
    let windowEnd = Date().addingTimeInterval(600) // up to 10 minutes after now

    return ordered.first { summary in
      guard let createdAt = summary.createdAt else { return true }
      return createdAt >= windowStart && createdAt <= windowEnd
    }
  }

  private func archiveConversation(withId conversationId: String, agentId: String?) async throws {
    let userId = try await SupabaseManager.shared.getCurrentUserId()
    var record = try await SupabaseManager.shared.fetchSessionRecord(conversationId: conversationId)
    var sessionId = record?.id ?? UUID()

    if record == nil {
      record = try await SupabaseManager.shared.insertSessionRecord(
        sessionId: sessionId,
        userId: userId,
        conversationId: conversationId,
        agentId: agentId
      )
      sessionId = record?.id ?? sessionId
    }

    let downloadedAudio = try await downloadConversationAudioWithRetry(conversationId: conversationId)

    let fileExtension = Self.preferredFileExtension(agentFormat: nil, mimeType: downloadedAudio.mimeType)
    let mimeType = downloadedAudio.mimeType ?? Self.defaultMimeType(forExtension: fileExtension)

    _ = try await SupabaseManager.shared.uploadSessionAudio(
      data: downloadedAudio.data,
      userId: userId,
      sessionId: sessionId,
      fileExtension: fileExtension,
      mimeType: mimeType
    )

    print("✅ Archived conversation \(conversationId)")
  }

  private func downloadConversationAudioWithRetry(conversationId: String) async throws -> ElevenLabsAPI.DownloadedAudio {
    let attempts = 3
    for attempt in 1...attempts {
      do {
        return try await ElevenLabsAPI.downloadConversationAudio(conversationId: conversationId)
      } catch ElevenLabsAPI.APIError.invalidResponse(statusCode: 404) where attempt < attempts {
        try await Task.sleep(nanoseconds: 3 * 1_000_000_000) // wait 3s
        continue
      }
    }
    return try await ElevenLabsAPI.downloadConversationAudio(conversationId: conversationId)
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
    .background(Color.primeButtonDanger.opacity(0.95))
    .cornerRadius(16)
    .shadow(color: Color.primeButtonDanger.opacity(0.3), radius: 8, x: 0, y: 4)
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
    .background(Color.primeAccent.opacity(0.95))
    .cornerRadius(16)
    .shadow(color: Color.primeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
    .padding(.horizontal)
    .padding(.top, 8)
  }
}

// MARK: - Main View

struct PrimeChat: View {
  @StateObject private var viewModel = OrbConversationViewModel()
  @State private var showingDebugMenu = false
  @State private var showingProfile = false
  
  // Use the Agent ID from config directly.
  private let agentId = Config.elevenLabsAgentId
  
  var body: some View {
    ZStack(alignment: .top) {
      // Background
      Color.white.ignoresSafeArea()
      
      // Subtle blue glow at bottom (only in Talk mode or if desired in Chat too)
      if viewModel.mode == .talk {
          GeometryReader { proxy in
            Ellipse()
              .fill(
                Color(red: 0.62, green: 0.83, blue: 1.0)
                  .opacity(0.25)
              )
              .frame(width: proxy.size.width * 1.5, height: proxy.size.height * 0.5)
              .position(x: proxy.size.width / 2, y: proxy.size.height * 1.1)
              .blur(radius: 60)
          }
          .ignoresSafeArea()
      }
      
      VStack(spacing: 0) {
        // Top Bar
        HStack {
          #if DEBUG
          Button(action: {
            showingDebugMenu = true
          }) {
            Image(systemName: "gearshape.fill")
              .font(.system(size: 16))
              .foregroundColor(.gray)
              .padding(6)
              .background(Color.white)
              .clipShape(Circle())
              .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
          }
          .padding(.trailing, 8)
          #endif

          // Streak Indicator
          HStack(spacing: 4) {
            Image(systemName: "flame.fill")
              .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0)) // Orange flame
              .font(.system(size: 16))
            Text("1")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(Color.black.opacity(0.8))
          }
          
          Spacer()
          
          // Talk / Chat Toggle
          HStack(spacing: 0) {
            // Talk Button
            Button(action: { viewModel.mode = .talk }) {
                HStack(spacing: 6) {
                  Text("Talk")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.mode == .talk ? .black : .gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(viewModel.mode == .talk ? Color.white : Color.clear)
                .cornerRadius(20)
                .shadow(color: viewModel.mode == .talk ? Color.black.opacity(0.05) : .clear, radius: 2, x: 0, y: 1)
            }
            
            // Chat Button
            Button(action: { viewModel.mode = .chat }) {
                HStack(spacing: 6) {
                  Text("Chat")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.mode == .chat ? .black : .gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(viewModel.mode == .chat ? Color.white : Color.clear)
                .cornerRadius(20)
                .shadow(color: viewModel.mode == .chat ? Color.black.opacity(0.05) : .clear, radius: 2, x: 0, y: 1)
            }
          }
          .padding(4)
          .background(Color(red: 0.96, green: 0.96, blue: 0.98)) // Light gray/blue bg
          .cornerRadius(24)
          
          Spacer()
          
          // User Profile
          Button(action: { showingProfile = true }) {
            if let firstName = viewModel.userFirstName, !firstName.isEmpty {
              Circle()
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .frame(width: 36, height: 36)
                .overlay(
                  Text(firstName.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                )
            } else {
              Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        
        // Content Area
        if viewModel.mode == .chat {
            ChatView(viewModel: viewModel)
                .frame(maxHeight: .infinity)
                .transition(.opacity)
        } else {
            Spacer()
            
            // Center Content (Orb)
            VStack(spacing: 32) {
              if viewModel.isConnected {
                AnimatedOrbView(
                  agentState: viewModel.conversation?.agentState ?? .listening,
                  size: 200
                )
              } else {
                // Idle State - Static Orb or similar
                 Circle()
                  .fill(
                    LinearGradient(
                      colors: [
                        Color(red: 0.95, green: 0.96, blue: 1.0),
                        Color(red: 0.85, green: 0.88, blue: 1.0)
                      ],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 200, height: 200)
                  .shadow(color: Color.blue.opacity(0.1), radius: 20, x: 0, y: 10)
                  .onTapGesture {
                    Task {
                       await viewModel.toggleConversation(agentId: agentId)
                    }
                  }
              }
            }
            
            Spacer()
            
            // Bottom Bar (Only for Talk Mode)
            HStack {
                // Left: Speaker Mute (previously History)
                Button(action: {
                    viewModel.toggleSpeakerMute()
                }) {
                    Image(systemName: viewModel.isSpeakerMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.isSpeakerMuted ? Color.red : Color.black.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                Spacer()
                
                // Center: Status / Action Pill
                Button(action: {
                    Task {
                       await viewModel.toggleConversation(agentId: agentId)
                    }
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isConnected {
                            // Status Text (e.g. Listening)
                             Image(systemName: "waveform")
                                .font(.system(size: 14))
                            Text(viewModel.isSpeaking ? "Speaking" : "Listening")
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            Text("Tap to Start")
                                 .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                // Right: Mic Toggle (Mute/Unmute)
                Button(action: {
                     viewModel.toggleMute()
                }) {
                    ZStack {
                        if viewModel.isConnected {
                            Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(viewModel.isMuted ? Color.red : Color.black.opacity(0.6))
                                .contentTransition(.symbolEffect(.replace))
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.black.opacity(0.2)) // Disabled look
                        }
                    }
                    .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.isConnected)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .transition(.opacity)
        }
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
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    #if DEBUG
    .confirmationDialog("Debug Menu", isPresented: $showingDebugMenu, titleVisibility: .visible) {
      Button("Sign Out", role: .destructive) {
        Task {
          do {
            try await SupabaseManager.shared.signOut()
            print("✅ Signed out successfully")
            NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
          } catch {
            print("❌ Sign out failed: \(error)")
          }
        }
      }
      
      Button("Force Sign Out & Clear Session", role: .destructive) {
        Task {
          do {
            try? await SupabaseManager.shared.signOut()
            UserDefaults.standard.removeObject(forKey: "sb-auth-token")
            UserDefaults.standard.synchronize()
            print("✅ Force signed out and cleared session")
          }
        }
      }
      
      Button("Check Session") {
        Task {
          do {
            let userId = try await SupabaseManager.shared.getCurrentUserId()
            print("✅ Session valid - User ID: \(userId)")
          } catch {
            print("❌ No valid session: \(error)")
          }
        }
      }
      
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("Developer options")
    }
    #endif
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
