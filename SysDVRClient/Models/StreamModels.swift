import Foundation

enum AspectRatioMode: String, CaseIterable {
    case fit = "Fit"
    case stretch = "16:9 Stretch"
}

enum ConnectionState: Equatable {
    case idle
    case connecting
    case streaming
    case error(String)

    var isActive: Bool {
        switch self {
        case .connecting, .streaming: return true
        default: return false
        }
    }
}
