COFFEE=node_modules/.bin/coffee
BLING=node_modules/bling/dist/bling.js
PREPROC=grep -v '^\s*\# ' | perl -ne 's/^\s*[\#]/\#/p; print' | cpp

SRC_FILES=$(shell ls *.coffee)

all: js/game.js js/bling.js js/coffee-script.js

js:
	mkdir -p js

js/game.js: js $(SRC_FILES) $(COFFEE)
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

clean:
	rm -rf js
	rm -rf node_modules
