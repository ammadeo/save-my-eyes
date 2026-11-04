# Native macOS app in SaveMyEyes/ (Swift, SwiftUI, AppKit). Requires Xcode 26+ and xcodegen
# (`brew install xcodegen`). The .xcodeproj is generated and not committed.

XCODEGEN ?= xcodegen
PROJECT   = SaveMyEyes/SaveMyEyes.xcodeproj
SCHEME    = SaveMyEyes
DERIVED   = SaveMyEyes/build
APP       = $(DERIVED)/Build/Products/Debug/Save\ My\ Eyes.app
XCB       = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES

.PHONY: project build test run release dist clean

project:
	cd SaveMyEyes && $(XCODEGEN) generate --quiet

build: project
	$(XCB) -configuration Debug build 2>&1 | tail -20

test: project
	$(XCB) -configuration Debug test 2>&1 | grep -E "Test Case.*(failed|error)|error:|Executed|TEST SUCCEEDED|TEST FAILED|BUILD FAILED" | tail -40

# Debug build with the dev aids: SME_DEV_EVERY_SECS=8 fires the first break after 8 s,
# SME_DEV_OPEN_MENU=1 opens the menu at startup (settings / stop-protection open that pane).
run: build
	pkill -x "Save My Eyes" || true
	open $(APP) --env SME_DEV_EVERY_SECS=$${SME_DEV_EVERY_SECS:-} --env SME_DEV_OPEN_MENU=$${SME_DEV_OPEN_MENU:-}

release: project
	$(XCB) -configuration Release build 2>&1 | tail -5
	@echo "App: $(DERIVED)/Build/Products/Release/Save My Eyes.app"

# Universal (Apple silicon + Intel) release build packaged as dist/Save-My-Eyes-<version>.dmg.
# Ad-hoc signed: Developer ID signing and notarization need an Apple Developer account.
VERSION = $(shell sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' SaveMyEyes/project.yml)
DIST    = dist
DMG     = $(DIST)/Save-My-Eyes-$(VERSION).dmg
RELEASE_APP = $(DERIVED)/Build/Products/Release/Save My Eyes.app

dist: project
	$(XCB) -configuration Release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build 2>&1 | grep -E "error:|warning:|BUILD" | tail -5
	rm -rf "$(DIST)/dmg" "$(DMG)" && mkdir -p "$(DIST)/dmg"
	cp -R "$(RELEASE_APP)" "$(DIST)/dmg/"
	ln -s /Applications "$(DIST)/dmg/Applications"
	hdiutil create -quiet -volname "Save My Eyes" -srcfolder "$(DIST)/dmg" -ov -format UDZO "$(DMG)"
	rm -rf "$(DIST)/dmg"
	@lipo -archs "$(RELEASE_APP)/Contents/MacOS/Save My Eyes"
	@ls -la "$(DMG)"

clean:
	rm -rf $(DERIVED) $(PROJECT)
