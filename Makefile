.PHONY: clean test build run watch install icons

clean:
	flutter clean
	flutter pub get

install:
	flutter pub get

build:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

test:
	flutter test

run: build
	flutter run

icons:
	dart run flutter_launcher_icons

check: clean build test
	flutter analyze 

apk: clean build
	flutter build apk --release 