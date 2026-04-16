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
| **2. SQLite 파일 열기 + 테이블 리스트** | ⏳ 대기 | BrowserFeature(@Reducer) / DatabaseClient(@DependencyClient) / SchemaInspector / NavigationSplitView |
| **3. 행 뷰어 + 라이브 리로드** | ⏳ 대기 | RowFetcher / dynamic Table / CellView / FileWatcherClient(@Dependency) / Toast |
| **4. 시뮬레이터 앱 자동 탐색** | ⏳ 대기 | SimulatorClient(@DependencyClient) / SimulatorPickerFeature |
| **5. SwiftData 스토어 지원** | ⏳ 대기 | SwiftDataDetector(Z_METADATA) / Decoder / .store 확장자 |
| **6. DMG 빌드 파이프라인** | ⏳ 대기 | Makefile / scripts/build.sh, make-dmg.sh, ExportOptions.plist |
| **7. GitHub Actions 릴리스** | ⏳ 대기 | .github/workflows/build.yml, release.yml (매크로 검증 스킵 플래그 포함) |

## 설계 참조

- 전체 설계: [Docs/PLAN.md](./PLAN.md)
- 색상: Sky Blue `#5AA7E6` + Sunset Orange `#FF9F5A`

## 최근 검증 (2026-04-16)

- **TCA 빌드**: `xcodebuild … -skipMacroValidation build` → BUILD SUCCEEDED
- **TCA 테스트**: TestStore 3건 통과 (초기 상태 / openButtonTapped / fileImported 성공)
- Welcome 화면 육안 검수 완료 (사용자 승인)

## 다음 작업 시작 지점

**Phase 2 — SQLite 파일 열기 + 테이블 리스트 (TCA)**

파일 생성 순서:
1. `Storefront/Dependencies/DatabaseClient.swift` — `@DependencyClient` 래퍼 (GRDB DatabaseQueue readonly)
   - `open(URL) async throws -> DatabaseHandle`
   - `tables(DatabaseHandle) async throws -> [TableInfo]`
2. `Storefront/Core/Database/SchemaInspector.swift` — sqlite_master 조회 로직 (Client 내부 구현용)
3. `Storefront/Features/Browser/BrowserFeature.swift` — `@Reducer`, State에 현재 URL/테이블 목록/선택, Action에 `.documentLoaded(tables)`, `.tableSelected`
4. `Storefront/Features/Browser/BrowserView.swift` — `NavigationSplitView`, 사이드바에 테이블 리스트
5. `AppFeature`에 Browser 자식 피처 scope 추가 — `currentDocumentURL`이 생기면 Browser로 전환
6. `StorefrontTests/BrowserFeatureTests.swift` — TestStore로 load/select 액션 테스트

## 저장소 상태

- GitHub: https://github.com/jun7680/Storefront
- Visibility: **Private** (v0.1.0 릴리스 전까지)
- Default branch: `master`
- Active branch: `feat/mvp-v0.1.0`
- Last commit on feat/mvp-v0.1.0: TCA 리팩터 완료
