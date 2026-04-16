import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.currentDocumentURL == nil {
                WelcomeView()
            } else {
                ContentUnavailableView(
                    "Phase 2에서 구현됩니다",
                    systemImage: "tray",
                    description: Text("SQLite 뷰어는 다음 단계 작업입니다.")
                )
            }
        }
        .background(Color("AppBackground"))
    }
}

#Preview("Welcome — Light") {
    RootView()
        .environment(AppState())
        .frame(width: 900, height: 560)
        .preferredColorScheme(.light)
}

#Preview("Welcome — Dark") {
    RootView()
        .environment(AppState())
        .frame(width: 900, height: 560)
        .preferredColorScheme(.dark)
}
