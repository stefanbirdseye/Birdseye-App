import SwiftUI

struct AIView: View {
    @State private var query = ""
    @State private var messages: [AIMessage] = []
    @FocusState private var isComposerFocused: Bool

    private let examples = [
        "Authorize this person to all locations",
        "How many people entered yesterday?",
        "Is this person banned across all locations?"
    ]

    private let history = [
        ("Who entered North Gate today?", "2h ago"),
        ("Show events that need review", "Yesterday"),
        ("Summarize today’s access activity", "Yesterday")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ask Birdseye AI")
                            .font(.largeTitle.weight(.semibold))
                        Text("Ask about people, equipment, organizations, or access events.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try these examples")
                            .font(.title2.weight(.semibold))

                        ForEach(examples, id: \.self) { example in
                            Button {
                                query = example
                                isComposerFocused = true
                            } label: {
                                HStack {
                                    Text(example)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent history")
                            .font(.title2.weight(.semibold))

                        ForEach(history, id: \.0) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.0)
                                    Text(item.1)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    if !messages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conversation")
                                .font(.title2.weight(.semibold))

                            ForEach(messages) { message in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(message.isUser ? "You" : "Birdseye AI")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(message.text)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    message.isUser
                                        ? Color.birdseyeNavy.opacity(0.1)
                                        : Color.secondary.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            composer
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            BirdseyeHeader()
        }
        .background(Color(.systemBackground))
    }

    private var composer: some View {
        HStack(spacing: 8) {
            Button {
            } label: {
                Image(systemName: "plus")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add attachment")

            TextField("Ask anything about your workspace...", text: $query, axis: .vertical)
                .lineLimit(1...4)
                .focused($isComposerFocused)
                .textFieldStyle(.roundedBorder)

            Button("@") {
            }
            .frame(minWidth: 44, minHeight: 44)
            .buttonStyle(.borderless)
            .accessibilityLabel("Mention")

            Button {
                sendQuery()
            } label: {
                Image(systemName: query.isEmpty ? "mic" : "arrow.up")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(query.isEmpty ? "Dictate" : "Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func sendQuery() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return
        }

        messages.append(AIMessage(text: trimmedQuery, isUser: true))
        messages.append(
            AIMessage(
                text: "I can help you explore that workspace activity. This is a mock response for now.",
                isUser: false
            )
        )
        query = ""
        isComposerFocused = false
    }
}

private struct AIMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

#Preview {
    AIView()
}
