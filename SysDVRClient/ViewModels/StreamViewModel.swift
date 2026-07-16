import Foundation
import Combine

@MainActor
final class StreamViewModel: ObservableObject {

    // MARK: - Published State

    @Published var ipAddress: String = ""
    @Published var selectedProtocol: StreamProtocol = .rtsp
    @Published var connectionState: ConnectionState = .idle
    @Published var aspectRatio: AspectRatioMode = .fit
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    // MARK: - Computed

    var streamURL: String {
        selectedProtocol.buildURL(host: ipAddress.trimmingCharacters(in: .whitespaces))
    }

    var isConnected: Bool {
        connectionState == .streaming
    }

    // MARK: - Validation

    private func validateIP() -> Bool {
        let trimmed = ipAddress.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            presentError("Enter the Nintendo Switch IP address.")
            return false
        }
        let parts = trimmed.split(separator: ".")
        guard parts.count == 4,
              parts.allSatisfy({ UInt8($0) != nil }) else {
            presentError("Invalid IP address format. Example: 192.168.1.100")
            return false
        }
        return true
    }

    private func reachabilityCheck() async -> Bool {
        let host = ipAddress.trimmingCharacters(in: .whitespaces)
        let port = selectedProtocol.defaultPort
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                guard sock >= 0 else {
                    continuation.resume(returning: false)
                    return
                }
                defer { close(sock) }

                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = UInt16(port).bigEndian
                inet_pton(AF_INET, host, &addr.sin_addr)

                // Non-blocking connect with 5s timeout
                var flags = fcntl(sock, F_GETFL, 0)
                flags |= O_NONBLOCK
                fcntl(sock, F_SETFL, flags)

                withUnsafePointer(to: &addr) { ptr in
                    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                        connect(sock, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }

                var writeSet = fd_set()
                __darwin_fd_zero(&writeSet)
                __darwin_fd_set(sock, &writeSet)
                var timeout = timeval(tv_sec: 5, tv_usec: 0)
                let result = select(sock + 1, nil, &writeSet, nil, &timeout)
                continuation.resume(returning: result > 0)
            }
        }
    }

    // MARK: - Actions

    func connect() async {
        guard validateIP() else { return }

        connectionState = .connecting

        let reachable = await reachabilityCheck()
        guard reachable else {
            presentError("Connection timed out. Ensure the Switch is on the same network and SysDVR is running.")
            connectionState = .idle
            return
        }

        connectionState = .streaming
    }

    func disconnect() {
        connectionState = .idle
    }

    func handleStreamError(_ message: String) {
        connectionState = .error(message)
        presentError(message)
    }

    func toggleAspectRatio() {
        aspectRatio = (aspectRatio == .fit) ? .stretch : .fit
    }

    // MARK: - Alert

    private func presentError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
