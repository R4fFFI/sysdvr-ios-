import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = StreamViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            if viewModel.isConnected {
                streamingView
            } else {
                dashboardView
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isConnected)
        .alert("Connection Error", isPresented: $viewModel.showAlert) {
            Button("OK") {
                if case .error = viewModel.connectionState {
                    viewModel.disconnect()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Dashboard (Connection Setup)

    private var dashboardView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                headerSection

                connectionForm
                    .frame(maxWidth: 500)

                connectButton

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("SysDVR Client")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text("Stream your Nintendo Switch over Wi-Fi")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var connectionForm: some View {
        VStack(spacing: 20) {
            // IP Address
            VStack(alignment: .leading, spacing: 6) {
                Label("Switch IP Address", systemImage: "network")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("192.168.1.100", text: $viewModel.ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .font(.title3.monospaced())
            }

            // Protocol Picker
            VStack(alignment: .leading, spacing: 6) {
                Label("Stream Protocol", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Protocol", selection: $viewModel.selectedProtocol) {
                    ForEach(StreamProtocol.allCases) { proto in
                        Text(proto.rawValue).tag(proto)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Protocol info
            Group {
                switch viewModel.selectedProtocol {
                case .rtsp:
                    Label("Connects to rtsp://<IP>:6666/ — Set Switch to \"Simple network mode\"",
                          systemImage: "info.circle")
                case .tcpBridge:
                    Label("Connects via TCP port 6667 — Set Switch to \"TCP Bridge\" mode",
                          systemImage: "info.circle")
                }
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var connectButton: some View {
        Button {
            Task { await viewModel.connect() }
        } label: {
            Group {
                if viewModel.connectionState == .connecting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Connect", systemImage: "play.fill")
                }
            }
            .font(.title3.bold())
            .frame(maxWidth: 300, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(viewModel.connectionState == .connecting)
    }

    // MARK: - Streaming View (Full-screen Player + Overlay)

    private var streamingView: some View {
        ZStack {
            VideoPlayerView(
                streamURL: viewModel.streamURL,
                aspectFill: viewModel.aspectRatio == .stretch
            ) { errorMessage in
                viewModel.handleStreamError(errorMessage)
            }
            .ignoresSafeArea()

            overlayControls
        }
        .statusBarHidden()
    }

    private var overlayControls: some View {
        VStack {
            HStack {
                Spacer()

                // Aspect ratio toggle
                Button {
                    viewModel.toggleAspectRatio()
                } label: {
                    Image(systemName: viewModel.aspectRatio == .fit
                          ? "rectangle.arrowtriangle.2.outward"
                          : "rectangle.arrowtriangle.2.inward")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // Disconnect
                Button {
                    viewModel.disconnect()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding()

            Spacer()

            // Bottom info bar
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.red)
                    .font(.caption2)
                Text(viewModel.streamURL)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)

                Spacer()

                Text(viewModel.aspectRatio.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    ContentView()
}
