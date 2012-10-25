SHELL:=/bin/bash
COFFEE=node_modules/.bin/coffee
BLING=node_modules/bling/dist/bling.js
MOCHA=node_modules/.bin/mocha
MOCHA_OPTS=--compilers coffee:coffee-script --globals document,window,Bling,$$,_ -R dot
JS_FILES:=js/bling.js js/coffee-script.js
COFFEE_FILES:=$(shell ls *.coffee)
BUILD_FILES:=$(shell ls *.coffee | sed -E 's@\b@build/@')
TEST_FILES:=$(shell ls test/*.coffee)
FILTER_COMMENTS=grep -v '^\s*\# ' | perl -ne 's/^\s*[\#]/\#/p; print'

all: js/game.js js/bling.js js/coffee-script.js

test: all test/pass
	@echo "All tests are passing."

test/pass: $(MOCHA) $(COFFEE_FILES) $(TEST_FILES)
	$(MOCHA) $(MOCHA_OPTS) $(TEST_FILES) && touch test/pass

js:
	mkdir -p js

build:
	mkdir -p build

build/%.coffee: %.coffee
	cat $< | $(FILTER_COMMENTS) > $@

js/game.js: js build $(BUILD_FILES) $(COFFEE) Makefile
	(cd build && cat game.coffee | cpp | ../$(COFFEE) -sc > ../$@)

js/bling.js: js $(BLING)
	cp $(BLING) js/bling.js

js/coffee-script.js: js $(COFFEE)
	curl http://coffeescript.org/extras/coffee-script.js > $@

$(COFFEE):
	npm install coffee-script
	# PATCH: avoid a warning message from the coffee compiler
	sed -ibak -e 's/path.exists/fs.exists/' node_modules/coffee-script/lib/coffee-script/command.js
	rm -f node_modules/coffee-script/lib/coffee-script/command.js.bak

$(BLING):
	npm install bling

$(MOCHA):
	npm install mocha

clean:
	rm -rf js node_modules build
