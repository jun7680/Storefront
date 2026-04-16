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

## Install

### 1. Download the DMG

Grab the latest DMG from [Releases](https://github.com/jun7680/Storefront/releases).

> ⚠️ **Storefront is unsigned** (no Apple Developer Program). macOS will show a Gatekeeper warning on first launch. Pick one of the bypasses below.

### 2. First run — bypass Gatekeeper

**Option A — Finder (easiest):**
1. Drag `Storefront.app` to `/Applications`
2. Right-click `Storefront.app` → **Open** → **Open** in the dialog
3. (macOS 15+) You may need **System Settings › Privacy & Security › "Open Anyway"**

**Option B — Terminal (one-liner):**
```bash
xattr -cr /Applications/Storefront.app
```
This removes the `com.apple.quarantine` attribute. Double-click from that point on.

**Option C — Remove quarantine from DMG before opening:**
```bash
xattr -d com.apple.quarantine ~/Downloads/Storefront.dmg
```

## Build from source

```bash
# Requirements: macOS 26 Tahoe, Xcode 26+, Homebrew
brew install xcodegen create-dmg
git clone https://github.com/jun7680/Storefront.git
cd Storefront
xcodegen generate           # regenerate Storefront.xcodeproj from project.yml
open Storefront.xcodeproj   # ⌘R to run in Xcode
```

Or build a DMG locally:
```bash
make dmg    # produces build/Storefront.dmg
```

Makefile targets:
- `make build` — Debug build for the current arch
- `make test` — run unit tests
- `make archive` — Release archive (ad-hoc signed)
- `make dmg` — build + package into a DMG
- `make clean` — remove `build/`

## Roadmap

- [x] v0.1.0 — core viewer MVP (SQLite + SwiftData + live reload + simulator scan)
- [ ] v0.2.0 — custom app icon, SQL read-only console, Homebrew Cask
- [ ] v0.3.0 — export to CSV/JSON, BLOB image preview, column filters

## Contributing

Issues and PRs welcome. This is my first open-source project, so please be gentle 🙏. For substantial changes, open an issue first to discuss.

## License

[MIT](./LICENSE) © 2026 Injun Mo
