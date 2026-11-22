APP := Lest
BUNDLE := build/$(APP).app
INSTALLED := /Applications/$(APP).app
# Where the `lest` command is linked. The folder has to be on your PATH.
COMMAND := $(HOME)/.local/bin/lest
VERSION := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
ARCHIVE := build/$(APP)-$(VERSION).zip
# Extra `swift build` flags; `release` uses them to build for Intel and Apple silicon at once.
BUILD_FLAGS :=

.PHONY: test snapshot app install release icons skill app-icon

test:
	swift test

# Draws the panel off screen with sample notes into build/snapshots, to check a layout change.
snapshot:
	LEST_SNAPSHOT_DIR="$(CURDIR)/build/snapshots" swift test --filter PanelSnapshotTests

# Builds build/Lest.app from the SwiftPM executable, signed for this Mac only.
app:
	swift build -c release $(BUILD_FLAGS)
	mkdir -p "$(BUNDLE)/Contents/MacOS" "$(BUNDLE)/Contents/Resources"
	cp "$$(swift build -c release $(BUILD_FLAGS) --show-bin-path)/$(APP)" "$(BUNDLE)/Contents/MacOS/$(APP)"
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	codesign --force --sign - "$(BUNDLE)"

# Installs the app and the `lest` command (the app binary doubles as it), replacing an earlier
# install in place, then connects the coding tools found on this Mac. `lest setup` fails when
# there are none, which is no reason to fail the install.
install: app
	-pkill -x $(APP)
	ditto "$(BUNDLE)" "$(INSTALLED)"
	mkdir -p "$(dir $(COMMAND))"
	ln -sf "$(INSTALLED)/Contents/MacOS/$(APP)" "$(COMMAND)"
	-"$(INSTALLED)/Contents/MacOS/$(APP)" setup
	open "$(INSTALLED)"
	@command -v lest >/dev/null || echo "Note: $(dir $(COMMAND)) is not on your PATH, so \`lest\` will not be found. Add it, or run: make install COMMAND=/usr/local/bin/lest"

# Builds the download for the releases page: a universal app signed with a Developer ID,
# notarized by Apple and stapled, so it opens on any Mac without a warning.
#   make release IDENTITY="Developer ID Application: Jane Doe (TEAMID)"
# Notarization goes through the App Store Connect CLI (`asc`), which has to be logged in.
release: BUILD_FLAGS := --arch arm64 --arch x86_64
release: app
	@test -n "$(IDENTITY)" || { echo 'Usage: make release IDENTITY="Developer ID Application: Name (TEAMID)"'; exit 1; }
	codesign --force --options runtime --timestamp --sign "$(IDENTITY)" "$(BUNDLE)"
	ditto -c -k --keepParent "$(BUNDLE)" "$(ARCHIVE)"
	asc notarization submit --file "$(ARCHIVE)" --wait
	xcrun stapler staple "$(BUNDLE)"
	ditto -c -k --keepParent "$(BUNDLE)" "$(ARCHIVE)"
	spctl --assess --type execute --verbose "$(BUNDLE)"
	@echo "Ready to upload: $(ARCHIVE)"

# Compiles the SVG files in Resources/Phosphor into Sources/Lest/Icons/Phosphor.swift.
# Run it after adding or removing an icon there.
icons:
	swift scripts/embed-icons.swift

# Compiles skill/lest/SKILL.md into Sources/LestCore/Connections/SkillText.swift.
# Run it after editing the skill; a test fails when the two differ.
skill:
	swift scripts/embed-skill.swift

# Regenerates Resources/AppIcon.icns from scripts/make-icon.swift.
app-icon:
	mkdir -p build/AppIcon.iconset
	swift scripts/make-icon.swift build/AppIcon.png
	for size in 16 32 128 256 512; do \
		sips -z $$size $$size build/AppIcon.png --out build/AppIcon.iconset/icon_$${size}x$${size}.png >/dev/null; \
		sips -z $$((size * 2)) $$((size * 2)) build/AppIcon.png --out build/AppIcon.iconset/icon_$${size}x$${size}@2x.png >/dev/null; \
	done
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
