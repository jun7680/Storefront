# Storefront — macOS SQLite/SwiftData 뷰어 초기 설정

## Context

사용자는 오픈소스 첫 경험. `/Users/dev4-injun/Documents/code/Storefront`는 README와 .gitignore만 있는 빈 상태. 목표는 **macOS 26 Tahoe용 SwiftUI 앱** "Storefront"를 iOS 개발자 타겟으로 출시하는 것 — SQLite/SwiftData 파일을 열어 테이블/행을 보여주고, 파일 변경 시 자동 새로고침하며, iOS 시뮬레이터에 설치된 앱의 DB를 자동 탐색한다.

**배포 방향은 확정됐음**: Apple Developer Program($99/년)은 가입하지 않고, **미서명 DMG를 GitHub Releases에 게시**. 사용자에게는 Gatekeeper 우회(우클릭→열기 또는 `xattr -cr`)를 README에 안내. 개발자는 clone + Xcode로 직접 빌드하면 되므로 Makefile도 제공하지만 일반 배포 경로는 DMG 단일.

MVP 범위는 **4가지 전부**: SQLite 뷰어, SwiftData 지원, 라이브 리로드, 시뮬레이터 자동 탐색.

---

## 구현 개요 (7단계)

| Phase | 목표 | 완료 기준 |
|---|---|---|
| 1 | Xcode 프로젝트 부트스트랩 | 빈 창 빌드 성공 |
| 2 | SQLite 파일 열기 + 테이블 리스트 | File > Open으로 사이드바에 테이블 표시 |
| 3 | 행 뷰어 + 라이브 리로드 | WAL 쓰기 감지 시 자동 새로고침 |
| 4 | 시뮬레이터 스캐너 | 시뮬 앱 DB 원클릭 오픈 |
| 5 | SwiftData 스토어 해석 | `.store` 파일 탐색 + `Z_` 접두어 정규화 |
| 6 | DMG 빌드 파이프라인 | `make dmg`로 `build/Storefront.dmg` 생성 |
| 7 | GitHub Actions 릴리스 | `v0.1.0` 태그 푸시 → Releases에 DMG 자동 업로드 |

---

## 프로젝트 구조

```
Storefront/
├── Storefront.xcodeproj/
├── Storefront/                     # App target (macOS 26.0, Swift 6)
│   ├── App/
│   │   ├── StorefrontApp.swift     # @main, Scene, Commands(File>Open/Reload)
│   │   └── AppState.swift          # @Observable 루트 상태
│   ├── Features/
│   │   ├── Welcome/WelcomeView.swift         # 드래그-드롭 + 최근 파일
│   │   ├── Browser/
│   │   │   ├── BrowserView.swift             # NavigationSplitView 3-column
│   │   │   ├── TableListView.swift
│   │   │   ├── RowTableView.swift            # dynamic Table API
│   │   │   └── BrowserViewModel.swift        # @Observable
│   │   └── SimulatorPicker/
│   │       ├── SimulatorPickerView.swift
│   │       └── SimulatorPickerViewModel.swift
│   ├── Core/                       # UI-독립 도메인
│   │   ├── Database/
│   │   │   ├── DatabaseConnection.swift      # GRDB DatabaseQueue 래퍼 (readonly)
│   │   │   ├── SchemaInspector.swift         # 테이블/컬럼/PK/FK 조회
│   │   │   └── RowFetcher.swift              # 페이지네이션
│   │   └── SwiftDataStore/
│   │       ├── SwiftDataDetector.swift       # Z_METADATA 존재 판별
│   │       └── SwiftDataDecoder.swift        # Z_ 컬럼 이름 정규화
│   ├── Services/
│   │   ├── FileWatcher.swift                 # DispatchSource 기반
│   │   ├── SimulatorScanner.swift            # simctl JSON + FS 글로빙
│   │   └── RecentFilesStore.swift            # UserDefaults bookmark
│   ├── UI/
│   │   ├── CellView.swift                    # BLOB/NULL/Date 표현
│   │   └── HexDumpView.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Storefront.entitlements           # 샌드박스 OFF (미서명 편의)
├── StorefrontTests/
│   ├── SchemaInspectorTests.swift
│   ├── SwiftDataDecoderTests.swift
│   ├── FileWatcherTests.swift
│   └── Fixtures/                             # chinook.sqlite, sample.store
├── scripts/
│   ├── build.sh
│   ├── make-dmg.sh
│   └── ExportOptions.plist
├── .github/workflows/
│   ├── build.yml                             # PR/푸시 시 test + build
│   └── release.yml                           # tag v* → DMG 업로드
├── Makefile
├── LICENSE                                   # MIT
├── README.md                                 # 확장판
└── .gitignore
```

**아키텍처**: MVVM-lite. `@Observable` ViewModel이 Core 서비스를 소유, View는 ViewModel만 참조. Repository/UseCase 추상화는 도입하지 않음 (과설계 방지).

---

## 기술 선택

| 영역 | 선택 | 근거 |
|---|---|---|
| **SQLite** | GRDB.swift v7.5.0 (SPM) | Row 동적 접근 탁월, readonly 모드, Swift 6 concurrency. SQLite.swift는 쿼리 빌더 중심이라 "임의 DB 리플렉션"엔 부적합. |
| **SwiftData 파싱** | GRDB로 내부 SQLite 직접 읽기 | `Z_METADATA` 존재 여부로 판별, `Z_` 접두어 제거로 컬럼명 정규화. NSManagedObjectModel 역직렬화는 v1 스킵. |
| **파일 감시** | `DispatchSource.makeFileSystemObjectSource` | 단일 파일엔 FSEventStream보다 가볍고 Swift-native. WAL 모드 대응으로 `-wal`, `-shm`도 감시, rename 시 재오픈. |
| **시뮬레이터 탐색** | `xcrun simctl list --json` + FS 글로빙 하이브리드 | simctl만으로는 앱 컨테이너 경로 부재. `~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/*/` 글로빙 필수. `Info.plist`의 `MCMMetadataIdentifier`로 번들ID 표시. |

**macOS 26 Tahoe SwiftUI 신기능 활용**
- `NavigationSplitView` 3-column (소스 / 테이블 / 행)
- `Table(of:selection:sortOrder:)` + 동적 `TableColumn` + `TableColumnCustomization` (사용자 재정렬/숨김 저장)
- `@Observable` + `@Bindable`
- `.fileImporter`, `.dropDestination`, `ContentUnavailableView`, `Inspector`, `.searchable(placement: .toolbar)`
- `Commands` API로 File > Open / Recent / Reload

---

## 디자인 & UX 방향

**원칙**: 귀엽지만 장난스럽지 않게, 데이터는 선명하게, macOS 네이티브 느낌은 유지.

### 톤 & 비주얼 언어
- **색상 팔레트 (확정)**: Sky Blue + Sunset Orange
  - Primary `#5AA7E6` (sky) — 선택/포커스/주요 액션
  - Accent `#FF9F5A` (orange) — 라이브 리로드 강조, 배지, 토스트
  - BG Light `#F8FAFC` / BG Dark `#161A1F`
  - Text Light `#1F2937` / Text Dark `#EEF2F7`
  - `Color(.systemBlue)` 대체로 Asset에 커스텀 `AppPrimary`, `AppAccent` 등록
- **모서리**: corner radius 10 (카드), 6 (셀). 둥글둥글.
- **타이포**: 시스템 폰트(San Francisco) + SF Mono는 **데이터 셀만**.
- **여백**: macOS 표준보다 살짝 넉넉 (16-20pt grid).

### 이모지/마스코트 수준 (확정)
- **중간**: 데이터 영역은 깔끔, **Welcome / Empty 화면 / 토스트에만** 이모지 사용.
  - Welcome 드롭존: "📦 파일을 끌어다 놓아보세요"
  - Empty: "🗂 아직 연 파일이 없어요"
  - Toast: "🔄 변경 감지됨 — 자동 새로고침"
- 마스코트 캐릭터는 v1에서 제외 (과함 방지).

### 앱 아이콘 (확정)
- **v1**: SF Symbol 조합으로 1024×1024 PNG 자동 생성
  - 후보: `storefront.fill` + 그라디언트 배경(sky→orange)
  - 또는 `cylinder.split.1x2.fill`(DB 원통) 오버레이
  - AppIcon.appiconset 모든 해상도 자동 산출 스크립트 (`scripts/make-icon.sh`, sips 사용)
- **v0.2+**: 커스텀 일러스트 아이콘 (상점 + DB 모티프)

### 레이아웃 (3-column NavigationSplitView)
```
┌─Sidebar──┬─Table List──────┬─Row Viewer──────────────┐
│ 📁 Recent │ 🗂 tracks (350) │ id │ name │ album │...  │
│ 📱 Simuls │ 🗂 artists (25) │ 1  │ Bohe.│ Qnight│...  │
│ ➕ Open   │ 🗂 albums (43)  │ 2  │ Stair│ Led Z │...  │
│          │ 🗂 Z_METADATA   │ ─────────────── Inspector│
└──────────┴─────────────────┴──────────────────────────┘
```
- **Sidebar**: Sources 섹션(Recent / Simulators / Open new…), NSVisualEffectView 블러
- **Table List**: 테이블명 + 행수 배지(capsule), `Z_` 접두 테이블은 별도 섹션
- **Row Viewer**: 동적 `Table`, 타입별 컬러 셀, sticky header, zebra stripe(옵션)
- **Inspector** (토글 가능): 선택한 행의 전체 필드 세로 표시, BLOB/긴 텍스트 확장 뷰

### 데이터 가독성 (핵심)
- **타입별 색상**:
  - `NULL` → 회색 이탤릭 `null`
  - `INTEGER/REAL` → 파란 계열 우측정렬
  - `TEXT` → 기본
  - `BLOB` → 보라 `0x…` + 클릭 시 HexDumpView / 이미지면 preview
  - `DATE` (ISO8601/Unix timestamp 추정) → 초록 + tooltip에 원본값
- **Sticky header** + 컬럼 resize/reorder/숨김 (`TableColumnCustomization` 영구 저장)
- **긴 텍스트**: 1줄 truncate + hover tooltip + Inspector에서 전체
- **검색**: `.searchable` 툴바, 테이블 전체 또는 현재 컬럼

### UX 디테일
- **Welcome 화면**: 큰 드롭존 + 최근 파일 그리드(3-up 카드) + "시뮬 앱 둘러보기" 버튼
- **토스트 알림** (macOS 26 `.alert`/커스텀 overlay): "🔄 변경 감지됨 — 자동 새로고침"
- **Command palette** (⌘K): 테이블 이름으로 즉시 점프, 최근 파일 열기
- **키보드 내비**: ⌘O(Open), ⌘R(Reload), ⌘F(Search), ⌥⌘I(Inspector 토글)
- **빈 상태**: `ContentUnavailableView` + 친근한 카피 ("아직 연 파일이 없어요")
- **햅틱/사운드**: 절제 (macOS는 기본 시스템 사운드만)
- **접근성**: Dynamic Type, VoiceOver 라벨, 고대비 모드 대응

### 다크/라이트 모드
- 둘 다 1급 지원. 라이트는 민트 생기, 다크는 민트가 은은한 포인트.
- 시스템 Appearance 따름 (설정에서 오버라이드 옵션 추후).

### 디자인 검증 방법
- Xcode Previews로 각 화면 라이트/다크 동시 확인
- `#Preview` 매크로로 빈 상태 / 데이터 많음 / BLOB 포함 / 긴 텍스트 등 **대표 6가지 케이스** 프리뷰
- 실 DB(chinook.sqlite)로 수동 QA

---

## DMG 빌드 파이프라인

**로컬 (Makefile)**
- `make build` → `xcodebuild archive` (CODE_SIGN_IDENTITY="-", CODE_SIGNING_REQUIRED=NO)
- `make export` → `xcodebuild -exportArchive` (ExportOptions.plist: method=`mac-application`, signing=manual, certificate 없음)
- `make dmg` → `create-dmg` v1.2.2 (Homebrew) 또는 `hdiutil create -format UDZO`
- `make test`, `make clean`

**GitHub Actions** (`macos-latest`, Xcode 26)
- `build.yml`: PR/push에서 `xcodebuild test` + `make build`
- `release.yml`: `on: push: tags: ['v*']` → `make dmg` → `softprops/action-gh-release@v2`로 `.dmg` 업로드

**Gatekeeper 우회 (README 명시)**
1. 권장: Finder에서 `.app` 우클릭 → 열기 → 열기
2. 시스템 설정 > 개인정보 보호 및 보안 > "그래도 열기" (macOS 15+)
3. CLI: `xattr -cr /Applications/Storefront.app`
4. 옵션: ad-hoc 서명 `codesign --force --deep --sign - Storefront.app` (경고는 여전하지만 라이브러리 검증 실패 방지)

---

## 초기 커밋 체크리스트 (Phase 1 직후)

- `LICENSE` (MIT, Copyright 2026 Injun Mo)
- `README.md` 확장: Features, 스크린샷 placeholder, Install(DMG), First run / Gatekeeper, Build from source, Roadmap, License
- `CONTRIBUTING.md`: **v1 skip** (첫 오픈소스엔 과함)
- `.github/ISSUE_TEMPLATE/bug_report.yml` (선택)

---

## 핵심 파일 (수정/생성)

신규 프로젝트라 전부 생성:

- `/Users/dev4-injun/Documents/code/Storefront/Storefront.xcodeproj/project.pbxproj`
- `/Users/dev4-injun/Documents/code/Storefront/Storefront/App/StorefrontApp.swift`
- `/Users/dev4-injun/Documents/code/Storefront/Storefront/Core/Database/DatabaseConnection.swift`
- `/Users/dev4-injun/Documents/code/Storefront/Storefront/Core/SwiftDataStore/SwiftDataDetector.swift`
- `/Users/dev4-injun/Documents/code/Storefront/Storefront/Services/FileWatcher.swift`
- `/Users/dev4-injun/Documents/code/Storefront/Storefront/Services/SimulatorScanner.swift`
- `/Users/dev4-injun/Documents/code/Storefront/Makefile`
- `/Users/dev4-injun/Documents/code/Storefront/scripts/make-dmg.sh`
- `/Users/dev4-injun/Documents/code/Storefront/scripts/ExportOptions.plist`
- `/Users/dev4-injun/Documents/code/Storefront/.github/workflows/build.yml`
- `/Users/dev4-injun/Documents/code/Storefront/.github/workflows/release.yml`
- `/Users/dev4-injun/Documents/code/Storefront/LICENSE`
- `/Users/dev4-injun/Documents/code/Storefront/README.md` (확장)

---

## 검증 방법 (E2E)

**Phase별 스모크 테스트**
- Phase 1: `xcodebuild build` 성공, 앱 실행 시 빈 창 렌더
- Phase 2: `chinook.sqlite`(Public Domain 샘플) 열어서 11개 테이블이 사이드바에 표시되는지
- Phase 3: 터미널에서 `sqlite3 chinook.sqlite "INSERT INTO artists VALUES (999, 'Test')"` 실행 후 UI가 자동 갱신되는지 수동 확인
- Phase 4: Xcode 시뮬레이터에 임의 iOS 앱 실행 후 "Simulators" 섹션에 앱 번들이 나타나는지
- Phase 5: 샘플 SwiftData 스토어(별도 `SampleGenerator` CLI 타겟으로 `@Model` 2개 생성) 열어서 `Z_` 접두어 제거된 상태로 보이는지

**단위 테스트 (XCTest, `xcodebuild test`)**
- `SchemaInspectorTests`: 테이블/컬럼/PK/FK/인덱스 파싱
- `SwiftDataDecoderTests`: `Z_METADATA` 판별, 컬럼명 정규화
- `FileWatcherTests`: 임시 디렉터리에 sqlite 생성 + INSERT 후 콜백 수신 확인 (`XCTestExpectation`)
- `SimulatorScannerTests`: mock JSON 파싱 (CI에는 실 시뮬 없음)

**CI 검증**
- `build.yml`이 PR에서 test + build 성공
- `release.yml`: 로컬에서 `git tag v0.1.0 && git push origin v0.1.0` → GitHub Releases에 DMG 업로드 + 다른 Mac에서 다운로드 → Gatekeeper 우회 후 정상 실행

**배포 후 수동 QA 체크리스트 (README에 유지)**
- File > Open으로 SQLite 열기
- 드래그-드롭으로 열기
- 최근 파일 목록
- WAL 모드 DB 라이브 리로드
- 시뮬레이터 앱 DB 원클릭 오픈
- SwiftData 스토어 인식 + 정규화 표시
