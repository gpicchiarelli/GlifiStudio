# SPDX-License-Identifier: BSD-3-Clause

.PHONY: bootstrap check-app-store app-store-submission-check check-apple check-architecture check-compliance check-docs check-fixtures check-github check-localization check-naming check-repository check-secrets check-toolchain format github-plan github-apply github-audit github-codeowners lint test build-macos build-ipados verify verify-app-store

check-app-store:
	./Scripts/check-app-store-baseline.py

app-store-submission-check:
	./Scripts/check-app-store-submission.py

bootstrap:
	./Scripts/bootstrap.sh

check-architecture:
	./Scripts/check-architecture.sh

check-compliance:
	./Scripts/check-compliance.py

check-apple:
	./Scripts/check-apple-baseline.py

check-docs:
	./Scripts/check-docs.py

check-fixtures:
	./Scripts/check-fixtures.py

check-github:
	./Scripts/check-github-config.py

check-localization:
	./Scripts/check-localization.py

check-naming:
	./Scripts/check-naming.py

check-repository:
	./Scripts/check-repository.py

check-secrets:
	./Scripts/check-secrets.py

check-toolchain:
	./Scripts/check-toolchain.sh

github-plan:
	./Scripts/github/configure-repository.sh "$(REPO)" "$(or $(PROFILE),solo)"

github-apply:
	./Scripts/github/configure-repository.sh --apply "$(REPO)" "$(or $(PROFILE),solo)"

github-audit:
	./Scripts/github/audit-repository.py "$(REPO)" "$(or $(PROFILE),solo)"

github-codeowners:
	./Scripts/github/create-codeowners.sh "$(OWNER)"

format:
	swift format format --in-place --recursive Apps Packages

lint:
	swift format lint --strict --recursive Apps Packages

test:
	./Scripts/test.sh

build-macos:
	xcodebuild build -workspace GlifiStudio.xcworkspace -scheme GlifiStudio-macOS -configuration Debug -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO

build-ipados:
	xcodebuild build -workspace GlifiStudio.xcworkspace -scheme GlifiStudio-iPadOS -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

verify:
	./Scripts/verify.sh

verify-app-store:
	./Scripts/verify-app-store.sh
