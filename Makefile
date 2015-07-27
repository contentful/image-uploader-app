.PHONY: all setup

all:
	xcodebuild -workspace 'image-uploader.xcworkspace' \
		-scheme 'image-uploader'|xcpretty

setup:
	pod install
