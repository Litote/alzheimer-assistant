PBXPROJ := ios/Runner.xcodeproj/project.pbxproj
PODLOCK  := ios/Podfile.lock

# CI values (already public via project.pbxproj)
CI_TEAM   := $(shell grep -m1 'DEVELOPMENT_TEAM' $(PBXPROJ) | sed 's/.*= //;s/;//')
CI_BUNDLE := $(shell grep -m1 'PRODUCT_BUNDLE_IDENTIFIER' $(PBXPROJ) | sed 's/.*= //;s/;//')

# Local dev values — override via dev.env or environment variables
-include dev.env
DEV_TEAM   ?= $(error DEV_TEAM is not set — create dev.env from dev.env.example)
DEV_BUNDLE ?= com.$(shell whoami).alzheimerAssistant

.PHONY: dev-setup dev-reset

dev-setup: ## Configure local iOS signing for device development
	sed -i '' 's/$(CI_TEAM)/$(DEV_TEAM)/g' $(PBXPROJ)
	sed -i '' 's/$(CI_BUNDLE)/$(DEV_BUNDLE)/g' $(PBXPROJ)
	git update-index --skip-worktree $(PBXPROJ)
	git update-index --skip-worktree $(PODLOCK)
	@echo "Dev setup done (team=$(DEV_TEAM), bundle=$(DEV_BUNDLE))"
	@echo "Run 'flutter run --profile --dart-define-from-file=secrets.json' to launch"

dev-reset: ## Restore iOS files to committed version before updating them
	git update-index --no-skip-worktree $(PBXPROJ)
	git update-index --no-skip-worktree $(PODLOCK)
	git restore $(PBXPROJ) $(PODLOCK)
	@echo "Restored — edit, commit, then run 'make dev-setup' again"
