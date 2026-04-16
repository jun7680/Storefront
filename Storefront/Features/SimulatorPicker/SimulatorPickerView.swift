import ComposableArchitecture
import SwiftUI

struct SimulatorPickerView: View {
    @Bindable var store: StoreOf<SimulatorPickerFeature>

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(minWidth: 520, minHeight: 420)
        .task { store.send(.onAppear) }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.gen3")
                .foregroundStyle(Color("AppPrimary"))
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("시뮬레이터 앱 둘러보기")
                    .font(.headline)
                Text("실행 중인 시뮬레이터의 앱 DB를 바로 엽니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.send(.refreshRequested)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(store.isLoading)
            .help("다시 스캔")

            Button("닫기") { store.send(.dismissTapped) }
                .keyboardShortcut(.cancelAction)
        }
        .padding(14)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.devices.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                Text("시뮬레이터 스캔 중…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.errorMessage {
            ContentUnavailableView(
                "탐색 실패",
                systemImage: "exclamationmark.triangle.fill",
                description: Text(error)
            )
        } else if store.devices.isEmpty {
            ContentUnavailableView(
                "시뮬레이터가 없습니다",
                systemImage: "iphone.slash",
                description: Text("Xcode에서 시뮬레이터를 부팅한 뒤 새로고침하세요.")
            )
        } else {
            deviceList
        }
    }

    private var deviceList: some View {
        List {
            ForEach(store.devices) { device in
                deviceSection(device)
            }
        }
        .listStyle(.inset)
    }

    private func deviceSection(_ device: SimulatorDevice) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { store.expandedDeviceIDs.contains(device.id) },
                set: { _ in store.send(.toggleDevice(device.id)) }
            )
        ) {
            if device.apps.isEmpty {
                Text(device.isBooted ? "DB가 있는 앱이 없습니다" : "부팅되지 않음")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            } else {
                ForEach(device.apps) { app in
                    appDisclosure(app)
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(device.isBooted ? Color("AppAccent") : .secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text(device.name).font(.body.weight(.medium))
                Text(device.runtime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !device.apps.isEmpty {
                    Text("\(device.apps.count) apps")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func appDisclosure(_ app: SimulatorApp) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { store.expandedAppIDs.contains(app.id) },
                set: { _ in store.send(.toggleApp(app.id)) }
            )
        ) {
            ForEach(app.databases) { db in
                Button {
                    store.send(.databasePicked(db.url))
                } label: {
                    HStack {
                        Image(systemName: db.url.pathExtension.lowercased() == "store" ? "leaf" : "cylinder.split.1x2.fill")
                            .foregroundStyle(Color("AppPrimary"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(db.displayName)
                                .font(.callout)
                            Text("\(byteFormatter.string(fromByteCount: db.sizeBytes)) · \(relative(db.modifiedAt))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }
        } label: {
            HStack {
                Image(systemName: "app.fill")
                    .foregroundStyle(.secondary)
                Text(app.bundleID)
                    .font(.callout)
                Spacer()
                Text("\(app.databases.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.leading, 4)
    }

    private var byteFormatter: ByteCountFormatter {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB]
        f.countStyle = .file
        return f
    }

    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
