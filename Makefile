.PHONY: deps build release run package test clean help

VLC_LIB_PATH ?= $(shell \
    if [ -d "/Applications/VLC.app/Contents/MacOS/lib" ]; then \
        echo "/Applications/VLC.app/Contents/MacOS/lib"; \
    elif [ -d "/opt/homebrew/lib" ]; then \
        echo "/opt/homebrew/lib"; \
    elif [ -d "/usr/local/lib" ]; then \
        echo "/usr/local/lib"; \
    fi)

VLC_INCLUDE_PATH ?= $(shell \
    if [ -d "/opt/homebrew/include" ]; then \
        echo "/opt/homebrew/include"; \
    elif [ -d "/usr/local/include" ]; then \
        echo "/usr/local/include"; \
    fi)

SWIFT_FLAGS = -Xlinker -L$(VLC_LIB_PATH) -Xlinker -rpath -Xlinker $(VLC_LIB_PATH)
APP_NAME = videOS
BUILD_DIR = .build
BUNDLE_DIR = $(BUILD_DIR)/$(APP_NAME).app

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

deps: ## Install and verify dependencies
	@bash scripts/install-deps.sh

build: ## Debug build
	swift build $(SWIFT_FLAGS)

release: ## Optimized release build
	swift build -c release $(SWIFT_FLAGS)

run: build ## Build and launch
	@bash scripts/run.sh

package: release ## Create videOS.app bundle
	@bash scripts/package.sh

test: ## Run tests
	swift test $(SWIFT_FLAGS)

clean: ## Clean build artifacts
	swift package clean
	rm -rf $(BUILD_DIR)/$(APP_NAME).app

lint: ## Check Swift formatting
	@which swiftlint > /dev/null 2>&1 && swiftlint || echo "swiftlint not installed"
