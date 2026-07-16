import SwiftUI
import MobileVLCKit

final class VLCPlayerUIView: UIView {

    private(set) var mediaPlayer: VLCMediaPlayer
    private var retryCount = 0
    private let maxRetries = 3
    var onError: ((String) -> Void)?

    override init(frame: CGRect) {
        mediaPlayer = VLCMediaPlayer()
        super.init(frame: frame)
        backgroundColor = .black
        mediaPlayer.drawable = self
        mediaPlayer.delegate = self
    }

    required init?(coder: NSCoder) {
        mediaPlayer = VLCMediaPlayer()
        super.init(coder: coder)
        mediaPlayer.drawable = self
        mediaPlayer.delegate = self
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
        media.addOptions([
            "network-caching": 150,
            "clock-jitter": 0,
            "clock-synchro": 0,
            "rtsp-tcp": true,
            "codec": "avcodec",
            "avcodec-skiploopfilter": 1,
            "avcodec-skip-frame": 0,
            "avcodec-skip-idct": 0,
            "avcodec-fast": true,
            "avcodec-threads": 2,
            "live-caching": 0,
            "file-caching": 0,
            "sout-mux-caching": 0,
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
            mediaPlayer.videoAspectRatio = nil
        }
    }
}

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
