# Storefront 작업 진행 상태

> 이 파일은 언제 어디서든 작업을 이어갈 수 있도록 현재 상태를 기록합니다.

## 현재 브랜치

`feat/mvp-v0.1.0` — MVP v0.1.0을 위한 장기 피처 브랜치. 모든 Phase 작업은 이 브랜치에 커밋 후 릴리스 시 master로 merge.

## 다른 머신에서 이어 받기

```bash
git clone https://github.com/jun7680/Storefront.git
cd Storefront
git checkout feat/mvp-v0.1.0
brew install xcodegen create-dmg
xcodegen generate                      # .xcodeproj 재생성 (gitignore됨)
open Storefront.xcodeproj              # Xcode에서 ⌘R
# 첫 실행 시 TCA 매크로 "Trust & Enable" 프롬프트 → 허용
# CLI 빌드: xcodebuild ... -skipMacroValidation -skipPackagePluginValidation
```

## 아키텍처 요약

- **TCA (The Composable Architecture) v1.15+** — `@Reducer` + `@ObservableState` 기반
- 루트 `AppFeature`가 자식 피처를 `Scope`로 합성
- 사이드이펙트는 `@Dependency` 주입 (Phase 2+에서 `DatabaseClient` 등 추가)
- 테스트: `TestStore` 기반 액션 단위 검증

## Phase 진행 상태

| Phase | 상태 | 메모 |
|---|---|---|
| **1. Xcode 프로젝트 부트스트랩** | ✅ 완료 | xcodegen, macOS 26, Swift 6, GRDB 7.5 + TCA 1.15 SPM |
| **초기 문서 · 라이선스 · Asset** | ✅ 완료 | LICENSE(MIT), README, Sky/Orange 컬러 |
| **TCA 리팩터** | ✅ 완료 | AppFeature(@Reducer, @ObservableState) / AppView / WelcomeView(StoreOf<AppFeature>) / TestStore 3건 통과 |
| **2. SQLite 파일 열기 + 테이블 리스트** | ✅ 완료 | BrowserFeature / DatabaseClient(actor registry) / SchemaInspector / NavigationSplitView 2-column + Tables/Views 섹션 + 행수 배지 |
| **3. 행 뷰어 + 라이브 리로드** | ⏳ 대기 | RowFetcher / dynamic Table / CellView / FileWatcherClient(@Dependency) / Toast |
| **4. 시뮬레이터 앱 자동 탐색** | ⏳ 대기 | SimulatorClient(@DependencyClient) / SimulatorPickerFeature |
| **5. SwiftData 스토어 지원** | ⏳ 대기 | SwiftDataDetector(Z_METADATA) / Decoder / .store 확장자 |
| **6. DMG 빌드 파이프라인** | ⏳ 대기 | Makefile / scripts/build.sh, make-dmg.sh, ExportOptions.plist |
| **7. GitHub Actions 릴리스** | ⏳ 대기 | .github/workflows/build.yml, release.yml (매크로 검증 스킵 플래그 포함) |

## 설계 참조

- 전체 설계: [Docs/PLAN.md](./PLAN.md)
- 색상: Sky Blue `#5AA7E6` + Sunset Orange `#FF9F5A`

## 최근 검증 (2026-04-16)

- **Phase 2 빌드/테스트**: `xcodebuild … test` → 6/6 통과 (AppFeature 3 + BrowserFeature 3)
- 샘플 DB `/tmp/storefront-sample.sqlite` (artists/albums/tracks + track_summary view) 생성됨 — 앱에서 File > Open으로 검증 가능

## 다음 작업 시작 지점

**Phase 3 — 행 뷰어 + 라이브 리로드 (TCA)**

파일 생성 순서:
1. `Storefront/Core/Database/RowFetcher.swift` — 페이지네이션 행 조회 (OFFSET/LIMIT 또는 keyset)
2. `Storefront/Dependencies/DatabaseClient.swift` 확장 — `columns(URL, table)`, `rows(URL, table, offset, limit)`
3. `Storefront/Dependencies/FileWatcherClient.swift` — `DispatchSource.makeFileSystemObjectSource` 래퍼. `watch(URL) -> AsyncStream<Void>`
4. `Storefront/Features/Browser/RowTableView.swift` — dynamic `Table(of:selection:sortOrder:)` + `TableColumn`
5. `Storefront/UI/CellView.swift` — NULL/BLOB/Date/Number/Text 타입별 색상
6. `BrowserFeature` 확장 — `.columnsLoaded`, `.rowsLoaded`, `.fileChanged` 액션 + Effect 합성
7. `BrowserView` 우측 detail에 `RowTableView` 연결, 라이브 리로드 토스트
8. Tests: `BrowserFeatureRowsTests`, `FileWatcherClientTests`

## 저장소 상태

- GitHub: https://github.com/jun7680/Storefront
- Visibility: **Private** (v0.1.0 릴리스 전까지)
- Default branch: `master`
- Active branch: `feat/mvp-v0.1.0`
- Last commit on feat/mvp-v0.1.0: Phase 2 완료 (SQLite 뷰어 + 테이블 리스트)
