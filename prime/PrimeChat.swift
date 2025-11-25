//
//  PrimeChat.swift
//  prime
//
//  A text-based chatbot using Google Gemini AI
//  Note: Requires Firebase AI Logic SDK to be added to the project
//

import SwiftUI
import Combine
import FirebaseAI

// MARK: - Message Model

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp: Date
    
    enum ChatRole {
        case user
        case assistant
    }
}

// MARK: - Chat ViewModel

@MainActor
final class GeminiChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: SupabaseManager.UserProfile?
    @Published var userFirstName: String?
    
    private var chat: Chat?
    private var model: GenerativeModel?
    private var conversationId: UUID?
    private let modelName = "gemini-2.5-flash"
    private var userNotes: [SupabaseManager.UserNote] = []
    private var messageCountSinceLastNoteExtraction = 0
    private let noteExtractionThreshold = 3  // Extract notes every 3 user messages
    
    init() {
        setupGemini()
    }
    
    private func setupGemini() {
        // Initialize the Gemini Developer API backend service
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // Create a GenerativeModel instance with Gemini 2.5 Flash
        model = ai.generativeModel(modelName: modelName)
        
        // Start a new chat session
        chat = model?.startChat()
    }
    
    /// Create a new conversation in Supabase
    private func createConversation() async {
        do {
            let conversation = try await SupabaseManager.shared.createChatConversation(
                title: "Chat on \(Date().formatted(date: .abbreviated, time: .shortened))",
                modelName: modelName
            )
            conversationId = conversation.id
            print("✅ Created conversation: \(conversation.id?.uuidString ?? "unknown")")
        } catch {
            print("⚠️ Failed to create conversation in Supabase: \(error)")
        }
    }
    
    /// Save a message to Supabase
    private func saveMessage(role: String, content: String) async {
        guard let conversationId = conversationId else {
            print("⚠️ No conversation ID, skipping message save")
            return
        }
        
        do {
            _ = try await SupabaseManager.shared.saveChatMessage(
                conversationId: conversationId,
                role: role,
                content: content,
                modelName: modelName
            )
            print("💾 Saved \(role) message to Supabase")
        } catch {
            print("⚠️ Failed to save message: \(error)")
        }
    }
    
    func loadUserProfile() async {
        userFirstName = await SupabaseManager.shared.getCurrentUserFirstName()
        
        // Create a new conversation in Supabase
        await createConversation()
        
        // Fetch existing notes about the user
        await fetchUserNotes()
        
        do {
            userProfile = try await SupabaseManager.shared.fetchUserProfile()
            print("✅ Loaded user profile for chat")
            
            // Send initial greeting after loading profile
            await sendInitialGreeting()
        } catch {
            print("⚠️ Failed to load user profile: \(error)")
            // Still send greeting even if profile fails
            await sendInitialGreeting()
        }
    }
    
    /// Fetch existing notes about the user from Supabase
    private func fetchUserNotes() async {
        do {
            userNotes = try await SupabaseManager.shared.fetchUserNotes()
            print("📝 Loaded \(userNotes.count) notes about user")
        } catch {
            print("⚠️ Failed to fetch user notes: \(error)")
            userNotes = []
        }
    }
    
    /// Build a context string from user notes
    private func buildNotesContext() -> String {
        guard !userNotes.isEmpty else { return "" }
        
        var context = "\n\nIMPORTANT - Here are things you've learned about this user from previous conversations:\n"
        
        // Group notes by category for better organization
        let categories = ["goal", "achievement", "challenge", "insight", "preference", "context", "reminder"]
        
        for category in categories {
            let categoryNotes = userNotes.filter { $0.category == category }
            if !categoryNotes.isEmpty {
                let categoryLabel = category.capitalized + "s"
                context += "\n\(categoryLabel):\n"
                for note in categoryNotes {
                    context += "- \(note.content)\n"
                }
            }
        }
        
        context += "\nUse this knowledge naturally in your responses. Reference past conversations when relevant.\n"
        return context
    }
    
    private func sendInitialGreeting() async {
        // Build a personalized system context
        var systemContext = """
        You are a helpful and friendly life coach assistant named Prime Coach. 
        Your role is to help users achieve their goals, overcome challenges, and grow personally.
        
        """
        
        if let firstName = userFirstName {
            systemContext += "The user's name is \(firstName). "
        }
        
        if let profile = userProfile {
            systemContext += "Their primary goal is: \(profile.primaryGoal). "
            if let style = profile.coachingStyle {
                systemContext += "They prefer a \(style) coaching style. "
            }
        }
        
        // Add notes context from previous conversations
        systemContext += buildNotesContext()
        
        systemContext += "\nStart the conversation with a warm greeting that says 'Hello' and be encouraging. If you have notes about the user, subtly reference something relevant to show you remember them."
        
        isLoading = true
        
        do {
            guard let chat = chat else {
                throw GeminiError.notInitialized
            }
            
            // Send system context to establish personality
            let response = try await chat.sendMessage(systemContext)
            
            let content = response.text ?? ""
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: content,
                timestamp: Date()
            )
            messages.append(assistantMessage)
            
            // Save to Supabase
            await saveMessage(role: "assistant", content: content)
        } catch {
            print("❌ Failed to send initial greeting: \(error)")
            // Add a fallback greeting
            let fallbackContent = "Hello! I'm your Prime coach. How can I help you today?"
            let fallbackMessage = ChatMessage(
                role: .assistant,
                content: fallbackContent,
                timestamp: Date()
            )
            messages.append(fallbackMessage)
            
            // Save fallback to Supabase
            await saveMessage(role: "assistant", content: fallbackContent)
        }
        
        isLoading = false
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message to the list
        let userMessage = ChatMessage(
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Save user message to Supabase
        await saveMessage(role: "user", content: text)
        
        // Track messages for note extraction
        messageCountSinceLastNoteExtraction += 1
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let chat = chat else {
                throw GeminiError.notInitialized
            }
            
            let response = try await chat.sendMessage(text)
            
            let responseContent = response.text ?? ""
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: responseContent,
                timestamp: Date()
            )
            messages.append(assistantMessage)
            
            // Save assistant response to Supabase
            await saveMessage(role: "assistant", content: responseContent)
            
            // Periodically extract notes from conversation
            if messageCountSinceLastNoteExtraction >= noteExtractionThreshold {
                Task {
                    await extractAndSaveNotes()
                }
            }
        } catch {
            print("❌ Failed to send message: \(error)")
            errorMessage = "Failed to get response. Please try again."
        }
        
        isLoading = false
    }
    
    /// Extract notable insights from recent conversation and save as notes
    private func extractAndSaveNotes() async {
        guard let model = model else { return }
        
        // Get recent messages for analysis (last 6 messages = 3 exchanges)
        let recentMessages = messages.suffix(6)
        guard recentMessages.count >= 2 else { return }
        
        // Build conversation transcript
        var transcript = ""
        for msg in recentMessages {
            let role = msg.role == .user ? "User" : "Assistant"
            transcript += "\(role): \(msg.content)\n\n"
        }
        
        let extractionPrompt = """
        Analyze this conversation excerpt and extract any important insights about the user that would be valuable to remember for future conversations. 
        
        CONVERSATION:
        \(transcript)
        
        Extract notes in this exact JSON format. Only include notes if there's genuinely new, meaningful information. Return an empty array if nothing notable.
        
        Categories: goal, challenge, preference, achievement, insight, context, reminder
        
        Response format (JSON only, no other text):
        [
            {"category": "goal", "content": "User wants to run a marathon by next year", "importance": 3},
            {"category": "achievement", "content": "User completed their first 5K last week", "importance": 4}
        ]
        
        Importance scale: 1=minor detail, 2=useful context, 3=important, 4=very important, 5=critical
        
        Return ONLY valid JSON array, nothing else.
        """
        
        do {
            let response = try await model.generateContent(extractionPrompt)
            let responseText = response.text ?? ""
            
            // Parse the JSON response
            if let notes = parseNotesFromJSON(responseText) {
                for note in notes {
                    _ = try? await SupabaseManager.shared.saveUserNote(
                        category: note.category,
                        content: note.content,
                        conversationId: conversationId,
                        importance: note.importance
                    )
                }
                
                if !notes.isEmpty {
                    print("📝 Extracted and saved \(notes.count) notes from conversation")
                }
            }
        } catch {
            print("⚠️ Failed to extract notes: \(error)")
        }
        
        messageCountSinceLastNoteExtraction = 0
    }
    
    /// Parse notes from JSON response
    private func parseNotesFromJSON(_ jsonString: String) -> [(category: String, content: String, importance: Int)]? {
        // Clean up the response - extract JSON array
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON array in response
        if let startIndex = cleanJSON.firstIndex(of: "["),
           let endIndex = cleanJSON.lastIndex(of: "]") {
            cleanJSON = String(cleanJSON[startIndex...endIndex])
        } else {
            return nil
        }
        
        guard let data = cleanJSON.data(using: .utf8) else { return nil }
        
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var notes: [(category: String, content: String, importance: Int)] = []
                
                for item in jsonArray {
                    guard let category = item["category"] as? String,
                          let content = item["content"] as? String else { continue }
                    
                    let importance = item["importance"] as? Int ?? 2
                    
                    // Validate category
                    let validCategories = ["goal", "challenge", "preference", "achievement", "insight", "context", "reminder"]
                    guard validCategories.contains(category) else { continue }
                    
                    notes.append((category: category, content: content, importance: importance))
                }
                
                return notes.isEmpty ? nil : notes
            }
        } catch {
            print("⚠️ Failed to parse notes JSON: \(error)")
        }
        
        return nil
    }
    
    func clearChat() {
        messages.removeAll()
        // Restart chat session
        chat = model?.startChat()
        conversationId = nil
        messageCountSinceLastNoteExtraction = 0
        
        Task {
            // Create a new conversation for the new chat
            await createConversation()
            // Refresh notes (might have new ones from previous session)
            await fetchUserNotes()
            await sendInitialGreeting()
        }
    }
    
    enum GeminiError: Error {
        case notInitialized
        case emptyResponse
    }
}

// MARK: - Chat Message Bubble

struct ChatMessageBubble: View {
    let message: ChatMessage
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
                    ChatTypewriterText(text: message.content)
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

// MARK: - Typewriter Text Effect

struct ChatTypewriterText: View {
    let text: String
    @State private var displayedText = ""
    @State private var charIndex = 0
    
    private let typingSpeed: TimeInterval = 0.02
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onChange(of: text) { _, newText in
                if !newText.hasPrefix(displayedText) {
                    displayedText = ""
                    charIndex = 0
                    startTyping()
                } else {
                    startTyping()
                }
            }
    }
    
    private func startTyping() {
        guard charIndex < text.count else { return }
        
        let remainingCount = text.count - charIndex
        
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

// MARK: - Chat Input View

struct ChatInputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void
    @FocusState.Binding var isFocused: Bool
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording indicator
            if speechManager.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Listening...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    if !speechManager.transcribedText.isEmpty {
                        Text(speechManager.transcribedText)
                            .font(.caption)
                            .foregroundColor(.black)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primeControlBg.opacity(0.5))
            }
            
            HStack(spacing: 12) {
                // Microphone button
                Button(action: {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        // Transfer transcribed text to message field
                        if !speechManager.transcribedText.isEmpty {
                            if messageText.isEmpty {
                                messageText = speechManager.transcribedText
                            } else {
                                messageText += " " + speechManager.transcribedText
                            }
                            speechManager.clearTranscription()
                        }
                    } else {
                        speechManager.clearTranscription()
                        speechManager.startRecording()
                    }
                }) {
                    Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 20))
                        .foregroundColor(speechManager.isRecording ? .red : .gray)
                        .frame(width: 36, height: 36)
                        .background(speechManager.isRecording ? Color.red.opacity(0.1) : Color.clear)
                        .cornerRadius(18)
                }
                .disabled(!speechManager.isAuthorized || isLoading)
                
                TextField("Type or tap mic to speak...", text: $messageText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.primeControlBg)
                    .cornerRadius(20)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        onSend()
                    }
                    .disabled(isLoading)
                
                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .primePrimaryText)
                    }
                }
                .disabled(messageText.isEmpty || isLoading)
            }
            .padding()
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primeDivider),
            alignment: .top
        )
    }
}

// MARK: - Main Chat View

struct GeminiChatView: View {
    @ObservedObject var viewModel: GeminiChatViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            ChatMessageBubble(
                                message: message,
                                isLast: index == viewModel.messages.count - 1
                            )
                            .id(message.id)
                        }
                        
                        // Loading indicator
                        if viewModel.isLoading && viewModel.messages.last?.role == .user {
                            HStack {
                                TypingIndicator()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.primeControlBg)
                                    .cornerRadius(20)
                                Spacer()
                            }
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
            
            // Error Banner
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Dismiss") {
                        viewModel.errorMessage = nil
                    }
                    .font(.caption)
                    .foregroundColor(.primePrimaryText)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }
            
            // Input Area
            ChatInputView(
                messageText: $messageText,
                isLoading: viewModel.isLoading,
                onSend: sendMessage,
                isFocused: $isFocused
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

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = -5
        }
    }
}

// MARK: - Main View

struct PrimeChat: View {
    @StateObject private var viewModel = GeminiChatViewModel()
    @State private var showingProfile = false
    @State private var showingDebugMenu = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
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
                            .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                            .font(.system(size: 16))
                        Text("1")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Title
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.primePrimaryText)
                        Text("Prime Chat")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
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
                
                // Chat Content
                GeminiChatView(viewModel: viewModel)
                    .frame(maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        #if DEBUG
        .confirmationDialog("Debug Menu", isPresented: $showingDebugMenu, titleVisibility: .visible) {
            Button("Clear Chat") {
                viewModel.clearChat()
            }
            
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
    }
}

#Preview {
    PrimeChat()
}

