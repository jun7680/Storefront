# Storefront 작업 진행 상태

> 이 파일은 언제 어디서든 작업을 이어갈 수 있도록 현재 상태를 기록합니다.

## 현재 브랜치

`feat/mvp-v0.1.0` — MVP v0.1.0을 위한 장기 피처 브랜치. 모든 Phase 작업은 이 브랜치에 커밋 후 릴리스 시 master로 merge.

## 다른 머신에서 이어 받기

```bash
git clone https://github.com/jun7680/Storefront.git
cd Storefront
git checkout feat/mvp-v0.1.0
brew install xcodegen create-dmg   # 로컬 도구
xcodegen generate                   # .xcodeproj 재생성 (gitignore됨)
open Storefront.xcodeproj
```

## Phase 진행 상태

| Phase | 상태 | 메모 |
|---|---|---|
| **1. Xcode 프로젝트 부트스트랩** | ✅ 완료 | xcodegen 기반, macOS 26, Swift 6, GRDB 7.5 SPM, Welcome 화면 빌드 성공 |
| **초기 문서 · 라이선스 · Asset** | ✅ 완료 | LICENSE(MIT), README 확장, Sky/Orange 컬러 등록 |
| **2. SQLite 파일 열기 + 테이블 리스트** | ⏳ 대기 | DatabaseConnection / SchemaInspector / BrowserView / .fileImporter / RecentFilesStore |
| **3. 행 뷰어 + 라이브 리로드** | ⏳ 대기 | RowFetcher / 동적 Table / CellView / FileWatcher(DispatchSource) / Toast / Inspector |
| **4. 시뮬레이터 앱 자동 탐색** | ⏳ 대기 | SimulatorScanner (simctl JSON + FS 글로빙) / SimulatorPickerView |
| **5. SwiftData 스토어 지원** | ⏳ 대기 | SwiftDataDetector(Z_METADATA) / SwiftDataDecoder / .store 확장자 / SampleGenerator CLI |
| **6. DMG 빌드 파이프라인** | ⏳ 대기 | Makefile / scripts/build.sh, make-dmg.sh, ExportOptions.plist / scripts/make-icon.sh |
| **7. GitHub Actions 릴리스** | ⏳ 대기 | .github/workflows/build.yml, release.yml / bug_report.yml |

## 설계 참조

- 전체 설계·기술 선택: [Docs/PLAN.md](./PLAN.md)
- 색상: Sky Blue `#5AA7E6` + Sunset Orange `#FF9F5A` (Assets.xcassets의 `AppPrimary`/`AppAccent`)

## 최근 검증

- **Phase 1**: `xcodebuild -project Storefront.xcodeproj -scheme Storefront -configuration Debug build` → BUILD SUCCEEDED
- Welcome 화면 육안 확인은 사용자 검토 대기 중

## 다음 작업 시작 지점

**Phase 2 — SQLite 파일 열기**
1. `Storefront/Core/Database/DatabaseConnection.swift` (GRDB DatabaseQueue readonly 래퍼)
2. `Storefront/Core/Database/SchemaInspector.swift` (sqlite_master 쿼리로 테이블 목록)
3. `Storefront/Features/Browser/BrowserView.swift` (NavigationSplitView 3-column)
4. `Storefront/Features/Browser/TableListView.swift`
5. `Storefront/Features/Browser/BrowserViewModel.swift` (@Observable)
6. `Storefront/Services/RecentFilesStore.swift` (UserDefaults security-scoped bookmark)
7. `StorefrontApp.swift`에 `.fileImporter` 연결

## 저장소 상태

- GitHub: https://github.com/jun7680/Storefront
- Visibility: **Private** (v0.1.0 릴리스 전까지)
- Default branch: `master`
- Active branch: `feat/mvp-v0.1.0`
