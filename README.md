# Storefront

> Modern SQLite / SwiftData viewer for macOS — native SwiftUI, live reload, built for iOS developers.

<p align="center">
  <em>🚧 Pre-alpha — v0.1.0 is under active development.</em>
</p>

---

## Features

- 📂 **Open .sqlite / .db / .store files** — drag-and-drop or File › Open (⌘O)
- 🗂 **Browse tables and rows** — 3-column split view with dynamic columns, sortable, resizable
- 🔄 **Live reload** — automatically refresh when the file changes (WAL-aware)
- 📱 **iOS Simulator auto-discovery** — list installed apps and open their databases in one click
- 🍂 **SwiftData store support** — automatic `Z_` prefix normalization, metadata-table awareness
- 🎨 **Native macOS feel** — Sky Blue × Sunset Orange palette, dark mode first-class
- 🔒 **Read-only** — your databases are never written to

## Requirements

- macOS 26 Tahoe 이상
- (개발자) Xcode 26 이상, Homebrew

---

## Install

Storefront를 설치하는 방법은 세 가지입니다. 일반 사용자는 **A**로, 소스에서 빌드하고 싶은 개발자는 **B/C**로 가세요.

### A. DMG 다운로드 (일반 사용자) ⭐ 추천

1. [Releases 페이지](https://github.com/jun7680/Storefront/releases)에서 `Storefront-*.dmg` 다운로드
2. DMG를 더블클릭 → `Storefront.app`을 `Applications` 폴더로 드래그
3. **첫 실행 — Gatekeeper 우회 필요** (아래 세 가지 중 편한 방법):

   **방법 1: Finder (가장 간단)**
   - `Applications` 폴더에서 `Storefront.app` **우클릭 → 열기 → 열기**
   - macOS 15+에선 **시스템 설정 › 개인정보 보호 및 보안 › "그래도 열기"** 한 번만 눌러주면 됩니다

   **방법 2: 터미널 한 줄**
   ```bash
   xattr -cr /Applications/Storefront.app
   ```
   이후부터는 그냥 더블클릭해서 열립니다.

   **방법 3: DMG 자체의 격리 속성 제거 (마운트 전)**
   ```bash
   xattr -d com.apple.quarantine ~/Downloads/Storefront-*.dmg
   ```

> **왜 경고가 뜨나요?** Storefront는 Apple Developer Program ($99/년) 없이 배포되는 순수 오픈소스 프로젝트라 Apple의 공증(notarization)을 거치지 않았습니다. 코드는 [GitHub](https://github.com/jun7680/Storefront)에서 그대로 확인 가능합니다.

### B. Xcode로 클론 + 실행 (개발자, 가장 빠른 방법)

```bash
# 1. 도구 설치 (한 번만)
brew install xcodegen

# 2. 소스 받기
git clone https://github.com/jun7680/Storefront.git
cd Storefront

# 3. Xcode 프로젝트 생성 (gitignore되어 있어서 매번 필요)
xcodegen generate

# 4. Xcode 열기
open Storefront.xcodeproj
```

Xcode에서 **⌘R** 누르면 실행됩니다.

> **첫 실행 시**: Xcode가 TCA 매크로(ComposableArchitecture, CasePaths, Perception, Dependencies) "Trust & Enable" 프롬프트를 띄웁니다 — 전부 **Trust & Enable** 눌러주세요.

### C. 터미널로 빌드 + 실행 (CLI 선호)

```bash
brew install xcodegen create-dmg
git clone https://github.com/jun7680/Storefront.git
cd Storefront

make build                                          # Debug 빌드
open build/Build/Products/Debug/Storefront.app      # 실행
```

로컬에서 배포용 DMG까지 만들고 싶다면:
```bash
make dmg                        # → build/Storefront-0.1.0.dmg
open build/Storefront-0.1.0.dmg # 더블클릭으로 확인
```

---

## Makefile targets

| 명령 | 하는 일 |
|---|---|
| `make setup` | `xcodegen`, `create-dmg` 설치 (Homebrew) |
| `make generate` | `project.yml` → `Storefront.xcodeproj` 재생성 |
| `make build` | Debug 빌드 |
| `make test` | 단위 테스트 실행 |
| `make archive` | Release 아카이브 + ad-hoc 서명 |
| `make dmg` | 전체 빌드 후 `build/Storefront-<version>.dmg` 패키징 |
| `make icon` | SF 로고 기반 앱 아이콘 자동 산출 |
| `make clean` | `build/` 정리 |

---

## Architecture

Built with [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture) — 모든 피처는 `@Reducer` + `@ObservableState` 쌍으로 구성되며, 루트 `AppFeature`에 `Scope`로 합성됩니다. 사이드이펙트(DB 읽기, 파일 감시, 시뮬레이터 스캔)는 `@Dependency` 클라이언트로 격리되어 `TestStore`로 단위 테스트됩니다.

- `Storefront/Features/` — TCA 피처 (App, Welcome, Browser, SimulatorPicker)
- `Storefront/Dependencies/` — `DatabaseClient`, `FileWatcherClient`, `SimulatorClient`
- `Storefront/Core/` — UI-독립 도메인 (GRDB 기반 SQLite/SwiftData 파싱)
- `Docs/PLAN.md`, `Docs/PROGRESS.md` — 설계·진행 상태

## Roadmap

- [x] v0.1.0 — core viewer MVP (SQLite + SwiftData + live reload + simulator scan)
- [ ] v0.2.0 — custom app icon, SQL read-only console, Homebrew Cask
- [ ] v0.3.0 — export to CSV/JSON, BLOB image preview, column filters

## Contributing

Issues and PRs welcome. This is my first open-source project, so please be gentle 🙏. For substantial changes, open an issue first to discuss.

## License

[MIT](./LICENSE) © 2026 Injun Mo
