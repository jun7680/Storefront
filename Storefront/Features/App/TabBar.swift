import ComposableArchitecture
import SwiftUI

struct TabBar: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.tabs) { tab in
                        TabChip(
                            title: tab.title,
                            subtitle: tab.subtitle,
                            isSelected: tab.id == store.selectedTabID,
                            onSelect: { store.send(.tabSelected(tab.id)) },
                            onClose:  { store.send(.tabCloseTapped(tab.id)) }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            Divider()
                .frame(height: 22)
                .padding(.horizontal, 4)

            Button {
                store.send(.newTabButtonTapped)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("새 탭 (⌘T)")
            .padding(.trailing, 8)
        }
        .frame(height: 38)
        .background(Color("AppBackground").opacity(0.6))
    }
}

private struct TabChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color("AppPrimary") : Color.secondary.opacity(0.5))
                    .frame(width: 7, height: 7)

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(isHovering ? Color("AppAccent").opacity(0.25) : .clear)
                        )
                        .foregroundStyle(isHovering ? Color("AppAccent") : .secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("탭 닫기 (⌘W)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(maxWidth: 220)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        isSelected
                            ? Color("AppPrimary").opacity(0.18)
                            : (isHovering ? Color.secondary.opacity(0.10) : .clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(
                        isSelected ? Color("AppPrimary").opacity(0.55) : .clear,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
