# Native macOS app in SaveMyEyes/ (Swift, SwiftUI, AppKit). Requires Xcode 26+ and xcodegen
# (`brew install xcodegen`). The .xcodeproj is generated and not committed.

XCODEGEN ?= xcodegen
PROJECT   = SaveMyEyes/SaveMyEyes.xcodeproj
SCHEME    = SaveMyEyes
# Build products stay inside the repo (git-ignored). With the repo under a folder macOS
# protects (Documents, Desktop, Downloads), `make test` makes macOS ask "would like to access
# files in your Documents folder" after every rebuild: the test host reads its build folder,
# and each ad-hoc signed build is a new app to the privacy system. `make run` does not ask.
# `make test DERIVED=<a folder outside Documents>` avoids the prompt.
DERIVED  ?= SaveMyEyes/build
APP       = $(DERIVED)/Build/Products/Debug/Save\ My\ Eyes.app
XCB       = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES

.PHONY: project build test run release dist install clean

project:
	cd SaveMyEyes && $(XCODEGEN) generate --quiet

build: project
	$(XCB) -configuration Debug build 2>&1 | tail -20

test: project
	$(XCB) -configuration Debug test 2>&1 | grep -E "Test Case.*(failed|error)|error:|Executed|TEST SUCCEEDED|TEST FAILED|BUILD FAILED" | tail -40

# Debug build with the dev aids: SME_DEV_EVERY_SECS=8 fires the first break after 8 s,
# SME_DEV_OPEN_MENU=1 opens the menu at startup (settings / stop-protection open that pane),
# SME_DEV_CALL=20 makes the microphone read as in use for 20 s (the paused menu-bar icon).
run: build
	pkill -x "Save My Eyes" || true
	open $(APP) --env SME_DEV_EVERY_SECS=$${SME_DEV_EVERY_SECS:-} --env SME_DEV_OPEN_MENU=$${SME_DEV_OPEN_MENU:-} --env SME_DEV_CALL=$${SME_DEV_CALL:-}

release: project
	$(XCB) -configuration Release build 2>&1 | tail -5
	@echo "App: $(DERIVED)/Build/Products/Release/Save My Eyes.app"

# Universal (Apple silicon + Intel) release build packaged as dist/Save-My-Eyes-<version>.dmg.
# Signed and notarized by itself when a "Developer ID Application" certificate is in the keychain
# (one-time setup in the README), so downloads open without the "Apple could not verify" warning.
# Without the certificate the build stays ad-hoc signed.
VERSION = $(shell sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' SaveMyEyes/project.yml)
DIST    = dist
DMG     = $(DIST)/Save-My-Eyes-$(VERSION).dmg
RELEASE_APP = $(DERIVED)/Build/Products/Release/Save My Eyes.app
SIGN_ID ?= $(shell security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)
NOTARY_PROFILE ?= save-my-eyes

dist: project
	$(XCB) -configuration Release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build 2>&1 | grep -E "error:|warning:|BUILD" | tail -5
	rm -rf "$(DIST)/dmg" "$(DMG)" && mkdir -p "$(DIST)/dmg"
	$(if $(SIGN_ID),codesign --force --options runtime --timestamp --entitlements SaveMyEyes/Resources/SaveMyEyes.entitlements --sign "$(SIGN_ID)" "$(RELEASE_APP)")
	codesign --verify --strict "$(RELEASE_APP)"
	cp -R "$(RELEASE_APP)" "$(DIST)/dmg/"
	ln -s /Applications "$(DIST)/dmg/Applications"
	hdiutil create -volname "Save My Eyes" -srcfolder "$(DIST)/dmg" -ov -format UDZO "$(DMG)"
	rm -rf "$(DIST)/dmg"
	$(if $(SIGN_ID),codesign --force --timestamp --sign "$(SIGN_ID)" "$(DMG)")
	$(if $(SIGN_ID),xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait)
	$(if $(SIGN_ID),xcrun stapler staple "$(DMG)")
	@lipo -archs "$(RELEASE_APP)/Contents/MacOS/Save My Eyes"
	@ls -la "$(DMG)"

# Replaces the app in /Applications with the build from `make dist` and starts it. A build copied
# here was never downloaded, so it carries no quarantine flag and opens without a warning.
install: dist
	pkill -x "Save My Eyes" || true
	rm -rf "/Applications/Save My Eyes.app"
	cp -R "$(RELEASE_APP)" /Applications/
	open "/Applications/Save My Eyes.app"

clean:
	rm -rf $(DERIVED) $(PROJECT)
