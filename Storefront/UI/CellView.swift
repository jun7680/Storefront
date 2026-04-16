import SwiftUI

struct CellView: View {
    let value: DBValue

    var body: some View {
        switch value {
        case .null:
            Text("null")
                .font(.system(.body, design: .monospaced).italic())
                .foregroundStyle(.secondary)

        case let .integer(v):
            Text(v.formatted(.number.grouping(.never)))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.blue)
                .monospacedDigit()

        case let .double(v):
            Text(String(v))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.blue)
                .monospacedDigit()

        case let .text(v):
            Text(v)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(v)

        case let .blob(data):
            Text("0x\(hexPreview(data))")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.purple)
                .help("\(data.count) bytes")
        }
    }

    private func hexPreview(_ data: Data) -> String {
        let maxBytes = 6
        let prefix = data.prefix(maxBytes)
        let hex = prefix.map { String(format: "%02X", $0) }.joined()
        return data.count > maxBytes ? hex + "…" : hex
    }
}
