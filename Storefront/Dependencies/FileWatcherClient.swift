import ComposableArchitecture
import Foundation

struct FileWatcherClient: Sendable {
    var changes: @Sendable (URL) -> AsyncStream<Void>
}

extension FileWatcherClient: DependencyKey {
    static let liveValue: FileWatcherClient = FileWatcherClient(
        changes: { url in
            AsyncStream { continuation in
                let watcher = FileWatcher(url: url) {
                    continuation.yield()
                }
                continuation.onTermination = { _ in watcher.cancel() }
                watcher.start()
            }
        }
    )

    static let testValue = FileWatcherClient(
        changes: unimplemented("FileWatcherClient.changes", placeholder: .finished)
    )
}

extension DependencyValues {
    var fileWatcher: FileWatcherClient {
        get { self[FileWatcherClient.self] }
        set { self[FileWatcherClient.self] = newValue }
    }
}

private final class FileWatcher: @unchecked Sendable {
    private let url: URL
    private let onChange: @Sendable () -> Void
    private var sources: [DispatchSourceFileSystemObject] = []
    private let queue = DispatchQueue(label: "com.moinjun.Storefront.FileWatcher")
    private var isCancelled = false

    init(url: URL, onChange: @escaping @Sendable () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    func start() {
        queue.async { [weak self] in
            self?.watch()
        }
    }

    private func watch() {
        guard !isCancelled else { return }
        cancelSources()
        for path in Self.siblingPaths(for: url) where FileManager.default.fileExists(atPath: path) {
            if let s = makeFileSource(path: path) {
                sources.append(s)
            }
        }
        if let dirSource = makeDirectorySource(path: url.deletingLastPathComponent().path) {
            sources.append(dirSource)
        }
        sources.forEach { $0.resume() }
    }

    private func makeFileSource(path: String) -> DispatchSourceFileSystemObject? {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            guard let self, !self.isCancelled else { return }
            let events = source.data
            self.onChange()
            if events.contains(.rename) || events.contains(.delete) {
                self.watch()
            }
        }
        source.setCancelHandler { close(fd) }
        return source
    }

    private func makeDirectorySource(path: String) -> DispatchSourceFileSystemObject? {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            guard let self, !self.isCancelled else { return }
            let watchedCount = self.sources.count - 1
            let existingCount = Self.siblingPaths(for: self.url).filter {
                FileManager.default.fileExists(atPath: $0)
            }.count
            if existingCount != watchedCount {
                self.watch()
                self.onChange()
            }
        }
        source.setCancelHandler { close(fd) }
        return source
    }

    private func cancelSources() {
        sources.forEach { $0.cancel() }
        sources.removeAll()
    }

    func cancel() {
        queue.async { [weak self] in
            self?.isCancelled = true
            self?.cancelSources()
        }
    }

    private static func siblingPaths(for url: URL) -> [String] {
        let base = url.path
        return [base, base + "-wal", base + "-shm"]
    }
}
