import ComposableArchitecture
import SwiftUI

struct WelcomeView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "storefront.fill")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 4)

            VStack(spacing: 6) {
                Text("Storefront")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                Text("SQLite · SwiftData 뷰어")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    store.send(.openButtonTapped)
                } label: {
                    Label("파일 열기", systemImage: "tray.and.arrow.down")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AppPrimary"))
                .keyboardShortcut("o", modifiers: .command)

                Button {
                    store.send(.simulatorButtonTapped)
                } label: {
                    Label("시뮬레이터", systemImage: "iphone.gen3")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("l", modifiers: .command)
            }

            Text("📦 .sqlite · .db · .store 파일을 끌어다 놓아보세요")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            store.send(.fileImported(url))
            return true
        }
    }
}

#Preview {
    WelcomeView(
        store: Store(initialState: AppFeature.State()) { AppFeature() }
    )
    .frame(width: 900, height: 560)
}
