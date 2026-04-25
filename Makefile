# Slatewave for JetBrains — local build helpers.
#
# Wraps the Gradle tasks the IntelliJ Platform plugin exposes so you don't have
# to remember the JAVA_HOME dance every time. Run `make` (or `make help`) to
# see targets.

PLUGIN_NAME    := $(shell awk -F' = ' '/^pluginName/ {print $$2}' gradle.properties)
PLUGIN_VERSION := $(shell awk -F' = ' '/^pluginVersion/ {print $$2}' gradle.properties)
DIST_ZIP       := build/distributions/$(PLUGIN_NAME)-$(PLUGIN_VERSION).zip

# Gradle 8 needs JDK 17+ to start. The system `java` on macOS is often JDK 8,
# so fall back to whatever JetBrains IDE is installed — its bundled JBR is
# JDK 21. Override by exporting JAVA_HOME yourself before invoking make.
JAVA_HOME ?= $(shell ls -d /Applications/*.app/Contents/jbr/Contents/Home 2>/dev/null | head -n1)
export JAVA_HOME

GRADLE := ./gradlew

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "; printf "\nSlatewave — make targets\n\n"} \
		/^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\n  plugin    %s %s\n  JAVA_HOME %s\n\n" "$(PLUGIN_NAME)" "$(PLUGIN_VERSION)" "$(JAVA_HOME)"

.PHONY: build
build: ## Build the plugin zip into build/distributions/
	@$(GRADLE) buildPlugin
	@printf "\n→ %s\n" "$(DIST_ZIP)"

.PHONY: run
run: ## Launch a sandbox IDE with the plugin loaded
	@$(GRADLE) runIde

.PHONY: verify
verify: ## Run the JetBrains plugin verifier against the IDE range in build.gradle.kts
	@$(GRADLE) verifyPlugin

.PHONY: clean
clean: ## Remove build artifacts
	@$(GRADLE) clean

.PHONY: zip
zip: ## Print the path to the built distribution zip
	@echo "$(DIST_ZIP)"

.PHONY: version
version: ## Print the current plugin version
	@echo "$(PLUGIN_VERSION)"

.PHONY: bump-patch bump-minor bump-major
bump-patch: ## Bump the patch version in gradle.properties (x.y.Z+1)
	@$(MAKE) -s _bump PART=patch
bump-minor: ## Bump the minor version in gradle.properties (x.Y+1.0)
	@$(MAKE) -s _bump PART=minor
bump-major: ## Bump the major version in gradle.properties (X+1.0.0)
	@$(MAKE) -s _bump PART=major

.PHONY: _bump
_bump:
	@awk -v part="$(PART)" -F' = ' '\
		/^pluginVersion/ { \
			n = split($$2, v, "."); \
			if (part == "patch") v[3]++; \
			else if (part == "minor") { v[2]++; v[3] = 0; } \
			else if (part == "major") { v[1]++; v[2] = 0; v[3] = 0; } \
			printf "%s = %d.%d.%d\n", $$1, v[1], v[2], v[3]; \
			next; \
		} { print }' gradle.properties > gradle.properties.tmp \
		&& mv gradle.properties.tmp gradle.properties \
		&& echo "→ $$(awk -F' = ' '/^pluginVersion/ {print $$2}' gradle.properties)"
