import Foundation

// ponytail: enum covers RTSP + TCP Bridge; extend with raw UDP if SysDVR adds it
enum StreamProtocol: String, CaseIterable, Identifiable {
    case rtsp = "RTSP (Simple Network)"
    case tcpBridge = "TCP Bridge"

    var id: String { rawValue }

    func buildURL(host: String) -> String {
        switch self {
        case .rtsp:
            return "rtsp://\(host):6666/"
        case .tcpBridge:
            return "tcp://\(host):6667"
        }
    }

    var defaultPort: Int {
        switch self {
        case .rtsp: return 6666
        case .tcpBridge: return 6667
        }
    }
}
