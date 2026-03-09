import AppKit

enum GitStatus {
    case noUpstream
    case uncommitted
    case unpushed
    case unpulled
    case clean

    var color: NSColor? {
        switch self {
        case .noUpstream, .uncommitted:
            return .red
        case .unpushed, .unpulled:
            return .yellow
        case .clean:
            return nil // nil = System-Farbe (weiß oder schwarz je nach Theme)
        }
    }
}
