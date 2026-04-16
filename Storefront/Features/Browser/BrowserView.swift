import ComposableArchitecture
import SwiftUI

struct BrowserView: View {
    @Bindable var store: StoreOf<BrowserFeature>
    @State private var showReloadToast: Bool = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            detail
                .overlay(alignment: .top) { reloadToast }
        }
        .navigationTitle(store.databaseURL.lastPathComponent)
        .task {
            store.send(.onAppear)
        }
        .onChange(of: store.liveReloadToast) { _, _ in
            triggerToast()
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if store.isLoading && store.tables.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("스키마 읽는 중…").font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.loadErrorMessage {
            ContentUnavailableView(
                "열 수 없음",
                systemImage: "exclamationmark.triangle.fill",
                description: Text(error)
            )
        } else if store.tables.isEmpty {
            ContentUnavailableView(
                "테이블 없음",
                systemImage: "tray",
                description: Text("이 데이터베이스에는 테이블이 없습니다.")
            )
        } else {
            tableList
        }
    }

    private var tableList: some View {
        let tables = store.tables.filter { $0.kind == .table }
        let views = store.tables.filter { $0.kind == .view }
        let selection = Binding(
            get: { store.selectedTableID },
            set: { store.send(.tableSelected($0)) }
        )

        return List(selection: selection) {
            if !tables.isEmpty {
                Section("Tables") {
                    ForEach(tables) { table in
                        TableRow(table: table).tag(Optional(table.id))
                    }
                }
            }
            if !views.isEmpty {
                Section("Views") {
                    ForEach(views) { table in
                        TableRow(table: table).tag(Optional(table.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var detail: some View {
        if let page = store.currentPage {
            VStack(spacing: 0) {
                detailToolbar(page: page)
                Divider()
                DynamicRowGrid(page: page)
                    .background(Color("AppBackground"))
            }
        } else if store.isLoadingRows {
            ProgressView("행 로딩 중…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.rowLoadError {
            ContentUnavailableView(
                "행을 읽을 수 없음",
                systemImage: "exclamationmark.triangle.fill",
                description: Text(error)
            )
        } else {
            ContentUnavailableView(
                "테이블 선택",
                systemImage: "sidebar.left",
                description: Text("왼쪽 사이드바에서 테이블을 선택하세요.")
            )
        }
    }

    private func detailToolbar(page: RowPage) -> some View {
        HStack(spacing: 12) {
            Text(store.selectedTableID ?? "")
                .font(.headline)
            Text("\(page.totalRows.formatted()) rows · \(page.columns.count) columns")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            if page.totalRows > page.rows.count {
                Text("첫 \(page.rows.count.formatted())개 표시 중")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color("AppBackground"))
    }

    @ViewBuilder
    private var reloadToast: some View {
        if showReloadToast {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("변경 감지됨 — 자동 새로고침")
                    .font(.callout)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color("AppAccent").opacity(0.5), lineWidth: 1))
            .shadow(radius: 6)
            .padding(.top, 14)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(10)
        }
    }

    private func triggerToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            showReloadToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.25)) {
                    showReloadToast = false
                }
            }
        }
    }
}

private struct TableRow: View {
    let table: TableInfo

    var body: some View {
        HStack {
            Image(systemName: table.kind == .view ? "eye" : "tablecells")
                .foregroundStyle(Color("AppPrimary"))
            Text(table.name)
            Spacer()
            Text("\(table.rowCount.formatted())")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}
