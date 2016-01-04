.PHONY: all setup

all:
	xcodebuild -workspace 'image-uploader.xcworkspace' \
		-scheme 'image-uploader'|xcpretty

setup:
	bundle install
	bundle exec pod install
