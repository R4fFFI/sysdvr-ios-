import SwiftUI
import MobileVLCKit

// MARK: - UIKit VLC Player View

final class VLCPlayerUIView: UIView {

    private(set) var mediaPlayer = VLCMediaPlayer()
    private var retryCount = 0
    private let maxRetries = 3
    var onError: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        mediaPlayer.drawable = self
        mediaPlayer.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    func play(url: String) {
        retryCount = 0
        startPlayback(url: url)
    }

    private func startPlayback(url: String) {
        guard let mediaURL = URL(string: url) else {
            onError?("Invalid stream URL.")
            return
        }

        let media = VLCMedia(url: mediaURL)

        // Low-latency tuning for SysDVR's 720p@30 H.264 stream
        media.addOptions([
            // Network
            "network-caching": 150,       // ms, low for gaming
            "clock-jitter": 0,
            "clock-synchro": 0,
            "rtsp-tcp": true,             // Prefer TCP transport for RTSP

            // Decoder
            "codec": "avcodec",
            "avcodec-skiploopfilter": 1,   // Skip deblock for speed
            "avcodec-skip-frame": 0,
            "avcodec-skip-idct": 0,
            "avcodec-fast": true,
            "avcodec-threads": 2,

            // Demux
            "live-caching": 0,
            "file-caching": 0,
            "sout-mux-caching": 0,

            // No audio buffering
            "audio-desync": 0,
        ])

        mediaPlayer.media = media
        mediaPlayer.play()
    }

    func stop() {
        mediaPlayer.stop()
    }

    func setAspectFill(_ fill: Bool) {
        if fill {
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer(mutating: ("16:9" as NSString).utf8String)
        } else {
            mediaPlayer.videoAspectRatio = nil // Best fit
        }
    }
}

// MARK: - VLCMediaPlayerDelegate

extension VLCPlayerUIView: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }

        switch player.state {
        case .error:
            if retryCount < maxRetries {
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if let urlStr = player.media?.url?.absoluteString {
                        self?.startPlayback(url: urlStr)
                    }
                }
            } else {
                onError?("Stream lost after \(maxRetries) retries. Check your connection.")
            }
        case .playing:
            retryCount = 0
        case .ended:
            onError?("Stream ended. The game may have been closed on the Switch.")
        default:
            break
        }
    }
}

// MARK: - SwiftUI Wrapper

struct VideoPlayerView: UIViewRepresentable {

    let streamURL: String
    let aspectFill: Bool
    let onError: (String) -> Void

    func makeUIView(context: Context) -> VLCPlayerUIView {
        let view = VLCPlayerUIView()
        view.onError = onError
        return view
    }

    func updateUIView(_ uiView: VLCPlayerUIView, context: Context) {
        uiView.setAspectFill(aspectFill)

        let currentURL = uiView.mediaPlayer.media?.url?.absoluteString
        if currentURL != streamURL {
            uiView.stop()
            uiView.play(url: streamURL)
        }
    }

    static func dismantleUIView(_ uiView: VLCPlayerUIView, coordinator: ()) {
        uiView.stop()
    }
}
