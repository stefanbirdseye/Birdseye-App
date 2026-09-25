import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct RequestsView: View {

    @Environment(PageContextStore.self) private var pageContextStore

    @State private var requestText = ""
    @State private var activeDraft: RequestConversationDraft?
    @State private var requests = RequestSummary.samples
    @State private var composerHiderID = UUID()

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
            pageContextStore.hideWorkspaceComposer(for: composerHiderID)
        }
        .onDisappear {
            pageContextStore.showWorkspaceComposer(for: composerHiderID)
        }
        .sheet(item: $activeDraft) { draft in
            RequestClarificationSheet(
                initialRequest: draft.initialRequest,
                attachmentNames: draft.attachmentNames,
                onSend: addRequest
            )
        }
    }

    private func beginRequest(_ attachments: [RequestComposerAttachment]) {
        let trimmedRequest = requestText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedRequest.isEmpty || !attachments.isEmpty else {
            return
        }

        HapticFeedback.lightImpact()
        activeDraft = RequestConversationDraft(
            initialRequest: trimmedRequest,
            attachmentNames: attachments.map(\.name)
        )
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
    let onSubmit: ([RequestComposerAttachment]) -> Void

    @FocusState private var isFocused: Bool
    @State private var attachments: [RequestComposerAttachment] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isPhotosPickerPresented = false
    @State private var isFileImporterPresented = false
    @State private var isCameraPresented = false

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !attachments.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(attachments) { attachment in
                            RequestComposerAttachmentChip(attachment: attachment) {
                                attachments.removeAll { $0.id == attachment.id }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            HStack(spacing: 12) {
                attachmentMenu

                TextField("Describe what you need…", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit(submit)

                Button(action: submit) {
                    Image(systemName: "arrow.up")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(canSubmit ? Color.blue : Color.secondary.opacity(0.2), in: Circle())
                        .foregroundStyle(canSubmit ? Color.white : Color.secondary)
                }
                .disabled(!canSubmit)
                .accessibilityLabel("Start request")
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.blue.opacity(isFocused ? 0.65 : 0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .photosPicker(
            isPresented: $isPhotosPickerPresented,
            selection: $selectedPhotoItems,
            maxSelectionCount: nil,
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { _, photoItems in
            Task {
                for item in photoItems {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }

                    addImage(image, namePrefix: "Photo")
                }
                selectedPhotoItems = []
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image, .pdf, .plainText, .data, .movie, .audio],
            allowsMultipleSelection: true,
            onCompletion: addFiles
        )
        .sheet(isPresented: $isCameraPresented) {
            RequestCameraPicker { image in
                addImage(image, namePrefix: "Camera")
            }
            .ignoresSafeArea()
        }
    }

    private var attachmentMenu: some View {
        Menu {
            Button {
                isCameraPresented = true
            } label: {
                Label("Camera", systemImage: "camera")
            }

            Button {
                isPhotosPickerPresented = true
            } label: {
                Label("Photos", systemImage: "photo.on.rectangle")
            }

            Button {
                isFileImporterPresented = true
            } label: {
                Label("Files", systemImage: "folder")
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(Color(.secondarySystemBackground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add attachment")
    }

    private func submit() {
        guard canSubmit else {
            return
        }

        onSubmit(attachments)
        attachments = []
    }

    private func addFiles(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else {
            return
        }

        for url in urls {
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            attachments.append(
                RequestComposerAttachment(
                    name: url.lastPathComponent,
                    thumbnail: UIImage(contentsOfFile: url.path),
                    systemImage: RequestComposerAttachment.icon(for: url)
                )
            )
        }
    }

    private func addImage(_ image: UIImage, namePrefix: String) {
        attachments.append(
            RequestComposerAttachment(
                name: "\(namePrefix) \(attachments.count + 1).jpg",
                thumbnail: image,
                systemImage: "photo"
            )
        )
    }
}

private struct RequestComposerAttachment: Identifiable {
    let id = UUID()
    let name: String
    let thumbnail: UIImage?
    let systemImage: String

    static func icon(for url: URL) -> String {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return "doc"
        }

        if type.conforms(to: .image) {
            return "photo"
        }
        if type.conforms(to: .pdf) {
            return "doc.richtext"
        }
        if type.conforms(to: .movie) {
            return "video"
        }
        if type.conforms(to: .audio) {
            return "waveform"
        }
        return "doc"
    }
}

private struct RequestComposerAttachmentChip: View {

    let attachment: RequestComposerAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let thumbnail = attachment.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            } else {
                Image(systemName: attachment.systemImage)
                    .font(.subheadline.weight(.medium))
                    .frame(width: 26, height: 26)
            }

            Text(attachment.name)
                .font(.subheadline)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(attachment.name)")
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .frame(height: 38)
        .background(Color(.tertiarySystemBackground), in: Capsule())
    }
}

private struct RequestCameraPicker: UIViewControllerRepresentable {

    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        let parent: RequestCameraPicker

        init(parent: RequestCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RequestConversationView: View {

    let request: RequestSummary

    @Environment(PageContextStore.self) private var pageContextStore

    @State private var composerHiderID = UUID()

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
        .onAppear {
            pageContextStore.hideWorkspaceComposer(for: composerHiderID)
        }
        .onDisappear {
            pageContextStore.showWorkspaceComposer(for: composerHiderID)
        }
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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RequestClarificationSheet: View {

    let initialRequest: String
    let attachmentNames: [String]
    let onSend: (RequestSubmission) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var requestTitle: String
    @State private var selectedType: RequestType
    @State private var requestDescription: String
    @State private var attachedFileNames: [String] = []
    @State private var isFileImporterPresented = false

    init(
        initialRequest: String,
        attachmentNames: [String],
        onSend: @escaping (RequestSubmission) -> Void
    ) {
        self.initialRequest = initialRequest
        self.attachmentNames = attachmentNames
        self.onSend = onSend
        let suggestedType = RequestType.suggested(for: initialRequest)
        _requestTitle = State(
            initialValue: RequestTitleGenerator.title(
                for: initialRequest,
                type: suggestedType
            )
        )
        _selectedType = State(initialValue: suggestedType)
        _requestDescription = State(initialValue: initialRequest)
        _attachedFileNames = State(initialValue: attachmentNames)
    }

    private func sendRequest() {
        HapticFeedback.lightImpact()
        onSend(
            RequestSubmission(
                title: requestTitle,
                type: selectedType,
                description: requestDescription
            )
        )
        dismiss()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        RequestMessageBubble(
                            text: "Review and send, or edit anything below.",
                            isUserMessage: false
                        )

                        RequestConfirmationCard(
                            title: $requestTitle,
                            selectedType: $selectedType,
                            description: $requestDescription,
                            attachedFileNames: attachedFileNames,
                            onAddFiles: {
                                isFileImporterPresented = true
                            },
                            onRemoveFile: { fileName in
                                if let index = attachedFileNames.firstIndex(of: fileName) {
                                    attachedFileNames.remove(at: index)
                                }
                            },
                            onSend: sendRequest
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", action: sendRequest)
                        .fontWeight(.semibold)
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

    @Binding var title: String
    @Binding var selectedType: RequestType
    @Binding var description: String
    let attachedFileNames: [String]
    let onAddFiles: () -> Void
    let onRemoveFile: (String) -> Void
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RequestPreviewTextField(label: "Title", text: $title)

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
                text: $description,
                minimumHeight: 104
            )

            Button(action: onAddFiles) {
                Label("Add files", systemImage: "paperclip")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            if !attachedFileNames.isEmpty {
                ForEach(attachedFileNames, id: \.self) { fileName in
                    HStack(spacing: 8) {
                        Label(fileName, systemImage: "doc")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            onRemoveFile(fileName)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(fileName)")
                    }
                }
            }

            Button(action: onSend) {
                Text("Send request")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        Color.blue,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Sends this request to Birdseye Support")
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct RequestPreviewTextField: View {

    let label: LocalizedStringKey
    @Binding var text: String
    var minimumHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("", text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(minimumHeight > 0 ? 4...8 : 1...1)
                .frame(
                    maxWidth: .infinity,
                    minHeight: minimumHeight,
                    alignment: .topLeading
                )
                .padding(12)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .accessibilityLabel(Text(label))
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
    let attachmentNames: [String]
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
