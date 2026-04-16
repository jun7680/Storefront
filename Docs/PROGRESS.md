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
| **3. 행 뷰어 + 라이브 리로드** | ✅ 완료 | RowFetcher / DynamicRowGrid(ScrollView+HStack) / CellView(NULL/INT/REAL/TEXT/BLOB 색상) / FileWatcherClient(DispatchSource, WAL/-shm 포함) / 상단 Toast |
| **4. 시뮬레이터 앱 자동 탐색** | ✅ 완료 | SimulatorScanner(simctl JSON + FS 글로빙) / SimulatorClient / SimulatorPickerFeature(DisclosureGroup 트리) / Welcome의 "시뮬레이터" 버튼(⌘L) + Welcome 드래그&드롭 |
| **5. SwiftData 스토어 지원** | ✅ 완료 | SwiftDataDetector(Z_METADATA/Z_PRIMARYKEY 판별) + SwiftDataDecoder(Z 접두어 정규화) + TableInfo.Classification(swiftDataEntity/swiftDataSystem) + 사이드바 Entities/Tables/Views/System 섹션 분리 + 원본명 tooltip + DynamicRowGrid 전체 폭 flex-fill |
| **6. DMG 빌드 파이프라인** | ⏳ 대기 | Makefile / scripts/build.sh, make-dmg.sh, ExportOptions.plist |
| **7. GitHub Actions 릴리스** | ⏳ 대기 | .github/workflows/build.yml, release.yml (매크로 검증 스킵 플래그 포함) |

## 설계 참조

- 전체 설계: [Docs/PLAN.md](./PLAN.md)
- 색상: Sky Blue `#5AA7E6` + Sunset Orange `#FF9F5A`

## 최근 검증 (2026-04-16)

- **Phase 5 빌드/테스트**: 13/13 통과 (AppFeature 3 + BrowserFeature 4 + SimulatorPicker 3 + SwiftDataDecoder 3)
- DynamicRowGrid: GeometryReader 기반 flex/고정 폭 자동 전환 (컬럼수 × 140pt > 가용폭이면 horizontal scroll, 아니면 균등 분배)
- LazyVStack + pinned section header로 상단 고정 (스크롤 시 헤더 유지)

## 다음 작업 시작 지점

**Phase 6 — DMG 빌드 파이프라인 (Makefile)**

파일 생성 순서:
1. `scripts/ExportOptions.plist` — method=mac-application, signing=manual, certificate 없음
2. `scripts/build.sh` — `xcodebuild archive` + `xcodebuild -exportArchive` (ad-hoc 서명 `codesign --sign -`)
3. `scripts/make-dmg.sh` — `create-dmg` (Applications 심볼릭 링크 포함) 또는 `hdiutil create -format UDZO`
4. `scripts/make-icon.sh` — SF Symbol → 1024 PNG → sips로 전 해상도 산출
5. `Makefile` — build/test/archive/dmg/clean/icon 타겟. 필수 flag: `-skipMacroValidation -skipPackagePluginValidation`
6. 로컬 `make dmg` 검증 — `build/Storefront.dmg` 생성 + Applications 드롭존 확인

## 저장소 상태

- GitHub: https://github.com/jun7680/Storefront
- Visibility: **Private** (v0.1.0 릴리스 전까지)
- Default branch: `master`
- Active branch: `feat/mvp-v0.1.0`
- Last commit on feat/mvp-v0.1.0: Phase 5 완료 (SwiftData 지원 + 그리드 flex 레이아웃)
