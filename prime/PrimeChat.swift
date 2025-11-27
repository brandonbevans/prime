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
    var isPreloaded: Bool = false  // True for messages loaded from history (no typewriter)
    
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
    @Published var isStreamingEnabled: Bool = true  // Global toggle for typewriter effect
    @Published var shouldScrollToBottom: Bool = false  // Trigger scroll after loading conversation
    
    private var chat: Chat?
    private var model: GenerativeModel?
    private(set) var conversationId: UUID?
    private let modelName = "gemini-2.5-flash"
    private var userNotes: [SupabaseManager.UserNote] = []
    private var isFirstChatOfDay: Bool = true  // Track if this is the user's first chat today
    
    // Function declaration for saving user notes - Gemini will call this when it notices something important
    private let saveUserNoteTool = FunctionDeclaration(
        name: "saveUserNote",
        description: """
            Save an important insight or fact about the user that should be remembered for future conversations.
            Call this whenever you learn something meaningful about the user such as:
            - Their goals, dreams, or aspirations
            - Challenges or obstacles they're facing
            - Achievements or progress they've made
            - Personal preferences or styles
            - Important context about their life
            - Things to follow up on later
            Only save genuinely important information, not trivial details.
            """,
        parameters: [
            "category": .enumeration(
                values: ["goal", "challenge", "preference", "achievement", "insight", "context", "reminder"],
                description: "The type of note: goal (aspirations), challenge (obstacles), preference (styles/likes), achievement (wins), insight (realizations), context (background info), reminder (follow-ups)"
            ),
            "content": .string(
                description: "The insight or fact to remember about the user. Be concise but include enough context to be useful later."
            ),
            "importance": .integer(
                description: "How important is this to remember? 1=minor detail, 2=useful context, 3=important, 4=very important, 5=critical"
            )
        ]
    )
    
    init() {
        setupGemini()
    }
    
    private func setupGemini() {
        // Initialize the Gemini Developer API backend service
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // Create a GenerativeModel instance with the saveUserNote tool
        model = ai.generativeModel(
            modelName: modelName,
            tools: [.functionDeclarations([saveUserNoteTool])]
        )
        
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
        
        // Check if this is the first conversation of the day BEFORE creating the new one
        await checkIfFirstChatOfDay()
        
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
    
    /// Check if there are any conversations from today (determines greeting style)
    private func checkIfFirstChatOfDay() async {
        do {
            let todaysCount = try await SupabaseManager.shared.countTodaysConversations()
            isFirstChatOfDay = todaysCount == 0
            print("📅 Today's conversation count: \(todaysCount), isFirstChatOfDay: \(isFirstChatOfDay)")
        } catch {
            print("⚠️ Failed to check today's conversations: \(error)")
            // Default to first chat behavior if check fails
            isFirstChatOfDay = true
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
        // Build a personalized system context with Prime persona
        var systemContext = """
        ROLE:
        You are Prime. You are a results-oriented performance coach and accountability partner. Your purpose is not to be a friend, but to ensure the user executes on their goals. You are the user's rational mirror.

        TONE & STYLE:
        1. No Fluff, No Filler: Avoid performative niceties ("I hope you're having a wonderful day!"). Get straight to the point.
        2. Grounded Reality: Offer encouragement based on facts and evidence, not empty slogans.
           - Bad: "You're a superstar! You can do anything!"
           - Good: "You've handled high-pressure situations before. This is just another problem to solve. Let's break it down."
        3. Rational, Not Mean: If the user is lazy, call it out firmly. If they're genuinely struggling or burnt out, offer constructive support and strategy—not pity.
        4. Mobile-First: Keep responses concise, scannable, and actionable. Use bullet points. Avoid long paragraphs.

        CORE DIRECTIVES:
        1. The Daily Debrief:
           - Your primary goal is to ensure the user has a clear plan.
           - Ask: "What is the ONE move that makes today a win?"
           - If the answer is vague, drill down until it is specific and actionable.
        2. The "Next 1% Move":
           - When the user is overwhelmed, reduce the scope. Find the smallest possible action that creates momentum.
           - Focus on the immediate next step, not the distant mountain.
        3. Constructive Criticism:
           - If the user makes an excuse, challenge it with logic.
           - If the user fails, help them analyze *why* so they don't repeat the mistake. Do not judge, but do not coddle.

        INTERACTION EXAMPLES:
        - User making excuses ("I'm too tired to go to the gym"):
          "You're negotiating with yourself. You don't need to hit a PR today, but you do need to keep the habit. Go for 15 minutes. Just show up. Confirm when you're leaving."
        - User genuinely defeated ("I blew it. I feel useless"):
          "Beating yourself up is just another form of procrastination—it wastes energy. You had a bad day. Acknowledge it, learn the lesson, and move on. What is one small thing you can do right now to end the day on a win?"
        - User is vague ("I need to work on my business"):
          "Too vague. That's a wish, not a plan. Define the first action: Are you emailing a client? Writing code? Drafting a document? Give me the specific task."

        MEMORY TOOL:
        You have a tool called 'saveUserNote' to remember important things about the user. Use it proactively when you learn:
        - Goals, aspirations, or targets they're working toward
        - Challenges, obstacles, or recurring excuses
        - Achievements, wins, or progress made
        - Patterns in their behavior (positive or negative)
        - Important context about their life or situation
        - Commitments they make that you should follow up on
        Focus on insights that help you hold them accountable. Don't save trivial details.

        Assume the user is capable and ambitious. Treat them with the respect of high expectations. Always push for the next tangible step.
        
        """
        
        if let firstName = userFirstName {
            systemContext += "USER CONTEXT:\nName: \(firstName)\n"
        }
        
        if let profile = userProfile {
            systemContext += "Primary Goal: \(profile.primaryGoal)\n"
            if let style = profile.coachingStyle {
                systemContext += "Preferred Style: \(style)\n"
            }
        }
        
        // Add notes context from previous conversations
        systemContext += buildNotesContext()
        
        // Differentiate between first chat of day vs subsequent chats
        if isFirstChatOfDay {
            // First chat: Focus on the ONE move - the main purpose of the app
            systemContext += """
            
            CONTEXT: This is the user's FIRST conversation of the day. This is their daily check-in.
            
            Your opening should:
            1. Be brief and direct (no small talk)
            2. If returning user with notes, briefly acknowledge one relevant commitment or goal
            3. Immediately ask: "What's the ONE move that makes today a win?"
            
            This is the most important question. The entire purpose of this conversation is to get them to define and commit to their single most important action for today.
            """
        } else {
            // Subsequent chat: More casual, they're coming back for ad-hoc help
            systemContext += """
            
            CONTEXT: This is NOT the user's first conversation today. They've already done their daily check-in.
            
            Your opening should:
            1. Be casual and brief - just "What's up?" or "Back again. What do you need?"
            2. Don't re-ask about their ONE move for today (they already set it)
            3. Be ready to help with whatever ad-hoc question or issue they have
            4. If relevant, you can ask for a quick status update on their earlier commitment
            
            Keep it short - they're here for something specific.
            """
        }
        
        isLoading = true
        
        do {
            guard let chat = chat else {
                throw GeminiError.notInitialized
            }
            
            // Send system context to establish personality
            var response = try await chat.sendMessage(systemContext)
            
            // Handle any function calls (Gemini might save notes from profile info)
            response = try await handleFunctionCalls(response: response, chat: chat)
            
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
            let fallbackContent = "I'm Prime. What's the ONE move that makes today a win?"
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
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let chat = chat else {
                throw GeminiError.notInitialized
            }
            
            var response = try await chat.sendMessage(text)
            
            // Handle any function calls from the model
            response = try await handleFunctionCalls(response: response, chat: chat)
            
            let responseContent = response.text ?? ""
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: responseContent,
                timestamp: Date()
            )
            messages.append(assistantMessage)
            
            // Save assistant response to Supabase
            await saveMessage(role: "assistant", content: responseContent)
        } catch {
            print("❌ Failed to send message: \(error)")
            errorMessage = "Failed to get response. Please try again."
        }
        
        isLoading = false
    }
    
    /// Handle function calls from the model (e.g., saveUserNote)
    private func handleFunctionCalls(response: GenerateContentResponse, chat: Chat) async throws -> GenerateContentResponse {
        let functionCalls = response.functionCalls
        
        // If no function calls, return the original response
        guard !functionCalls.isEmpty else {
            return response
        }
        
        var functionResponses = [FunctionResponsePart]()
        
        for functionCall in functionCalls {
            if functionCall.name == "saveUserNote" {
                // Extract parameters from the function call
                guard case let .string(category) = functionCall.args["category"],
                      case let .string(content) = functionCall.args["content"] else {
                    print("⚠️ Invalid arguments for saveUserNote")
                    functionResponses.append(FunctionResponsePart(
                        name: functionCall.name,
                        response: ["success": .bool(false), "error": .string("Invalid arguments")]
                    ))
                    continue
                }
                
                // Get importance (default to 3 if not provided)
                var importance = 3
                if case let .number(imp) = functionCall.args["importance"] {
                    importance = Int(imp)
                }
                
                // Save the note to Supabase
                let result = await saveNoteTool(category: category, content: content, importance: importance)
                
                functionResponses.append(FunctionResponsePart(
                    name: functionCall.name,
                    response: result
                ))
                
                print("📝 Gemini saved note: [\(category)] \(content) (importance: \(importance))")
            }
        }
        
        // If we handled function calls, send the responses back to get the final response
        if !functionResponses.isEmpty {
            let finalResponse = try await chat.sendMessage(
                [ModelContent(role: "function", parts: functionResponses)]
            )
            
            // Check if there are more function calls to handle (recursive)
            return try await handleFunctionCalls(response: finalResponse, chat: chat)
        }
        
        return response
    }
    
    /// Execute the saveUserNote tool - saves to Supabase
    private func saveNoteTool(category: String, content: String, importance: Int) async -> JSONObject {
        do {
            let note = try await SupabaseManager.shared.saveUserNote(
                category: category,
                content: content,
                conversationId: conversationId,
                importance: importance
            )
            
            // Add to local cache
            userNotes.append(note)
            
            return [
                "success": .bool(true),
                "noteId": .string(note.id?.uuidString ?? "unknown"),
                "message": .string("Note saved successfully")
            ]
        } catch {
            print("⚠️ Failed to save note: \(error)")
            return [
                "success": .bool(false),
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func clearChat() {
        messages.removeAll()
        // Restart chat session
        chat = model?.startChat()
        conversationId = nil
        
        Task {
            // Check if first chat of day BEFORE creating the new conversation
            await checkIfFirstChatOfDay()
            // Create a new conversation for the new chat
            await createConversation()
            // Refresh notes (might have new ones from previous session)
            await fetchUserNotes()
            await sendInitialGreeting()
        }
    }
    
    /// Start a fresh new conversation
    func startNewConversation() {
        clearChat()
    }
    
    /// Fetch list of past conversations
    func fetchPastConversations() async -> [SupabaseManager.ChatConversation] {
        do {
            return try await SupabaseManager.shared.fetchChatConversations()
        } catch {
            print("⚠️ Failed to fetch past conversations: \(error)")
            return []
        }
    }
    
    /// Load a specific conversation by ID
    func loadConversation(_ conversation: SupabaseManager.ChatConversation) async {
        guard let id = conversation.id else { return }
        
        // Clear current state
        messages.removeAll()
        conversationId = id
        
        do {
            // Fetch all messages for this conversation at once
            let messageRecords = try await SupabaseManager.shared.fetchChatMessages(conversationId: id)
            
            // Build chat history for Gemini context and UI messages in one pass
            var chatHistory: [ModelContent] = []
            var loadedMessages: [ChatMessage] = []
            
            for record in messageRecords {
                let isUser = record.role == "user"
                let role: ChatMessage.ChatRole = isUser ? .user : .assistant
                
                // Build UI message - mark as preloaded to skip typewriter effect
                var message = ChatMessage(
                    role: role,
                    content: record.content,
                    timestamp: record.createdAt ?? Date()
                )
                message.isPreloaded = true
                loadedMessages.append(message)
                
                // Build Gemini history
                let geminiRole = isUser ? "user" : "model"
                chatHistory.append(ModelContent(role: geminiRole, parts: record.content))
            }
            
            // Set all messages at once (single UI update)
            messages = loadedMessages
            
            // Initialize chat with full history for context
            chat = model?.startChat(history: chatHistory)
            
            // Signal that we need to scroll to bottom
            shouldScrollToBottom = true
            
            print("✅ Loaded conversation with \(messages.count) messages")
        } catch {
            print("❌ Failed to load conversation: \(error)")
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
    let useTypewriter: Bool  // Whether to use typewriter effect
    
    var isUser: Bool {
        message.role == .user
    }
    
    // Only use typewriter for new messages (not preloaded from history)
    var shouldUseTypewriter: Bool {
        isLast && useTypewriter && !message.isPreloaded
    }
    
    var body: some View {
        HStack {
            if isUser {
                // Push user messages to the right, taking at most 75% of width
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }
            
            if isUser {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primePrimaryText)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .cornerRadius(4, corners: .bottomRight)
            } else {
                if shouldUseTypewriter {
                    ChatTypewriterText(text: message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primeControlBg)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: .bottomLeft)
                } else {
                    MarkdownText(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primeControlBg)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: .bottomLeft)
                }
            }
            
            if !isUser { Spacer() }
        }
    }
}

// MARK: - Markdown Text View

struct MarkdownText: View {
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        Text(attributedString)
            .foregroundColor(.black)
    }
    
    private var attributedString: AttributedString {
        do {
            var attributed = try AttributedString(markdown: content, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            // Ensure the text color is set
            attributed.foregroundColor = .black
            return attributed
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(content)
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
        MarkdownText(displayedText)
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
    @State private var textEditorHeight: CGFloat = 40
    
    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 120
    
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
            
            HStack(alignment: .bottom, spacing: 12) {
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
                .padding(.bottom, 4)
                
                // Multi-line text input
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if messageText.isEmpty {
                        Text("Type or tap mic to speak...")
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    // Expanding text editor
                    TextEditor(text: $messageText)
                        .font(.body)
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: minHeight, maxHeight: maxHeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .focused($isFocused)
                        .disabled(isLoading)
                }
                .background(Color.primeControlBg)
                .cornerRadius(20)
                
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
                .padding(.bottom, 4)
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
                                isLast: index == viewModel.messages.count - 1,
                                useTypewriter: viewModel.isStreamingEnabled
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
                .onChange(of: viewModel.shouldScrollToBottom) { _, shouldScroll in
                    if shouldScroll, let lastMessage = viewModel.messages.last {
                        // Scroll immediately without animation for loaded conversations
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        viewModel.shouldScrollToBottom = false
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

// MARK: - Conversation Sidebar

struct ConversationSidebar: View {
    @ObservedObject var viewModel: GeminiChatViewModel
    @Binding var isShowing: Bool
    @State private var conversations: [SupabaseManager.ChatConversation] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Conversations")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        isShowing = false 
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // New Chat Button
            Button(action: {
                viewModel.startNewConversation()
                withAnimation(.spring(response: 0.3)) {
                    isShowing = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("New Conversation")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primePrimaryText)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Conversations List
            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            } else if conversations.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No previous conversations")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(conversations, id: \.id) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                isActive: viewModel.conversationId == conversation.id
                            ) {
                                Task {
                                    await viewModel.loadConversation(conversation)
                                    withAnimation(.spring(response: 0.3)) {
                                        isShowing = false
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .frame(width: 300)
        .background(Color.white)
        .onAppear {
            loadConversations()
        }
    }
    
    private func loadConversations() {
        Task {
            isLoading = true
            conversations = await viewModel.fetchPastConversations()
            isLoading = false
        }
    }
}

struct ConversationRow: View {
    let conversation: SupabaseManager.ChatConversation
    let isActive: Bool
    let onTap: () -> Void
  
  var body: some View {
        Button(action: onTap) {
    HStack(spacing: 12) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? .white : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title ?? "Untitled Chat")
        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isActive ? .white : .black)
                        .lineLimit(1)
                    
                    if let date = conversation.updatedAt ?? conversation.createdAt {
                        Text(formatDate(date))
                            .font(.system(size: 12))
                            .foregroundColor(isActive ? .white.opacity(0.8) : .gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isActive ? Color.primePrimaryText : Color.gray.opacity(0.08))
            .cornerRadius(10)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
  }
}

// MARK: - Main View

struct PrimeChat: View {
    @StateObject private var viewModel = GeminiChatViewModel()
  @State private var showingProfile = false
    @State private var showingDebugMenu = false
    @State private var showingSidebar = false
  
  var body: some View {
        ZStack(alignment: .leading) {
            // Main Content
    ZStack(alignment: .top) {
      // Background
      Color.white.ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Top Bar
        HStack {
                        // Menu Button (for sidebar)
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showingSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
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
                        .padding(.leading, 4)
          #endif
          
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
            .offset(x: showingSidebar ? 300 : 0)
            
            // Sidebar overlay (dim background)
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .offset(x: 300)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingSidebar = false
                        }
                    }
            }
            
            // Sidebar
            if showingSidebar {
                ConversationSidebar(viewModel: viewModel, isShowing: $showingSidebar)
                    .transition(.move(edge: .leading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 5, y: 0)
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

// MARK: - Rounded Corner Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
  }
}

#Preview {
  PrimeChat()
}

