.PHONY: help setup generate build test archive dmg icon clean

# xcodebuild 공통 플래그 (TCA 매크로 실행 허용)
XCFLAGS := \
	-project Storefront.xcodeproj \
	-scheme Storefront \
	-destination 'platform=macOS' \
	-derivedDataPath build \
	-skipPackagePluginValidation \
	-skipMacroValidation

help: ## 사용 가능한 명령
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}'

setup: ## 로컬 개발 도구 설치 (Homebrew)
	brew install xcodegen create-dmg

generate: ## project.yml → Storefront.xcodeproj 재생성
	xcodegen generate

build: generate ## Debug 빌드
	xcodebuild $(XCFLAGS) -configuration Debug build

test: generate ## 단위 테스트
	xcodebuild $(XCFLAGS) test

archive: generate ## Release 아카이브 + 익스포트 (ad-hoc 서명)
	@bash scripts/build.sh

dmg: archive ## build/Storefront-<version>.dmg 생성
	@bash scripts/make-dmg.sh

icon: ## AppIcon.appiconset 전 해상도 산출 (임시 SF S 로고)
	@bash scripts/make-icon.sh

clean: ## 빌드 결과물 제거
	rm -rf build
	rm -rf DerivedData
