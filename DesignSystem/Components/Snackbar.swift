import Observation
import SwiftUI

@MainActor
@Observable
final class SnackbarCenter {
    struct Message {
        let text: String
        let onOpen: (() -> Void)?
        let onUndo: (() -> Void)?
    }

    var message: Message?
    private var dismissalTask: Task<Void, Never>?

    func show(
        _ text: String,
        onOpen: (() -> Void)? = nil,
        onUndo: (() -> Void)? = nil
    ) {
        dismissalTask?.cancel()
        message = Message(text: text, onOpen: onOpen, onUndo: onUndo)
        HapticFeedback.success()

        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))

            guard !Task.isCancelled else {
                return
            }

            self?.dismiss()
        }
    }

    func dismiss() {
        dismissalTask?.cancel()
        dismissalTask = nil
        message = nil
    }

    func undo() {
        let action = message?.onUndo
        dismiss()
        action?()
    }

    func open() {
        let action = message?.onOpen
        dismiss()
        action?()
    }
}

private struct SnackbarPresenter: ViewModifier {
    @Environment(SnackbarCenter.self) private var snackbarCenter

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = snackbarCenter.message {
                    SnackbarView(
                        message: message,
                        onOpen: snackbarCenter.open,
                        onUndo: snackbarCenter.undo
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
                    .zIndex(100)
                }
            }
            .animation(.spring(duration: 0.32), value: snackbarCenter.message != nil)
    }
}

private struct SnackbarView: View {
    let message: SnackbarCenter.Message
    let onOpen: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if message.onUndo != nil {
                Button("Undo", action: onUndo)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.blue)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator.opacity(0.45))
        }
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        .contentShape(Rectangle())
        .onTapGesture {
            guard message.onOpen != nil else {
                return
            }

            onOpen()
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(
            message.onOpen == nil
                ? ""
                : "Double-tap to open the saved item."
        )
    }
}

extension View {
    func presentingSnackbars() -> some View {
        modifier(SnackbarPresenter())
    }
}
