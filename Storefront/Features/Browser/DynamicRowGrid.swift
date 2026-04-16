import SwiftUI

struct DynamicRowGrid: View {
    let page: RowPage

    private static let minColumnWidth: CGFloat = 120

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                header
                Divider()
                ForEach(Array(page.rows.enumerated()), id: \.element.id) { idx, row in
                    rowView(row: row, zebra: idx.isMultiple(of: 2))
                    Divider().opacity(0.3)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            ForEach(page.columns) { column in
                HStack(spacing: 4) {
                    if column.isPrimaryKey {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundStyle(Color("AppPrimary"))
                    }
                    Text(column.name)
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                    if !column.declaredType.isEmpty {
                        Text(column.declaredType)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: Self.minColumnWidth, alignment: .leading)
            }
        }
        .background(Color.secondary.opacity(0.08))
    }

    private func rowView(row: RowSnapshot, zebra: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(page.columns.enumerated()), id: \.element.id) { idx, column in
                let value = idx < row.values.count ? row.values[idx] : .null
                CellView(value: value)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: Self.minColumnWidth, alignment: columnAlignment(for: value))
            }
        }
        .background(zebra ? Color.secondary.opacity(0.04) : Color.clear)
    }

    private func columnAlignment(for value: DBValue) -> Alignment {
        switch value {
        case .integer, .double: return .trailing
        default: return .leading
        }
    }
}
