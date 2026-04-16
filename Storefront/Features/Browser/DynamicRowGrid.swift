import SwiftUI

struct DynamicRowGrid: View {
    let page: RowPage

    private static let minColumnWidth: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            let columnCount = max(1, page.columns.count)
            let flexWidth = geo.size.width / CGFloat(columnCount)
            let columnWidth = max(Self.minColumnWidth, flexWidth)
            let totalWidth = columnWidth * CGFloat(columnCount)

            ScrollView([.vertical, .horizontal]) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(Array(page.rows.enumerated()), id: \.element.id) { idx, row in
                            rowView(row: row, zebra: idx.isMultiple(of: 2), columnWidth: columnWidth, totalWidth: totalWidth)
                            Divider().opacity(0.25)
                        }
                    } header: {
                        header(columnWidth: columnWidth, totalWidth: totalWidth)
                    }
                }
                .frame(
                    minWidth: geo.size.width,
                    minHeight: geo.size.height,
                    alignment: .topLeading
                )
            }
        }
    }

    private func header(columnWidth: CGFloat, totalWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(page.columns) { column in
                HStack(spacing: 4) {
                    if column.isPrimaryKey {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundStyle(Color("AppPrimary"))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(column.displayName)
                            .font(.system(.subheadline, design: .default).weight(.semibold))
                            .lineLimit(1)
                        if column.displayName != column.name {
                            Text(column.name)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    if !column.declaredType.isEmpty {
                        Text(column.declaredType)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(width: columnWidth, alignment: .leading)

                if column.id != page.columns.last?.id {
                    Divider()
                }
            }
        }
        .frame(width: totalWidth, alignment: .leading)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func rowView(row: RowSnapshot, zebra: Bool, columnWidth: CGFloat, totalWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(page.columns.enumerated()), id: \.element.id) { idx, column in
                let value = idx < row.values.count ? row.values[idx] : .null
                HStack {
                    CellView(value: value)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(width: columnWidth, alignment: .leading)

                if column.id != page.columns.last?.id {
                    Divider().opacity(0.3)
                }
            }
        }
        .frame(width: totalWidth, alignment: .leading)
        .background(zebra ? Color.secondary.opacity(0.04) : Color.clear)
    }
}
