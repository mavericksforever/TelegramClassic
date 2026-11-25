#if DEBUG
import Cocoa
import TGUIKit
import SwiftSignalKit
import PerfLab

public enum ChatListSnapshotLab {
    private static var session: ChatListSnapshotLabSession?
    private static var didStart = false

    @discardableResult
    public static func startIfRequested(outputDirectory: URL) -> Bool {
        guard !self.didStart, let configuration = PerfLabConfiguration.fromLaunchArguments(defaultOutputDirectory: outputDirectory), configuration.lab == "chatlist-snapshots" else {
            return false
        }
        self.didStart = true
        let session = ChatListSnapshotLabSession(configuration: configuration, completion: {
            ChatListSnapshotLab.session = nil
            if configuration.quitWhenDone {
                NSApp.terminate(nil)
            }
        })
        self.session = session
        Queue.mainQueue().after(configuration.double("-PerfLabStartDelay", 4.0), {
            session.start()
        })
        return true
    }
}

private protocol ChatListSnapshotLabTarget: AnyObject {
    var snapshotLabTable: TableView { get }
    func snapshotLabOpenSavedMessages()
}

extension PeersListController: ChatListSnapshotLabTarget {
    fileprivate var snapshotLabTable: TableView {
        return self.genericView.tableView
    }

    fileprivate func snapshotLabOpenSavedMessages() {
        self.open(with: .chatId(.chatList(self.context.peerId), self.context.peerId, -1))
    }
}

private final class ChatListSnapshotLabSession {
    private let configuration: PerfLabConfiguration
    private let completion: () -> Void
    private let report: PerfLabReport
    private var scenarios: [String]
    private let deltas: [CGFloat]
    private let wait: Double

    init(configuration: PerfLabConfiguration, completion: @escaping () -> Void) {
        self.configuration = configuration
        self.completion = completion
        self.report = PerfLabReport(configuration: configuration)
        let all = ["list", "swipe-left", "swipe-right"]
        self.scenarios = configuration.scenarios == ["warm"] ? all : configuration.scenarios
        self.deltas = configuration.string("-PerfLabSwipeDeltas", "70,120,300").split(separator: ",").compactMap { Double($0) }.map { CGFloat($0) }
        self.wait = configuration.double("-PerfLabSwipeWait", 0.8)
    }

    private var window: Window? {
        return StoryRevealLabRegistry.target?.storyLabWindow
    }

    private var target: ChatListSnapshotLabTarget? {
        return StoryRevealLabRegistry.target as? ChatListSnapshotLabTarget
    }

    private var table: TableView? {
        return self.target?.snapshotLabTable
    }

    func start() {
        try? FileManager.default.createDirectory(at: self.configuration.outputDirectory, withIntermediateDirectories: true)
        self.waitForList(start: Date().timeIntervalSince1970, deadline: CACurrentMediaTime() + self.configuration.double("-PerfLabWait", 30))
    }

    private func waitForList(start: Double, deadline: Double) {
        if let window = self.window, !self.revealableRows().isEmpty {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            Queue.mainQueue().after(self.wait, {
                self.next()
            })
            return
        }
        if CACurrentMediaTime() > deadline {
            self.add(scenario: "setup", start: start, notes: ["error": "no chat list rows"])
            self.finish()
            return
        }
        Queue.mainQueue().after(0.5, {
            self.waitForList(start: start, deadline: deadline)
        })
    }

    private func revealableRows() -> [ChatListRowView] {
        var rows: [ChatListRowView] = []
        self.table?.enumerateVisibleItems(with: { item in
            if let item = item as? ChatListRowItem, item.hasRevealState, !item.isAd, let view = item.view as? ChatListRowView {
                rows.append(view)
            }
            return true
        })
        return rows
    }

    private func next() {
        guard !self.scenarios.isEmpty else {
            self.finish()
            return
        }
        let scenario = self.scenarios.removeFirst()
        switch scenario {
        case "list":
            self.capture(scenario: scenario, step: "window", start: Date().timeIntervalSince1970)
            self.next()
        case "swipe-left", "swipe-right":
            self.swipe(scenario: scenario, isRight: scenario == "swipe-right")
        case "saved":
            self.openSavedMessages(scenario: scenario)
        default:
            self.add(scenario: scenario, start: Date().timeIntervalSince1970, notes: ["error": "unknown scenario"])
            self.next()
        }
    }

    private func openSavedMessages(scenario: String) {
        let start = Date().timeIntervalSince1970
        guard let target = self.target else {
            self.add(scenario: scenario, start: start, notes: ["error": "no chat list"])
            self.next()
            return
        }
        target.snapshotLabOpenSavedMessages()
        Queue.mainQueue().after(self.configuration.double("-PerfLabOpenWait", 3), {
            self.capture(scenario: scenario, step: "window", start: start)
            self.next()
        })
    }

    private func swipe(scenario: String, isRight: Bool) {
        let start = Date().timeIntervalSince1970
        let rows = self.revealableRows()
        let index = Int(self.configuration.double("-PerfLabSwipeRow", 1))
        guard rows.indices.contains(index) else {
            self.add(scenario: scenario, start: start, notes: ["error": "no row at index \(index) of \(rows.count)"])
            self.next()
            return
        }
        let row = rows[index]
        let controller = ViewController()
        let direction: (SwipeState) -> SwipeDirection = { state in
            return isRight ? .right(state) : .left(state)
        }
        guard row.handleRevealSwipe(direction(.start(controller: controller)), cancelled: false) else {
            self.add(scenario: scenario, start: start, notes: ["error": "row has no options on this side"])
            self.next()
            return
        }
        self.drag(row, scenario: scenario, deltas: self.deltas[...], direction: direction, controller: controller)
    }

    private func drag(_ row: ChatListRowView, scenario: String, deltas: ArraySlice<CGFloat>, direction: @escaping (SwipeState) -> SwipeDirection, controller: ViewController) {
        let start = Date().timeIntervalSince1970
        guard let delta = deltas.first else {
            _ = row.handleRevealSwipe(.none, cancelled: true)
            Queue.mainQueue().after(self.wait, {
                self.capture(scenario: scenario, step: "released", start: start)
                row.closeReveal(animated: false)
                Queue.mainQueue().after(self.wait, {
                    self.next()
                })
            })
            return
        }
        _ = row.handleRevealSwipe(direction(.swiping(delta: delta, controller: controller)), cancelled: false)
        Queue.mainQueue().after(self.wait, {
            self.capture(scenario: scenario, step: "\(Int(delta))", start: start)
            self.drag(row, scenario: scenario, deltas: deltas.dropFirst(), direction: direction, controller: controller)
        })
    }

    private func capture(scenario: String, step: String, start: Double) {
        let url = self.configuration.outputDirectory.appendingPathComponent("chatlist-snapshots-\(self.configuration.label)-\(scenario)-\(step).png")
        var notes: [String: String] = ["step": step]
        if let image = self.window?.windowImageShot(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]), (try? data.write(to: url)) != nil {
            notes["snapshot"] = url.path
        } else {
            notes["error"] = "window capture failed"
        }
        self.add(scenario: scenario, start: start, notes: notes)
    }

    private func add(scenario: String, start: Double, notes: [String: String]) {
        self.report.add(scenario: scenario, run: 0, metrics: ["startUnixTime": start, "endUnixTime": Date().timeIntervalSince1970], notes: notes)
    }

    private func finish() {
        let url = self.report.write()
        NSLog("ChatListSnapshotLab done %@", url?.path ?? "-")
        self.completion()
    }
}
#endif
