import Carbon
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: switch-input-source <source-id>\n", stderr)
    exit(1)
}

let targetId = CommandLine.arguments[1]

if targetId == "-l" {
    let sources = TISCreateInputSourceList(nil, false)
        .takeRetainedValue() as! [TISInputSource]
    for source in sources {
        guard let idPtr = TISGetInputSourceProperty(
            source, kTISPropertyInputSourceID
        ) else { continue }
        guard let selectPtr = TISGetInputSourceProperty(
            source, kTISPropertyInputSourceIsSelectCapable
        ) else { continue }
        let isSelectable = Unmanaged<CFBoolean>
            .fromOpaque(selectPtr).takeUnretainedValue()
        if CFBooleanGetValue(isSelectable) {
            let id = Unmanaged<CFString>
                .fromOpaque(idPtr).takeUnretainedValue() as String
            print(id)
        }
    }
    exit(0)
}

// Get current input source to avoid redundant switches
let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
if let currentIdPtr = TISGetInputSourceProperty(
    current, kTISPropertyInputSourceID
) {
    let currentId = Unmanaged<CFString>
        .fromOpaque(currentIdPtr).takeUnretainedValue() as String
    if currentId == targetId {
        exit(0) // Already active, nothing to do
    }
}

let sources = TISCreateInputSourceList(nil, false)
    .takeRetainedValue() as! [TISInputSource]

for source in sources {
    guard let idPtr = TISGetInputSourceProperty(
        source, kTISPropertyInputSourceID
    ) else { continue }
    let id = Unmanaged<CFString>
        .fromOpaque(idPtr).takeUnretainedValue() as String
    if id == targetId {
        TISSelectInputSource(source)
        exit(0)
    }
}

fputs("Input source not found: \(targetId)\n", stderr)
exit(1)
