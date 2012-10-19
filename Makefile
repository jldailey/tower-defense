COFFEE=node_modules/.bin/coffee
BLING=node_modules/bling/dist/bling.js
MOCHA=node_modules/.bin/mocha
MOCHA_OPTS=--compilers coffee:coffee-script --globals document,window,Bling,$$,_ -R dot
SRC_FILES=$(shell ls *.coffee)
TEST_FILES=$(shell ls test/*.coffee)
PREPROC=grep -v '^\s*\# ' | perl -ne 's/^\s*[\#]/\#/p; print' | cpp

all: js/game.js js/bling.js js/coffee-script.js

test: all test/pass
	@echo "All tests are passing."

test/pass: $(MOCHA) $(SRC_FILES) $(TEST_FILES)
	$(MOCHA) $(MOCHA_OPTS) $(TEST_FILES) && touch test/pass


js:
	mkdir -p js

peek:
	cat game.coffee | $(PREPROC) | less

js/game.js: js $(SRC_FILES) $(COFFEE) Makefile
	@cat game.coffee | $(PREPROC) | $(COFFEE) -sc > $@

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
	rm -rf js
	rm -rf node_modules
