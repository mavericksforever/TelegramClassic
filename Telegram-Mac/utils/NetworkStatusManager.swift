import Foundation
import TelegramContext
import Localization
import TelegramTheme
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox
import ObjcUtils
import AppKit

public enum NetworkConnectingStatus: Equatable {
    case core(ConnectionStatus)
    case updated
    case connected

    public var text: String {
        switch self {
        case .connected:
            return strings().connectionStatusConnected
        case .updated:
            return strings().connectionStatusUpdated
        case let .core(status):
            switch status {
            case let .connecting(proxyAddress, _):
                return proxyAddress != nil ? strings().connectionStatusConnectingToProxy : strings().connectionStatusConnecting
            case .waitingForNetwork:
                return strings().connectionStatusWaitingForNetwork
            case .updating:
                return strings().connectionStatusUpdating
            case .online:
                return ""
            }
        }
    }

    public var shouldAddProgress: Bool {
        switch self {
        case .connected, .updated:
            return false
        case let .core(status):
            switch status {
            case .connecting, .waitingForNetwork, .updating:
                return true
            case .online:
                return false
            }
        }
    }
}

private final class TitleBarConnectingStatusView: View {
    private let shadeView = ImageView()
    private let container = View()
    private let textView = TextView()
    private var progressView: InfiniteProgressView?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        autoresizingMask = [.width, .height]
        addSubview(shadeView)
        addSubview(container)
        container.addSubview(textView)
        textView.userInteractionEnabled = false
        textView.isSelectable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        shadeView.frame = bounds
        if let progressView {
            progressView.centerY(x: 0)
            textView.centerY(x: progressView.frame.maxX + 5)
        } else {
            textView.center()
        }
        container.center()
    }

    func update(status: NetworkConnectingStatus, window: Window) {
        let textColor: NSColor
        switch status {
        case .connected, .updated:
            backgroundColor = theme.colors.accent
            textColor = theme.colors.underSelectedColor
        case .core:
            backgroundColor = window.backgroundColor
            textColor = theme.colors.grayText
        }

        let layout = TextViewLayout(.initialize(string: status.text, color: textColor, font: .bold(.text)))
        layout.measure(width: frame.width - 80)
        textView.update(layout)

        shadeView.image = generateImage(frame.size, contextGenerator: { size, ctx in
            ctx.clear(size.bounds)
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.08).cgColor)
            ctx.round(size, size.height / 2)
            ctx.fill(size.bounds)
        })

        if status.shouldAddProgress {
            let progressView: InfiniteProgressView
            if let current = self.progressView {
                progressView = current
            } else {
                progressView = InfiniteProgressView(color: textColor, lineWidth: 2.0)
                progressView.progress = nil
                container.addSubview(progressView)
                self.progressView = progressView
            }
            progressView.color = textColor
            progressView.setFrameSize(NSMakeSize(layout.layoutSize.height - 3, layout.layoutSize.height - 3))
            container.setFrameSize(NSMakeSize(layout.layoutSize.width + progressView.frame.width + 5, max(progressView.frame.height, layout.layoutSize.height)))
        } else {
            progressView?.removeFromSuperview()
            progressView = nil
            container.setFrameSize(layout.layoutSize)
        }
        needsLayout = true
    }
}

private final class TitleBarConnectingStatus {
    private let window: Window
    private var view: TitleBarConnectingStatusView?

    init(window: Window) {
        self.window = window
    }

    func update(_ status: NetworkConnectingStatus?, animated: Bool) {
        if let status, let titleView = window.titleView, let closeButton = window.standardWindowButton(.closeButton) {
            let current: TitleBarConnectingStatusView
            if let view {
                current = view
            } else {
                current = TitleBarConnectingStatusView(frame: titleView.bounds)
                if animated {
                    current.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
                }
                view = current
            }
            titleView.addSubview(current, positioned: .below, relativeTo: closeButton)
            current.update(status: status, window: window)
        } else if let view {
            performSubviewRemoval(view, animated: animated)
            self.view = nil
        }
    }
}

public final class NetworkStatusManager {
    private let account: Account
    private let sharedContext: any SharedAccountContextProtocol
    private let window: Window
    private let disposable = MetaDisposable()
    private let titleBarStatus: TitleBarConnectingStatus?

    private let statusPromise = Promise<NetworkConnectingStatus?>(nil)
    public var statusSignal: Signal<NetworkConnectingStatus?, NoError> {
        return statusPromise.get()
    }

    private var peer: EnginePeer?

    public init(account: Account, window: Window, sharedContext: any SharedAccountContextProtocol) {
        self.account = account
        self.window = window
        self.sharedContext = sharedContext
        self.titleBarStatus = InterfaceStyle.current.window.showsConnectingStatusInTitlebar ? TitleBarConnectingStatus(window: window) : nil
        initialize()
    }

    public func initialize() {
        let updating: Signal<Bool, NoError> = account.stateManager.isUpdating |> mapToSignal { isUpdating in
            return isUpdating ? .single(isUpdating) |> delay(1.0, queue: .mainQueue()) : .single(isUpdating)
        }

        let connecting: Signal<ConnectionStatus, NoError> = account.network.connectionStatus |> mapToSignal { status in
            switch status {
            case .online:
                return .single(status)
            default:
                return .single(status) |> delay(1.0, queue: .mainQueue())
            }
        }

        let previousStatus: Atomic<ConnectionStatus?> = Atomic(value: nil)

        let connectionStatus: Signal<NetworkConnectingStatus?, NoError> = combineLatest(queue: .mainQueue(), connecting, updating) |> deliverOnMainQueue |> map { status, isUpdating -> ConnectionStatus in
            var status = status
            switch status {
            case let .online(proxyAddress):
                if isUpdating {
                    status = .updating(proxyAddress: proxyAddress)
                }
            case let .updating(proxyAddress):
                if isUpdating {
                    status = .updating(proxyAddress: proxyAddress)
                } else {
                    return .connecting(proxyAddress: proxyAddress, proxyHasConnectionIssues: false)
                }
            default:
                break
            }
            return status
        } |> mapToQueue { coreStatus -> Signal<NetworkConnectingStatus?, NoError> in
            let previous = previousStatus.swap(coreStatus)
            if previous != coreStatus {
                switch coreStatus {
                case .online:
                    return .single(nil)
                default:
                    return .single(.core(coreStatus))
                }
            } else {
                return .complete()
            }
        }
        |> deliverOnMainQueue
        |> distinctUntilChanged

        let peerSignal = TelegramEngine(account: account).data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: account.peerId))

        disposable.set(combineLatest(queue: .mainQueue(), connectionStatus, appearanceSignal, window.fullScreen, peerSignal).start(next: { [weak self] status, _, _, peer in
            self?.apply(status: status, peer: peer)
        }))
    }

    private func apply(status: NetworkConnectingStatus?, peer: EnginePeer?) {
        self.peer = peer
        statusPromise.set(.single(status))

        if status == nil {
            if let peer {
                window.title = appName + " @ " + peer._asPeer().compactDisplayTitle
            } else {
                window.title = appName
            }
        } else {
            window.title = ""
        }
        titleBarStatus?.update(status, animated: true)
    }

    deinit {
        cleanup()
    }

    public func cleanup() {
        disposable.dispose()
        statusPromise.set(.single(nil))
        titleBarStatus?.update(nil, animated: false)
    }
}
