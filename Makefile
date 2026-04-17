.PHONY: help setup generate build test archive dmg icon clean star install

REPO := jun7680/Storefront

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
	@$(MAKE) --no-print-directory star

install: build ## 로컬 /Applications 에 Debug 빌드 복사
	@cp -R build/Build/Products/Debug/Storefront.app /Applications/
	@echo "✅ /Applications/Storefront.app 설치 완료"
	@$(MAKE) --no-print-directory star

star: ## ⭐ GitHub star 유도 (gh CLI 있으면 즉시 star, 없으면 링크)
	@echo ""
	@echo "────────────────────────────────────────────"
	@echo " 🙏 Storefront 가 도움이 됐다면,"
	@echo "    GitHub 에서 ⭐ 하나 눌러주실래요?"
	@echo "    https://github.com/$(REPO)"
	@echo "────────────────────────────────────────────"
	@printf " [y/N] > "; read ans; \
	case "$$ans" in \
	  y|Y|yes|YES) \
	    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then \
	      gh api -X PUT user/starred/$(REPO) >/dev/null 2>&1 \
	        && echo "⭐ 별 눌러주셔서 감사합니다!" \
	        || { echo "⚠️  API 실패 — 브라우저로 엽니다"; open https://github.com/$(REPO); }; \
	    else \
	      echo "ℹ️  gh CLI 미설치 또는 미로그인 — 브라우저로 엽니다"; \
	      open https://github.com/$(REPO); \
	    fi ;; \
	  *) echo "   괜찮아요, 나중에 생각나시면 눌러주세요 💙" ;; \
	esac

icon: ## AppIcon.appiconset 전 해상도 산출 (임시 SF S 로고)
	@bash scripts/make-icon.sh

clean: ## 빌드 결과물 제거
	rm -rf build
	rm -rf DerivedData
