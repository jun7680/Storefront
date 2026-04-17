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

| | Version | Needed for |
|---|---|---|
| **macOS** | 26 Tahoe or later | Running the app |
| **Xcode** | 26 or later | Building from source (B, C) |
| **Homebrew** | latest | Installing `xcodegen`, `create-dmg` (B, C) |
| **GitHub CLI** (`gh`) | optional | Auto-star after `make install` (C) |

---

## Install

Three paths depending on who you are. End users go with **A**. Developers who want to build from source pick **B** (Xcode GUI) or **C** (command line).

### Prerequisites — one-time tool setup

> Skip this block if you only plan to use path **A**.

**1. Install Homebrew** (macOS package manager):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Install Xcode 26+** — from the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835) or [Apple Developer portal](https://developer.apple.com/download/applications/). After installing, register the command-line tools:

```bash
sudo xcode-select -s /Applications/Xcode.app
xcodebuild -license accept   # accept the SDK license
```

**3. Install build helpers**:

```bash
brew install xcodegen create-dmg
```

**4. (Optional) Install GitHub CLI** — enables the one-click star prompt at the end of `make install` / `make dmg`:

```bash
brew install gh
gh auth login
```

---

### A. Download the DMG (end users) ⭐ Recommended

1. Grab `Storefront-*.dmg` from the [Releases page](https://github.com/jun7680/Storefront/releases)
2. Double-click the DMG → drag `Storefront.app` into `Applications`
3. **First launch — bypass Gatekeeper** (pick whichever is easiest):

   **Option 1: Finder (simplest)**
   - In `Applications`, **right-click `Storefront.app` → Open → Open**
   - On macOS 15+ you may also see a button under **System Settings › Privacy & Security › "Open Anyway"** — click it once.

   **Option 2: One-liner in Terminal**
   ```bash
   xattr -cr /Applications/Storefront.app
   ```
   Afterwards the app opens on regular double-click forever.

   **Option 3: Strip the quarantine attribute from the DMG before mounting**
   ```bash
   xattr -d com.apple.quarantine ~/Downloads/Storefront-*.dmg
   ```

> **Why the warning?** Storefront ships without Apple notarization because it is a pure open-source side project — no Apple Developer Program ($99/year) is involved. The source on [GitHub](https://github.com/jun7680/Storefront) is exactly what you run.

### B. Clone & run in Xcode (fastest for developers)

Requires the prerequisites above (Homebrew, Xcode, xcodegen).

```bash
git clone https://github.com/jun7680/Storefront.git
cd Storefront

xcodegen generate              # regenerate the .xcodeproj (it is gitignored)
open Storefront.xcodeproj      # then press ⌘R in Xcode
```

> **First build only**: Xcode will prompt **"Trust & Enable"** for the TCA macro plugins (`ComposableArchitectureMacros`, `CasePathsMacros`, `DependenciesMacros`, `PerceptionMacros`). Click **Trust & Enable** for each — this is a one-time security prompt.
>
> If Xcode blocks every build with a macro error, disable macro fingerprint validation globally (then restart Xcode):
> ```bash
> defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
> defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
> ```

### C. Build from the command line

Requires the prerequisites above.

```bash
git clone https://github.com/jun7680/Storefront.git
cd Storefront

make build                                          # Debug build
open build/Build/Products/Debug/Storefront.app      # launch it
```

Or copy the Debug build directly into `/Applications`:

```bash
make install                   # builds and copies to /Applications/Storefront.app
```

Want the distributable DMG locally?

```bash
make dmg                        # → build/Storefront-0.1.0.dmg
open build/Storefront-0.1.0.dmg # mount and verify
```

Both `make install` and `make dmg` finish with an opt-in star prompt — if you answer `y` and have `gh` authenticated, Storefront will be starred on your behalf; otherwise it opens the repo in your browser.

---

## Makefile targets

| Command | What it does |
|---|---|
| `make setup` | Install `xcodegen` and `create-dmg` via Homebrew |
| `make generate` | Regenerate `Storefront.xcodeproj` from `project.yml` |
| `make build` | Debug build |
| `make install` | Debug build → copy to `/Applications/Storefront.app` |
| `make test` | Run unit tests |
| `make archive` | Release archive with ad-hoc codesign |
| `make dmg` | Full archive + package `build/Storefront-<version>.dmg` |
| `make icon` | Regenerate `AppIcon.appiconset` (SF Symbol placeholder) |
| `make star` | Opt-in GitHub star prompt (uses `gh` if logged in, else opens browser) |
| `make clean` | Remove `build/` and derived data |

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
