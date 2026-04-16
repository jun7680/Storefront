import ComposableArchitecture
import SwiftUI

struct BrowserView: View {
    @Bindable var store: StoreOf<BrowserFeature>

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            detail
        }
        .navigationTitle(store.databaseURL.lastPathComponent)
        .task { store.send(.onAppear) }
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
        if
            let id = store.selectedTableID,
            let table = store.tables.first(where: { $0.id == id })
        {
            ContentUnavailableView {
                Label(table.name, systemImage: table.kind == .view ? "eye" : "tablecells")
            } description: {
                Text("\(table.rowCount.formatted()) rows")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text("행 뷰어는 Phase 3에서 구현됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        } else {
            ContentUnavailableView(
                "테이블 선택",
                systemImage: "sidebar.left",
                description: Text("왼쪽 사이드바에서 테이블을 선택하세요.")
            )
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

#Preview {
    BrowserView(
        store: Store(
            initialState: BrowserFeature.State(
                databaseURL: URL(fileURLWithPath: "/tmp/sample.sqlite"),
                tables: [
                    TableInfo(name: "artists", kind: .table, rowCount: 275),
                    TableInfo(name: "albums", kind: .table, rowCount: 347),
                    TableInfo(name: "tracks", kind: .table, rowCount: 3_503),
                    TableInfo(name: "invoice_summary", kind: .view, rowCount: 412)
                ],
                selectedTableID: "tracks"
            )
        ) {
            BrowserFeature()
        }
    )
    .frame(width: 900, height: 560)
}
