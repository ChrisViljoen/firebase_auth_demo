.PHONY: clean test

clean:
	flutter clean
	flutter pub get

test:
	flutter test 