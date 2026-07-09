import AppKit
import SwiftUI

/// The default typing surface. A single-line AppKit field so Return, arrows, and
/// Tab can be intercepted before the field consumes them. Return runs the line,
/// the arrows navigate history, and later phases add autocomplete on Tab.
struct CommandInputBar: NSViewRepresentable {
    @ObservedObject var controller: TerminalController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(frame: .zero)
        field.delegate = context.coordinator
        field.placeholderString = "Type a command, press Return to run"
        field.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byClipping
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        controller.inputField = field
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        if field.stringValue != controller.draft {
            field.stringValue = controller.draft
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        let controller: TerminalController

        init(controller: TerminalController) {
            self.controller = controller
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            // Safety net: if a program began reading input while the bar still
            // held focus, forward what was typed to the terminal instead.
            if controller.inputSink == .terminal {
                controller.sendRaw(field.stringValue)
                field.stringValue = ""
                controller.draft = ""
                return
            }
            controller.draft = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                controller.submitCurrentInput()
                return true
            case #selector(NSResponder.moveUp(_:)):
                controller.historyPrevious()
                return true
            case #selector(NSResponder.moveDown(_:)):
                controller.historyNext()
                return true
            default:
                return false
            }
        }
    }
}
