import SwiftUI

import PhotosUI

import UniformTypeIdentifiers

import AVFoundation

import UIKit

import Combine

struct WorkspaceAIComposer: View {

    @Binding var text: String

    @FocusState.Binding var isFocused: Bool

    let onSubmit: ([AIMessageAttachment], String?) -> Void

    let prompt: String

    let pageContext: String?

    let isLoading: Bool

    let onStop: () -> Void

    init(

        text: Binding<String>,

        attachedFiles: Binding<[AIMessageAttachment]>,

        isFocused: FocusState<Bool>.Binding,

        prompt: String = "Ask anything...",

        pageContext: String? = nil,

        isLoading: Bool = false,

        onStop: @escaping () -> Void = {},

        onSubmit: @escaping ([AIMessageAttachment], String?) -> Void

    ) {

        _text = text

        _attachedFiles = attachedFiles

        _isFocused = isFocused

        self.prompt = prompt

        self.pageContext = pageContext

        self.isLoading = isLoading

        self.onStop = onStop

        self.onSubmit = onSubmit

    }

    // MARK: - Attachments

    @Binding var attachedFiles: [AIMessageAttachment]

    @State private var isPageContextIncluded = true

    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    @State private var isPhotosPickerPresented = false

    @State private var isFileImporterPresented = false

    @State private var isCameraPresented = false

    @State private var isDropTargeted = false

    // MARK: - Voice recording

    @State private var isRecording = false

    @State private var audioRecorder: AVAudioRecorder?

    @State private var recordingURL: URL?

    @State private var recordingStartedAt: Date?

    @State private var recordingElapsed: TimeInterval = 0

    @State private var recordingLevel: CGFloat = 0.12

    @State private var showMicrophoneSetupAlert = false

    @State private var recordingErrorMessage: String?

    private let recordingTimer = Timer.publish(

        every: 0.08,

        on: .main,

        in: .common

    )

    .autoconnect()

    // MARK: - Context

    @State private var contextLocations: Set<String> = [

        "Northstar (Oshawa)",

        "Northstar (Dallas)",

        "Northstar (Toronto)"

    ]

    private let locations = [

        "Northstar (Oshawa)",

        "Northstar (Dallas)",

        "Northstar (Toronto)"

    ]

    // MARK: - State

    private var hasText: Bool {

        !text

            .trimmingCharacters(in: .whitespacesAndNewlines)

            .isEmpty

    }

    private var canSend: Bool {

        hasText || !attachedFiles.isEmpty

    }

    private var shouldShowPageContext: Bool {

        pageContext != nil && hasText && isPageContextIncluded

    }

    private var allLocationsSelected: Bool {

        contextLocations.count == locations.count

    }

    private var contextTitle: String {

        if allLocationsSelected {

            return "All locations"

        }

        if contextLocations.isEmpty {

            return "No locations"

        }

        if contextLocations.count == 1 {

            return contextLocations.first ?? "1 location"

        }

        return "\(contextLocations.count) locations"

    }

    private var submissionContext: String {

        let locationScope = allLocationsSelected

            ? "All locations"

            : contextLocations

                .sorted()

                .joined(separator: ", ")

        let selectedScope = locationScope.isEmpty

            ? "No locations"

            : locationScope

        guard shouldShowPageContext, let pageContext else {

            return "Locations: \(selectedScope)"

        }

        return "\(pageContext) • Locations: \(selectedScope)"

    }

    // MARK: - Body

    var body: some View {

        VStack(

            alignment: .leading,

            spacing: 8

        ) {

            // MARK: Attachments

            if (shouldShowPageContext || !attachedFiles.isEmpty) && !isRecording {

                ScrollView(.horizontal) {

                    HStack(spacing: 8) {

                        if let pageContext, shouldShowPageContext {

                            pageContextChip(pageContext)

                        }

                        ForEach(attachedFiles) { file in

                            attachmentChip(file)

                        }

                    }

                }

                .scrollIndicators(.hidden)

                .contentMargins(.horizontal, 4)

                .transition(

                    .move(edge: .bottom)

                        .combined(with: .opacity)

                )

            }

            // MARK: Composer row

            HStack(spacing: 8) {

                if isRecording {

                    // Plus becomes cancel

                    Button {

                        cancelRecording()

                    } label: {

                        Image(systemName: "xmark")

                            .font(

                                .system(

                                    size: 18,

                                    weight: .semibold

                                )

                            )

                            .foregroundStyle(.primary)

                            .frame(

                                width: 34,

                                height: 34

                            )

                    }

                    .buttonStyle(.plain)

                    .accessibilityLabel(

                        "Cancel recording"

                    )

                    // Waveform takes the text field's place

                    recordingWaveform

                        .frame(

                            maxWidth: .infinity

                        )

                        .transition(

                            .opacity

                                .combined(

                                    with: .scale(

                                        scale: 0.97

                                    )

                                )

                        )

                    // Timer immediately next to send

                    Text(formattedRecordingTime)

                        .font(

                            .system(

                                size: 15,

                                weight: .semibold,

                                design: .rounded

                            )

                        )

                        .monospacedDigit()

                        .foregroundStyle(.primary)

                        .contentTransition(.numericText())

                        .frame(minWidth: 46)

                    // Mic position becomes send

                    Button {

                        sendRecording()

                    } label: {

                        Image(

                            systemName: "arrow.up"

                        )

                        .font(

                            .system(

                                size: 16,

                                weight: .bold

                            )

                        )

                        .foregroundStyle(.white)

                        .frame(

                            width: 34,

                            height: 34

                        )

                        .background(

                            Color.accentColor,

                            in: Circle()

                        )

                    }

                    .buttonStyle(.plain)

                    .accessibilityLabel(

                        "Send recording"

                    )

                } else {

                    attachmentMenu

                    // IMPORTANT:

                    // This is your original native TextField.

                    // No UITextView replacement.

                    ZStack(alignment: .leading) {

                        if text.isEmpty {

                            ShimmeringPlaceholder(

                                text: prompt

                            )

                        }

                        TextField(

                            "",

                            text: $text,

                            prompt: Text(""),

                            axis: .vertical

                        )

                        .font(.body)

                        .foregroundStyle(.primary)

                        .lineLimit(1...4)

                        .focused($isFocused)

                        .submitLabel(.send)

                        .onSubmit {

                            submit()

                        }

                    }

                    if canSend || isLoading {

                        Button {

                            if isLoading {

                                stopHaptic()

                                onStop()

                            } else {

                                submit()

                            }

                        } label: {

                            if isLoading {

                                AIStopLoadingIndicator()

                            } else {

                                Image(systemName: "arrow.up")

                                    .font(

                                        .system(

                                            size: 16,

                                            weight: .bold

                                        )

                                    )

                                    .foregroundStyle(.white)

                                    .frame(

                                        width: 34,

                                        height: 34

                                    )

                                    .background(

                                        Color.accentColor,

                                        in: Circle()

                                    )

                            }

                        }

                        .buttonStyle(.plain)

                        .contentShape(Circle())

                        .accessibilityLabel(

                            isLoading ? "Stop Birdseye AI" : "Send"

                        )

                        .accessibilityHint(

                            isLoading

                            ? "Stops the current AI response"

                            : "Sends your message"

                        )

                    } else {

                        Button {

                            microphoneTapHaptic()

                             startRecordingFlow()

                        } label: {

                            Image(

                                systemName: "mic"

                            )

                            .font(

                                .system(

                                    size: 20,

                                    weight: .medium

                                )

                            )

                            .foregroundStyle(.primary)

                            .frame(

                                width: 34,

                                height: 34

                            )

                        }

                        .buttonStyle(.plain)

                        .accessibilityLabel(

                            "Voice input"

                        )

                    }

                }

            }

        }

        .padding(.horizontal, 10)

        .padding(.vertical, 8)

        // MARK: Composer surface

        // Keep every outline inside the same composited surface as
        // Liquid Glass, so it moves and deforms together with the glass.
        .overlay {

            ZStack {

                RoundedRectangle(

                    cornerRadius: 28,

                    style: .continuous

                )

                .stroke(

                    Color.accentColor.opacity(isFocused ? 0.38 : 0.28),

                    lineWidth: isFocused ? 1.2 : 0.9

                )

                if isDropTargeted {

                    RoundedRectangle(

                        cornerRadius: 28,

                        style: .continuous

                    )

                    .stroke(

                        Color.accentColor,

                        style: StrokeStyle(

                            lineWidth: 2,

                            dash: [6, 4]

                        )

                    )

                    .padding(1)

                }

            }

            .allowsHitTesting(false)

        }

        .compositingGroup()

        // MARK: Liquid Glass

        .glassEffect(

            .regular.interactive(),

            in: .rect(

                cornerRadius: 28

            )

        )

        .animation(

            .snappy(duration: 0.25),

            value: attachedFiles.count

        )

        .animation(

            .snappy(duration: 0.22),

            value: isRecording

        )

        // MARK: Photos

        .onChange(of: text) { oldText, newText in

            let wasEmpty = oldText

                .trimmingCharacters(in: .whitespacesAndNewlines)

                .isEmpty

            let hasNewText = newText

                .trimmingCharacters(in: .whitespacesAndNewlines)

                .isEmpty == false

            if wasEmpty && hasNewText {

                isPageContextIncluded = true

            }

        }

        .onChange(of: pageContext) { _, _ in

            isPageContextIncluded = true

        }

        .photosPicker(

            isPresented:

                $isPhotosPickerPresented,

            selection:

                $selectedPhotoItems,

            maxSelectionCount: nil,

            matching: .images

        )

        .onChange(

            of: selectedPhotoItems

        ) { _, newItems in

            Task {

                for item in newItems {

                    await loadPhoto(from: item)

                }

                selectedPhotoItems = []

            }

        }

        // MARK: Files

        .fileImporter(

            isPresented:

                $isFileImporterPresented,

            allowedContentTypes: [

                .image,

                .pdf,

                .plainText,

                .data,

                .movie,

                .audio

            ],

            allowsMultipleSelection: true

        ) { result in

            switch result {

            case .success(let urls):

                for url in urls {

                    addFile(

                        from: url

                    )

                }

            case .failure(let error):

                print(

                    "File picker error:",

                    error

                )

            }

        }

        // MARK: Camera

        .sheet(

            isPresented:

                $isCameraPresented

        ) {

            CameraPicker { image in

                addImage(

                    image,

                    namePrefix: "Camera"

                )

            }

            .ignoresSafeArea()

        }

        // MARK: Drag files / images

        .onDrop(

            of: [

                UTType.image.identifier,

                UTType.fileURL.identifier

            ],

            isTargeted:

                $isDropTargeted,

            perform:

                handleDrop

        )

        // MARK: Paste images / files

        /*

         This keeps the native SwiftUI TextField.

         The composer receives the system Paste command while

         something inside it, such as the TextField, is focused.

        */

        // MARK: Recording timer

        .onReceive(

            recordingTimer

        ) { _ in

            updateRecordingState()

        }

        // MARK: Missing microphone config

        .alert(

            "Microphone permission is not configured",

            isPresented:

                $showMicrophoneSetupAlert

        ) {

            Button(

                "OK",

                role: .cancel

            ) {

            }

        } message: {

            Text(

                """

                Add “Privacy - Microphone Usage Description” to the app target's Info settings.

                """

            )

        }

        .alert(

            "Voice recording unavailable",

            isPresented: Binding(

                get: { recordingErrorMessage != nil },

                set: { isPresented in

                    if !isPresented {

                        recordingErrorMessage = nil

                    }

                }

            )

        ) {

            Button("OK", role: .cancel) {

                recordingErrorMessage = nil

            }

        } message: {

            Text(recordingErrorMessage ?? "Please try again.")

        }

    }

    // MARK: - Attachment menu

    private var attachmentMenu: some View {

        Menu {

            // EXACT ORDER REQUESTED

            Button {

                openCamera()

            } label: {

                Label(

                    "Camera",

                    systemImage: "camera"

                )

            }

            Button {

                isPhotosPickerPresented = true

            } label: {

                Label(

                    "Photos",

                    systemImage:

                        "photo.on.rectangle"

                )

            }

            Button {

                isFileImporterPresented = true

            } label: {

                Label(

                    "Files",

                    systemImage: "folder"

                )

            }

            Divider()

            Menu {

                Button {

                    if allLocationsSelected {

                        contextLocations

                            .removeAll()

                    } else {

                        contextLocations =

                            Set(locations)

                    }

                } label: {

                    Label(

                        "All locations",

                        systemImage:

                            allLocationsSelected

                            ? "checkmark.circle.fill"

                            : "circle"

                    )

                }

                Divider()

                ForEach(

                    locations,

                    id: \.self

                ) { location in

                    Toggle(

                        location,

                        isOn: Binding(

                            get: {

                                contextLocations

                                    .contains(

                                        location

                                    )

                            },

                            set: { enabled in

                                if enabled {

                                    contextLocations

                                        .insert(

                                            location

                                        )

                                } else {

                                    contextLocations

                                        .remove(

                                            location

                                        )

                                }

                            }

                        )

                    )

                }

            } label: {

                Label(

                    "Context: \(contextTitle)",

                    systemImage: "scope"

                )

            }

        } label: {

            Image(systemName: "plus")

                .font(

                    .system(

                        size: 21,

                        weight: .medium

                    )

                )

                .foregroundStyle(.primary)

                .frame(

                    width: 34,

                    height: 34

                )

                .contentShape(

                    Rectangle()

                )

        }

        .buttonStyle(.plain)

        .accessibilityLabel("Add")

    }

    // MARK: - Page context chip

    private func pageContextChip(

        _ context: String

    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: "doc.text")

                .font(.subheadline.weight(.medium))

                .foregroundStyle(Color.accentColor)

                .frame(width: 26, height: 26)

            Text(context)

                .font(.subheadline)

                .foregroundStyle(.primary)

                .lineLimit(1)

                .truncationMode(.tail)

            Button {

                withAnimation {

                    isPageContextIncluded = false

                }

            } label: {

                Image(systemName: "xmark.circle.fill")

                    .font(.system(size: 17))

                    .foregroundStyle(.secondary)

            }

            .buttonStyle(.plain)

            .accessibilityLabel("Remove page context")

        }

        .padding(.leading, 8)

        .padding(.trailing, 8)

        .frame(height: 38)

        .glassEffect(

            .regular.interactive(),

            in: .capsule

        )

        .accessibilityElement(children: .contain)

        .accessibilityLabel("Page context: \(context)")

    }

    // MARK: - Attachment chip

    private func attachmentChip(

        _ file: AIMessageAttachment

    ) -> some View {

        HStack(spacing: 8) {

            // Actual image thumbnail when possible

            if let thumbnail =

                file.thumbnail {

                Image(

                    uiImage: thumbnail

                )

                .resizable()

                .scaledToFill()

                .frame(

                    width: 30,

                    height: 30

                )

                .clipShape(

                    RoundedRectangle(

                        cornerRadius: 7,

                        style: .continuous

                    )

                )

            } else {

                Image(

                    systemName:

                        file.systemImage

                )

                .font(

                    .subheadline

                        .weight(.medium)

                )

                .foregroundStyle(.primary)

                .frame(

                    width: 26,

                    height: 26

                )

            }

            Text(file.name)

                .font(.subheadline)

                .foregroundStyle(.primary)

                .lineLimit(1)

                .truncationMode(.middle)

                .frame(maxWidth: 160)

            Button {

                withAnimation {

                    attachedFiles

                        .removeAll {

                            $0.id == file.id

                        }

                }

            } label: {

                Image(

                    systemName:

                        "xmark.circle.fill"

                )

                .font(

                    .system(size: 17)

                )

                .foregroundStyle(

                    .secondary

                )

            }

            .buttonStyle(.plain)

            .accessibilityLabel(

                "Remove \(file.name)"

            )

        }

        .padding(.leading, 8)

        .padding(.trailing, 8)

        .frame(height: 38)

        .glassEffect(

            .regular.interactive(),

            in: .capsule

        )

    }

    // MARK: - Recording waveform

    private var recordingWaveform: some View {

        HStack(spacing: 2.2) {

            ForEach(0..<32, id: \.self) { index in

                let phase = Double(index) * 0.63

                let movement = abs(

                    sin(

                        recordingElapsed * 8

                        + phase

                    )

                )

                let variance = CGFloat(

                    0.30

                    + movement * 0.70

                )

                let barHeight =

                    5

                    + (

                        28

                        * recordingLevel

                        * variance

                    )

                Capsule()

                    .fill(

                        Color.primary

                            .opacity(0.78)

                    )

                    .frame(

                        width: 3.4,

                        height: max(

                            5,

                            barHeight

                        )

                    )

            }

        }

        .frame(

            maxWidth: .infinity,

            minHeight: 38,

            maxHeight: 38,

            alignment: .leading

        )

        .clipped()

    }

    private var formattedRecordingTime: String {

        let totalSeconds =

            Int(recordingElapsed)

        let minutes =

            totalSeconds / 60

        let seconds =

            totalSeconds % 60

        return String(

            format:

                "%02d:%02d",

            minutes,

            seconds

        )

    }

    // MARK: - Photo picker loading

    @MainActor

    private func loadPhoto(

        from item: PhotosPickerItem

    ) async {

        do {

            guard

                let data =

                    try await item

                        .loadTransferable(

                            type: Data.self

                        ),

                let image =

                    UIImage(

                        data: data

                    )

            else {

                return

            }

            addImage(

                image,

                namePrefix: "Photo"

            )

        } catch {

            print(

                "Photo loading error:",

                error

            )

        }

    }

    // MARK: - Add image

    private func addImage(

        _ image: UIImage,

        namePrefix: String

    ) {

        let url =

            saveImageTemporarily(

                image,

                namePrefix:

                    namePrefix

            )

        let file =

            AIMessageAttachment(

                name:

                    url?.lastPathComponent

                    ?? "\(namePrefix).jpg",

                systemImage: "photo",

                thumbnail:

                    makeThumbnail(

                        image

                    )

            )

        withAnimation {

            attachedFiles.append(

                file

            )

        }

    }

    // MARK: - Imported files

    private func addFile(

        from sourceURL: URL

    ) {

        let hasAccess =

            sourceURL

                .startAccessingSecurityScopedResource()

        defer {

            if hasAccess {

                sourceURL

                    .stopAccessingSecurityScopedResource()

            }

        }

        let localURL =

            copyFileToTemporaryDirectory(

                sourceURL

            ) ?? sourceURL

        var thumbnail: UIImage?

        if isImageFile(localURL),

           let image =

            UIImage(

                contentsOfFile:

                    localURL.path

            ) {

            thumbnail =

                makeThumbnail(

                    image

                )

        }

        let file =

            AIMessageAttachment(

                name:

                    localURL

                        .lastPathComponent,

                systemImage:

                    iconForFile(

                        localURL

                    ),

                thumbnail:

                    thumbnail

            )

        withAnimation {

            attachedFiles.append(

                file

            )

        }

    }

    // MARK: - Paste

    private func handlePaste(

        _ providers: [NSItemProvider]

    ) {

        for provider in providers {

            // Prefer actual images

            if provider.canLoadObject(

                ofClass: UIImage.self

            ) {

                provider.loadObject(

                    ofClass: UIImage.self

                ) { object, error in

                    if let error {

                        print(

                            "Paste image error:",

                            error

                        )

                        return

                    }

                    guard

                        let image =

                            object

                                as? UIImage

                    else {

                        return

                    }

                    DispatchQueue.main.async {

                        addImage(

                            image,

                            namePrefix:

                                "Pasted"

                        )

                    }

                }

                continue

            }

            // Handle copied Finder / Files URLs

            if provider

                .hasItemConformingToTypeIdentifier(

                    UTType

                        .fileURL

                        .identifier

                ) {

                provider.loadFileRepresentation(

                    forTypeIdentifier:

                        UTType

                            .fileURL

                            .identifier

                ) { url, error in

                    if let error {

                        print(

                            "Paste file error:",

                            error

                        )

                        return

                    }

                    guard let url else {

                        return

                    }

                    // The provider's temporary URL is only valid until this

                    // completion handler returns, so copy it first.

                    let localURL =

                        copyFileToTemporaryDirectory(url) ?? url

                    DispatchQueue.main.async {

                        addFile(from: localURL)

                    }

                }

            }

        }

    }

    // MARK: - Drop

    private func handleDrop(

        providers: [NSItemProvider]

    ) -> Bool {

        var accepted = false

        for provider in providers {

            if provider.canLoadObject(

                ofClass: UIImage.self

            ) {

                accepted = true

                provider.loadObject(

                    ofClass: UIImage.self

                ) { object, error in

                    if let error {

                        print(

                            "Drop image error:",

                            error

                        )

                        return

                    }

                    guard

                        let image =

                            object

                                as? UIImage

                    else {

                        return

                    }

                    DispatchQueue.main.async {

                        addImage(

                            image,

                            namePrefix:

                                "Dropped"

                        )

                    }

                }

                continue

            }

            if provider

                .hasItemConformingToTypeIdentifier(

                    UTType

                        .fileURL

                        .identifier

                ) {

                accepted = true

                provider.loadFileRepresentation(

                    forTypeIdentifier:

                        UTType

                            .fileURL

                            .identifier

                ) { url, error in

                    if let error {

                        print(

                            "Drop file error:",

                            error

                        )

                        return

                    }

                    guard let url else {

                        return

                    }

                    // The provider's temporary URL is only valid until this

                    // completion handler returns, so copy it first.

                    let localURL =

                        copyFileToTemporaryDirectory(url) ?? url

                    DispatchQueue.main.async {

                        addFile(from: localURL)

                    }

                }

            }

        }

        return accepted

    }

    private func extractURL(

        from object: NSSecureCoding?

    ) -> URL? {

        if let url =

            object as? URL {

            return url

        }

        if let data =

            object as? Data {

            return URL(

                dataRepresentation:

                    data,

                relativeTo: nil

            )

        }

        if let string =

            object as? String {

            return URL(

                string: string

            )

        }

        return nil

    }

    // MARK: - Camera

    private func openCamera() {

        guard

            Bundle.main.object(

                forInfoDictionaryKey:

                    "NSCameraUsageDescription"

            ) != nil

        else {

            print(

                """

                Missing NSCameraUsageDescription.

                Add Privacy - Camera Usage Description in the target Info settings.

                """

            )

            return

        }

        isCameraPresented = true

    }

    // MARK: - Voice permission

    private func startRecordingFlow() {

        isFocused = false

        /*

         This prevents iOS from terminating the app

         if the Info.plist privacy description is missing.

        */

        guard

            Bundle.main.object(

                forInfoDictionaryKey:

                    "NSMicrophoneUsageDescription"

            ) != nil

        else {

            showMicrophoneSetupAlert = true

            return

        }

        guard AVAudioSession.sharedInstance().isInputAvailable else {

            recordingErrorMessage =

                "Voice recording is not available on this simulator or device."

            return

        }

        if #available(

            iOS 17.0,

            *

        ) {

            AVAudioApplication

                .requestRecordPermission {

                    granted in

                    guard granted else {

                        return

                    }

                    DispatchQueue.main.async {

                        beginRecording()

                    }

                }

        } else {

            AVAudioSession

                .sharedInstance()

                .requestRecordPermission {

                    granted in

                    guard granted else {

                        return

                    }

                    DispatchQueue.main.async {

                        beginRecording()

                    }

                }

        }

    }

    // MARK: - Begin recording

    private func beginRecording() {

        Task.detached(priority: .userInitiated) {

            let session = AVAudioSession.sharedInstance()

            do {

                try session.setCategory(

                    .record,

                    mode: .default

                )

                try session.setActive(true)

                let url = FileManager.default

                    .temporaryDirectory

                    .appendingPathComponent(

                        "Voice-\(UUID().uuidString).m4a"

                    )

                let settings: [String: Any] = [

                    AVFormatIDKey:

                        Int(kAudioFormatMPEG4AAC),

                    AVSampleRateKey:

                        44_100,

                    AVNumberOfChannelsKey:

                        1,

                    AVEncoderAudioQualityKey:

                        AVAudioQuality.high.rawValue

                ]

                let recorder = try AVAudioRecorder(

                    url: url,

                    settings: settings

                )

                recorder.isMeteringEnabled = true

                recorder.prepareToRecord()

                guard recorder.record() else {

                    print("Recorder failed to start")

                    await MainActor.run {

                        recordingErrorMessage =

                            "Voice recording couldn't start. Please try again."

                    }

                    return

                }

                await MainActor.run {

                    audioRecorder = recorder

                    recordingURL = url

                    recordingStartedAt = Date()

                    recordingElapsed = 0

                    recordingLevel = 0.12

                    withAnimation(

                        .snappy(duration: 0.22)

                    ) {

                        isRecording = true

                    }

                    recordingHaptic()

                }

            } catch {

                let nsError = error as NSError

                print(

                    "Recording error:",

                    nsError.domain,

                    nsError.code,

                    nsError.localizedDescription

                )

                await MainActor.run {

                    recordingErrorMessage =

                        "Voice recording couldn't start. Please try again on a device with microphone access."

                }

            }

        }

    }

    // MARK: - Recording updates

    private func updateRecordingState() {

        guard

            isRecording,

            let recorder =

                audioRecorder,

            let started =

                recordingStartedAt

        else {

            return

        }

        recordingElapsed =

            Date()

                .timeIntervalSince(

                    started

                )

        recorder

            .updateMeters()

        let db =

            recorder.averagePower(

                forChannel: 0

            )

        /*

         Audio meters are normally negative dB.

         -50 = basically quiet

         0 = loud

        */

        let normalized =

            CGFloat(

                max(

                    0.10,

                    min(

                        1,

                        (db + 50)

                        / 50

                    )

                )

            )

        recordingLevel =

            normalized

    }

    // MARK: - Cancel recording

    private func cancelRecording() {

        cancelRecordingHaptic()

           audioRecorder?.stop()

           if let recordingURL {

               try? FileManager

                   .default

                   .removeItem(

                       at: recordingURL

                   )

           }

           finishRecordingState()

    }

    // MARK: - Send recording

    private func sendRecording() {

        guard recordingURL != nil else {

            cancelRecording()

            return

        }

        audioRecorder?

            .stop()

        sendHaptic()

        /*

         Treat the recording like another attachment.

        */

        let voiceFile =

            AIMessageAttachment(

                name:

                    "Voice message.m4a",

                systemImage:

                    "waveform",

                thumbnail:

                    nil

            )

        attachedFiles.append(

            voiceFile

        )

        finishRecordingState()

        /*

         Preserves the exact callback API from

         your working composer.

        */

        onSubmit(

            attachedFiles,

            submissionContext

        )

        withAnimation {

            attachedFiles

                .removeAll()

        }

    }

    // MARK: - Reset recorder

    private func finishRecordingState() {

        withAnimation(

            .snappy(duration: 0.22)

        ) {

            isRecording = false

        }

        audioRecorder = nil

        recordingURL = nil

        recordingStartedAt = nil

        recordingElapsed = 0

        recordingLevel = 0.12

        Task.detached {

            do {

                try AVAudioSession

                    .sharedInstance()

                    .setActive(

                        false,

                        options:

                            .notifyOthersOnDeactivation

                    )

            } catch {

                print(

                    "Audio session deactivate error:",

                    error.localizedDescription

                )

            }

        }

    }

    // MARK: - Haptics

    private func microphoneTapHaptic() {

        let generator = UIImpactFeedbackGenerator(style: .light)

        generator.prepare()

        generator.impactOccurred(intensity: 0.75)

    }

    private func recordingHaptic() {

        let generator = UIImpactFeedbackGenerator(style: .medium)

        generator.prepare()

        generator.impactOccurred(intensity: 1.0)

    }

    private func cancelRecordingHaptic() {

        let generator = UIImpactFeedbackGenerator(style: .soft)

        generator.prepare()

        generator.impactOccurred(intensity: 0.8)

    }

    private func stopHaptic() {

        let generator = UIImpactFeedbackGenerator(style: .soft)

        generator.prepare()

        generator.impactOccurred(intensity: 0.8)

    }

    private func sendHaptic() {

        let generator = UINotificationFeedbackGenerator()

        generator.prepare()

        generator.notificationOccurred(.success)

    }

    // MARK: - Submit

    private func submit() {

        guard canSend, !isLoading else {

            return

        }

        onSubmit(

            attachedFiles,

            submissionContext

        )

        withAnimation {

            attachedFiles

                .removeAll()

        }

    }

    // MARK: - Image storage

    private func saveImageTemporarily(

        _ image: UIImage,

        namePrefix: String

    ) -> URL? {

        guard

            let data =

                image.jpegData(

                    compressionQuality:

                        0.88

                )

        else {

            return nil

        }

        let url =

            FileManager

                .default

                .temporaryDirectory

                .appendingPathComponent(

                    "\(namePrefix)-\(UUID().uuidString.prefix(6)).jpg"

                )

        do {

            try data.write(

                to: url,

                options: .atomic

            )

            return url

        } catch {

            print(

                "Image save error:",

                error

            )

            return nil

        }

    }

    // MARK: - Thumbnail

    private func makeThumbnail(

        _ image: UIImage

    ) -> UIImage {

        let size =

            CGSize(

                width: 100,

                height: 100

            )

        let renderer =

            UIGraphicsImageRenderer(

                size: size

            )

        return renderer.image {

            _ in

            let scale =

                max(

                    size.width

                    / image.size.width,

                    size.height

                    / image.size.height

                )

            let width =

                image.size.width

                * scale

            let height =

                image.size.height

                * scale

            image.draw(

                in: CGRect(

                    x:

                        (

                            size.width

                            - width

                        )

                        / 2,

                    y:

                        (

                            size.height

                            - height

                        )

                        / 2,

                    width:

                        width,

                    height:

                        height

                )

            )

        }

    }

    // MARK: - File copy

    private func copyFileToTemporaryDirectory(

        _ source: URL

    ) -> URL? {

        let destination =

            FileManager

                .default

                .temporaryDirectory

                .appendingPathComponent(

                    "\(UUID().uuidString.prefix(6))-\(source.lastPathComponent)"

                )

        do {

            if FileManager

                .default

                .fileExists(

                    atPath:

                        destination.path

                ) {

                try FileManager

                    .default

                    .removeItem(

                        at: destination

                    )

            }

            try FileManager

                .default

                .copyItem(

                    at: source,

                    to: destination

                )

            return destination

        } catch {

            print(

                "File copy error:",

                error

            )

            return nil

        }

    }

    // MARK: - Image type

    private func isImageFile(

        _ url: URL

    ) -> Bool {

        guard

            let type =

                UTType(

                    filenameExtension:

                        url.pathExtension

                )

        else {

            return false

        }

        return type

            .conforms(

                to: .image

            )

    }

    // MARK: - File icon

    private func iconForFile(

        _ url: URL

    ) -> String {

        switch

            url.pathExtension

                .lowercased() {

        case

            "jpg",

            "jpeg",

            "png",

            "heic",

            "webp",

            "gif":

            return "photo"

        case "pdf":

            return "doc.richtext"

        case

            "txt",

            "md",

            "rtf":

            return "doc.text"

        case

            "zip",

            "rar",

            "7z":

            return "doc.zipper"

        case

            "mp3",

            "m4a",

            "wav",

            "aac":

            return "waveform"

        case

            "mp4",

            "mov",

            "m4v":

            return "video"

        case

            "csv",

            "xls",

            "xlsx":

            return "tablecells"

        default:

            return "doc"

        }

    }

}

// MARK: - AI loading / stop control

private struct AIStopLoadingIndicator: View {

    @Environment(\.accessibilityReduceMotion)

    private var reduceMotion

    @State private var rotation: Double = 0

    var body: some View {

        ZStack {

            Circle()

                .fill(.thinMaterial)

            Circle()

                .stroke(

                    Color.primary.opacity(0.10),

                    lineWidth: 3

                )

                .padding(2)

            Circle()

                .trim(from: 0.08, to: 0.72)

                .stroke(

                    Color.accentColor,

                    style: StrokeStyle(

                        lineWidth: 3,

                        lineCap: .round

                    )

                )

                .rotationEffect(.degrees(-90))

                .rotationEffect(.degrees(rotation))

                .padding(2)

            RoundedRectangle(

                cornerRadius: 2,

                style: .continuous

            )

            .fill(Color.primary)

            .frame(width: 10, height: 10)

        }

        .frame(width: 34, height: 34)

        .onAppear {

            startSpinning()

        }

        .onChange(of: reduceMotion) { _, _ in

            startSpinning()

        }

    }

    private func startSpinning() {

        if reduceMotion {

            rotation = 0

            return

        }

        rotation = 0

        withAnimation(

            .linear(duration: 0.9)

                .repeatForever(autoreverses: false)

        ) {

            rotation = 360

        }

    }

}

// MARK: - Shimmering placeholder

private struct ShimmeringPlaceholder: View {

    let text: String

    @Environment(\.accessibilityReduceMotion)

    private var reduceMotion

    @State private var shimmerOffset: CGFloat = -1.4

    @State private var isShimmering = false

    var body: some View {

        Text(text)

            .font(.body.weight(.semibold))

            .foregroundStyle(

                Color.primary.opacity(0.52)

            )

            .overlay {

                LinearGradient(

                    colors: [

                        .clear,

                        Color.accentColor.opacity(0.30),

                        Color.accentColor,

                        Color.white.opacity(0.95),

                        Color.accentColor,

                        Color.accentColor.opacity(0.30),

                        .clear

                    ],

                    startPoint: UnitPoint(

                        x: shimmerOffset - 0.45,

                        y: 0.5

                    ),

                    endPoint: UnitPoint(

                        x: shimmerOffset + 0.45,

                        y: 0.5

                    )

                )

                .mask {

                    Text(text)

                        .font(.body.weight(.semibold))

                }

                .opacity(isShimmering ? 1 : 0)

            }

            .allowsHitTesting(false)

            .accessibilityHidden(true)

            .task(id: reduceMotion) {

                guard !reduceMotion else {

                    return

                }

                while !Task.isCancelled {

                    try? await Task.sleep(

                        nanoseconds: 10_800_000_000

                    )

                    guard !Task.isCancelled else {

                        return

                    }

                    isShimmering = true

                    shimmerOffset = -1.4

                    withAnimation(

                        .linear(duration: 2.8)

                    ) {

                        shimmerOffset = 1.4

                    }

                    try? await Task.sleep(

                        nanoseconds: 2_800_000_000

                    )

                    shimmerOffset = -1.4

                    isShimmering = false

                }

            }

    }

}

// MARK: - Attached file

// MARK: - Camera picker

private struct CameraPicker:

    UIViewControllerRepresentable {

    let onImagePicked:

        (UIImage) -> Void

    @Environment(\.dismiss)

    private var dismiss

    func makeUIViewController(

        context: Context

    ) -> UIImagePickerController {

        let picker =

            UIImagePickerController()

        if UIImagePickerController

            .isSourceTypeAvailable(

                .camera

            ) {

            picker.sourceType =

                .camera

        } else {

            /*

             Simulator doesn't have a camera.

             This prevents it from crashing there.

            */

            picker.sourceType =

                .photoLibrary

        }

        picker.delegate =

            context.coordinator

        picker.allowsEditing =

            false

        return picker

    }

    func updateUIViewController(

        _ uiViewController: UIImagePickerController,

        context: Context

    ) {

    }

    func makeCoordinator()

        -> Coordinator {

        Coordinator(

            parent: self

        )

    }

    final class Coordinator:

        NSObject,

        UINavigationControllerDelegate,

        UIImagePickerControllerDelegate {

        let parent:

            CameraPicker

        init(

            parent: CameraPicker

        ) {

            self.parent =

                parent

        }

        func imagePickerController(

            _ picker:

                UIImagePickerController,

            didFinishPickingMediaWithInfo

                info:

                    [

                        UIImagePickerController

                            .InfoKey: Any

                    ]

        ) {

            if let image =

                info[

                    .originalImage

                ] as? UIImage {

                parent

                    .onImagePicked(

                        image

                    )

            }

            parent.dismiss()

        }

        func imagePickerControllerDidCancel(

            _ picker:

                UIImagePickerController

        ) {

            parent.dismiss()

        }

    }

}
