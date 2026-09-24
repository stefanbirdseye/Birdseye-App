import SwiftUI
import UniformTypeIdentifiers

struct RequestsView: View {

    @Environment(PageContextStore.self) private var pageContextStore

    @State private var requestText = ""
    @State private var activeDraft: RequestConversationDraft?
    @State private var requests = RequestSummary.samples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                BirdseyePageTitle(title: "Send us request")
                    .padding(.top, 16)

                RequestHero()

                RequestComposer(
                    text: $requestText,
                    onSubmit: beginRequest
                )

                RequestHistorySection(requests: requests)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticFeedback.lightImpact()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search requests")
            }
        }
        .onAppear {
            pageContextStore.hidesWorkspaceComposer = true
        }
        .onDisappear {
            pageContextStore.hidesWorkspaceComposer = false
        }
        .sheet(item: $activeDraft) { draft in
            RequestClarificationSheet(
                initialRequest: draft.initialRequest,
                onSend: addRequest
            )
        }
    }

    private func beginRequest() {
        let trimmedRequest = requestText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedRequest.isEmpty else {
            return
        }

        HapticFeedback.lightImpact()
        activeDraft = RequestConversationDraft(initialRequest: trimmedRequest)
        requestText = ""
    }

    private func addRequest(_ submission: RequestSubmission) {
        let request = RequestSummary(
            id: UUID().uuidString,
            subject: submission.title,
            preview: submission.description,
            timestamp: "Just now",
            status: .open,
            hasUnread: false
        )

        requests.insert(request, at: 0)
    }
}

private struct RequestHero: View {

    var body: some View {
        Text("Request footage, a protocol change, or an update to service hours. You’ll be notified by email whenever there’s an update.")
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct RequestComposer: View {

    @Binding var text: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(Color(.secondarySystemBackground), in: Circle())

            TextField("Describe what you need…", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 32, height: 32)
                    .background(canSubmit ? Color.blue : Color.secondary.opacity(0.2), in: Circle())
                    .foregroundStyle(canSubmit ? Color.white : Color.secondary)
            }
            .disabled(!canSubmit)
            .accessibilityLabel("Start request")
        }
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.blue.opacity(isFocused ? 0.65 : 0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

private struct RequestHistorySection: View {

    let requests: [RequestSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous requests")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVStack(spacing: 10) {
                ForEach(requests) { request in
                    NavigationLink {
                        RequestConversationView(request: request)
                    } label: {
                        RequestHistoryRow(
                            subject: request.subject,
                            preview: request.preview,
                            timestamp: request.timestamp,
                            status: request.status,
                            hasUnread: request.hasUnread
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RequestHistoryRow: View {

    let subject: String
    let preview: String
    let timestamp: String
    let status: RequestStatus
    let hasUnread: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "envelope")
                .font(.body.weight(.medium))
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(subject)
                        .font(.headline)
                        .lineLimit(1)

                    if hasUnread {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("Unread update")
                    }

                    Spacer(minLength: 0)

                    Text(timestamp)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(status.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(status.tint)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RequestConversationView: View {

    let request: RequestSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RequestConversationDetails(
                    title: request.subject,
                    description: request.preview,
                    type: request.type,
                    status: request.status
                )

                RequestConversationMessageCard(
                    message: RequestConversationMessage(
                        sender: "Birdseye Support",
                        timestamp: request.timestamp,
                        body: RequestConversationMessage.supportResponse(for: request.status),
                        isCurrentUser: false
                    )
                )

                Label("You’ll receive any further updates by email.", systemImage: "envelope")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Request")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RequestConversationDetails: View {

    let title: String
    let description: String
    let type: String
    let status: RequestStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RequestConversationDetailField(label: "Title", value: title)
            RequestConversationDetailField(label: "Description", value: description)
            RequestConversationDetailField(label: "Type", value: type)

            HStack {
                Text("Status")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(status.tint.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RequestConversationDetailField: View {

    let label: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct RequestConversationMessageCard: View {

    let message: RequestConversationMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(message.initials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(message.isCurrentUser ? Color.white : Color.blue)
                    .frame(width: 32, height: 32)
                    .background(
                        message.isCurrentUser ? Color.blue : Color.blue.opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(message.sender)
                        .font(.subheadline.weight(.semibold))
                    Text(message.isCurrentUser ? "To Birdseye Support" : "To you")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(message.timestamp)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(message.body)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RequestClarificationSheet: View {

    let initialRequest: String
    let onSend: (RequestSubmission) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: RequestType
    @State private var attachedFileNames: [String] = []
    @State private var isFileImporterPresented = false

    init(
        initialRequest: String,
        onSend: @escaping (RequestSubmission) -> Void
    ) {
        self.initialRequest = initialRequest
        self.onSend = onSend
        _selectedType = State(
            initialValue: RequestType.suggested(for: initialRequest)
        )
    }

    private var title: String {
        RequestTitleGenerator.title(
            for: initialRequest,
            type: selectedType
        )
    }

    private var description: String {
        initialRequest
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        RequestMessageBubble(
                            text: "Is this information right? You can send it now, or add more details to update it.",
                            isUserMessage: false
                        )

                        RequestConfirmationCard(
                            title: title,
                            selectedType: $selectedType,
                            description: description,
                            attachedFileNames: attachedFileNames,
                            onAddFiles: {
                                isFileImporterPresented = true
                            },
                            onSend: {
                                HapticFeedback.lightImpact()
                                onSend(
                                    RequestSubmission(
                                        title: title,
                                        type: selectedType,
                                        description: description
                                    )
                                )
                                dismiss()
                            }
                        )
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Confirm request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result {
                attachedFileNames = urls.map(\.lastPathComponent)
            }
        }
    }
}

private struct RequestMessageBubble: View {

    let text: String
    let isUserMessage: Bool

    var body: some View {
        HStack {
            if isUserMessage {
                Spacer(minLength: 48)
            }

            Text(text)
                .font(.body)
                .foregroundStyle(isUserMessage ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isUserMessage ? Color.blue : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16)
                )

            if !isUserMessage {
                Spacer(minLength: 48)
            }
        }
    }
}

private struct RequestConfirmationCard: View {

    let title: String
    @Binding var selectedType: RequestType
    let description: String
    let attachedFileNames: [String]
    let onAddFiles: () -> Void
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RequestPreviewTextField(label: "Title", value: title)

            VStack(alignment: .leading, spacing: 6) {
                Text("Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Menu {
                    Picker("Request type", selection: $selectedType) {
                        ForEach(RequestType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedType.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            RequestPreviewTextField(
                label: "Description",
                value: description,
                minimumHeight: 104
            )

            Button(action: onAddFiles) {
                Label("Add files", systemImage: "paperclip")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            if !attachedFileNames.isEmpty {
                ForEach(attachedFileNames, id: \.self) { fileName in
                    Label(fileName, systemImage: "doc")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Button("Send request", action: onSend)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct RequestPreviewTextField: View {

    let label: LocalizedStringKey
    let value: String
    var minimumHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .frame(
                    maxWidth: .infinity,
                    minHeight: minimumHeight,
                    alignment: .topLeading
                )
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct RequestSubmission {
    let title: String
    let type: RequestType
    let description: String
}

private enum RequestType: String, CaseIterable, Identifiable {
    case footageRequest
    case protocolMonitoringHours
    case protocolAdditionalHours
    case protocolContactsEscalationMatrix
    case protocolGateProcedure
    case protocolFacilityYardProtocol
    case protocolSpecialRequests
    case protocolOther
    case serviceEquipmentMaintenance
    case serviceCamerasAccessInquiry
    case serviceRequest
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .footageRequest:
            "Request - Footage Request"
        case .protocolMonitoringHours:
            "Protocol Change - Monitoring Hours"
        case .protocolAdditionalHours:
            "Protocol Change - Additional Hours"
        case .protocolContactsEscalationMatrix:
            "Protocol Change - Contacts Escalation Matrix"
        case .protocolGateProcedure:
            "Protocol Change - Gate Procedure"
        case .protocolFacilityYardProtocol:
            "Protocol Change - Facility/Yard Protocol"
        case .protocolSpecialRequests:
            "Protocol Change - Special Requests"
        case .protocolOther:
            "Protocol Change - Other"
        case .serviceEquipmentMaintenance:
            "Service - Equipment Maintenance"
        case .serviceCamerasAccessInquiry:
            "Service - Cameras Access Inquiry"
        case .serviceRequest:
            "Service - Service Request"
        case .other:
            "Other"
        }
    }

    static func suggested(for request: String) -> RequestType {
        let lowercasedRequest = request.lowercased()

        if lowercasedRequest.contains("footage") || lowercasedRequest.contains("video") {
            return .footageRequest
        }

        if lowercasedRequest.contains("monitoring") || lowercasedRequest.contains("hours") {
            return .protocolMonitoringHours
        }

        if lowercasedRequest.contains("protocol") {
            return .protocolOther
        }

        if lowercasedRequest.contains("camera") || lowercasedRequest.contains("access") {
            return .serviceCamerasAccessInquiry
        }

        if lowercasedRequest.contains("maintenance") || lowercasedRequest.contains("repair") {
            return .serviceEquipmentMaintenance
        }

        if lowercasedRequest.contains("service") {
            return .serviceRequest
        }

        return .other
    }
}

private enum RequestTitleGenerator {
    static func title(for request: String, type: RequestType) -> String {
        let lowercasedRequest = request.lowercased()

        if type == .footageRequest {
            return "Footage request"
        }

        if lowercasedRequest.contains("service hours") {
            return "Service hours update"
        }

        if type == .protocolMonitoringHours {
            return "Monitoring hours change"
        }

        if type == .serviceEquipmentMaintenance {
            return "Equipment maintenance request"
        }

        if type == .serviceCamerasAccessInquiry {
            return "Camera access inquiry"
        }

        if type == .serviceRequest {
            return "Service request"
        }

        if type == .protocolSpecialRequests {
            return "Special protocol request"
        }

        if type == .protocolOther {
            return "Protocol change"
        }

        return "New request"
    }
}

private struct RequestConversationDraft: Identifiable {
    let id = UUID()
    let initialRequest: String
}

private enum RequestStatus: String, CaseIterable {
    case open
    case onHold
    case closed
    case escalated

    var title: LocalizedStringKey {
        switch self {
        case .open:
            "Open"
        case .onHold:
            "On Hold"
        case .closed:
            "Closed"
        case .escalated:
            "Escalated"
        }
    }

    var tint: Color {
        switch self {
        case .open:
            .blue
        case .onHold:
            .orange
        case .closed:
            .secondary
        case .escalated:
            .red
        }
    }
}

private struct RequestSummary: Identifiable, Equatable {
    let id: String
    let subject: String
    let preview: String
    let timestamp: String
    let status: RequestStatus
    let hasUnread: Bool

    var type: String {
        switch id {
        case "footage-request":
            "Footage request"
        case "protocol-change":
            "Protocol change"
        case "service-hours":
            "Service hours"
        case "access-escalation":
            "Access escalation"
        default:
            "General request"
        }
    }

    static let samples = [
        RequestSummary(
            id: "footage-request",
            subject: "Footage request",
            preview: "Your footage request is ready for review.",
            timestamp: "Today",
            status: .open,
            hasUnread: true
        ),
        RequestSummary(
            id: "protocol-change",
            subject: "Protocol change",
            preview: "We’ve shared your request with the operations team.",
            timestamp: "Yesterday",
            status: .onHold,
            hasUnread: false
        ),
        RequestSummary(
            id: "service-hours",
            subject: "Service hours update",
            preview: "The updated service hours have been confirmed.",
            timestamp: "Sep 18",
            status: .closed,
            hasUnread: false
        ),
        RequestSummary(
            id: "access-escalation",
            subject: "Access escalation",
            preview: "We’re reviewing the access issue with the security team.",
            timestamp: "Sep 16",
            status: .escalated,
            hasUnread: false
        )
    ]
}

private struct RequestConversationMessage: Identifiable {
    let id = UUID()
    let sender: String
    let timestamp: String
    let body: String
    let isCurrentUser: Bool

    var initials: String {
        sender
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }

    static func supportResponse(for status: RequestStatus) -> String {
        switch status {
        case .open:
            "We’ve received your request and are reviewing the available footage. We’ll share an update here as soon as it’s ready."
        case .onHold:
            "Your request has been shared with the operations team. It’s on hold while we confirm the next steps."
        case .closed:
            "The requested update has been completed and confirmed. We’ll email you if there are any further updates."
        case .escalated:
            "We’ve escalated this request to the security team for priority review. We’ll keep you updated here."
        }
    }
}
