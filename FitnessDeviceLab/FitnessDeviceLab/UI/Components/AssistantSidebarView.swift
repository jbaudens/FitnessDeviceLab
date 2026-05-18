import SwiftUI

struct AssistantSidebarView: View {
    @Bindable var coordinator: WorkoutAssistantCoordinator
    let settings: SettingsProvider
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Cycling Coach", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button {
                    coordinator.clearChat()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear Chat")
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            
            // Chat Feed
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(coordinator.messages.filter { $0.role != .system }) { message in
                            if !message.content.isEmpty || message.role == .tool || message.toolCalls != nil {
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        
                        if coordinator.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Coach is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                        
                        if let error = coordinator.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                                .padding(.horizontal)
                                .contextMenu {
                                    Button {
                                        copyToClipboard(error)
                                    } label: {
                                        Label("Copy Error", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: coordinator.messages.count) {
                    withAnimation {
                        if let last = coordinator.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: coordinator.isGenerating) { _, generating in
                    if generating {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Ask the coach...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        #if os(macOS)
                        .onSubmit { sendMessage() }
                        #endif
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || coordinator.isGenerating)
                }
                .padding()
            }
            .background(Color.secondary.opacity(0.05))
        }
    }
    
    private func sendMessage() {
        let text = inputText
        inputText = ""
        Task {
            await coordinator.sendUserMessage(text)
        }
    }
}

fileprivate func copyToClipboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(text, forType: .string)
    #endif
}

struct MessageBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .tool {
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                        Text("Action executed")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                } else if !message.content.isEmpty {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(message.role == .user ? Color.blue : Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .contextMenu {
                            Button {
                                copyToClipboard(message.content)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
            }
            
            if message.role != .user { Spacer() }
        }
        .padding(.horizontal)
    }
}
